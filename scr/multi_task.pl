#!/usr/bin/perl -w
# -*- cperl -*-

## TODO: create and use working directory (?)

use Getopt::Std;
use POSIX ":sys_wait_h";
use File::Basename;
use strict;
use vars qw($opt_F $opt_f $opt_t $opt_s $opt_m $opt_n $opt_x);

## Configuration (for -F option)
my $patience = 14400;
my $sleeptime = 5;
my $retry_failed_tasks = 0;   # times to retry

$| = 1;

sub Usage {
  die "!!! Usage: multi_task.pl [-m max_tasks_per_host] [-F signalfile | -f from -t to -s step | -n] [-x task] [task]\n";
}

my $WRK = $ENV{WRK};
unless ( -d $WRK ) {
  die "!!! WRK '$WRK' is not a directory, abort!\n";
}
chdir($WRK);

## Get options
unless ( getopts('F:m:f:s:t:x:n') ) {
  &Usage();
}

## Check usage
my $task = $opt_x || shift;
my($signalfile,$regfile,$from,$to,$step);
if ( defined($opt_F) ) {
  # Read commands from signal file
  $signalfile = $opt_F;
  $regfile = "$WRK/registry_" . lc($task);
  $ENV{REGFILE} = $regfile;
  $from = 1;
  $to = 99999;
  $step = 1;
} else {
  $from = ( defined($opt_f) ? $opt_f : 1 );
  $to   = $opt_t || $ENV{LL} || 0;
  $step = $opt_s || 1;
  unless ( -x $task ) {   # require full path
    die "!!! Cannot execute task '$task', abort!\n";
  }
}
my $task_path = dirname($task);
$task_path = $ENV{HM_LIB}."/scr" if (not $task_path or $task_path eq '.');
$task = basename($task);
my $task_wrapper = $ENV{TASK_WRAPPER} || "$task_path/TaskWrapper";
my $max_tasks_per_host = $opt_m || $ENV{MAX_TASKS_PER_HOST} || 1;
my $host_exec = $ENV{HOST_EXEC};
my $envfile = "$WRK/multi_task_ENV$$";

## Get host list (PBS and SLURM implemented, otherwise try $HOSTLIST)
## TODO: externalize this to Env_submit somehow
my @hostlist = ();
if ( exists $ENV{PBS_NODEFILE} ) {
  if ( open(FH,$ENV{PBS_NODEFILE}) ) {
    my $nodefile = "$WRK/pbs_nodefile_mt";
    open(FH2,">$nodefile");
    print FH2 "localhost\n";
    my %h = ();
    while( <FH> ) {
      print FH2;
      chomp;
      $h{$_} = 1;
    }
    close(FH);
    close(FH2);
    @hostlist = sort keys %h;
    $ENV{PBS_NODEFILE} = $nodefile if (-s $nodefile);
  } else {
    die "!!! Could not figure out host list from PBS_NODEFILE variable, abort!\n";
  }
} elsif ( exists $ENV{SLURM_JOB_NODELIST} ) {
  if ( $ENV{SLURM_JOB_NODELIST} =~ /^(\w+)\[([\d,-]+)\](\w*)$/ ) {
    my($pre,$list,$suf) = ($1,$2,$3);
    $list =~ s/\-/\.\./g;
    for my $n ( eval $list ) {
      push @hostlist, "$pre$n$suf";
    }
  } else {
    @hostlist = split(',',$ENV{SLURM_JOB_NODELIST});
  }
  $host_exec ||= "srun -O -N1 -n1 --mem-per-cpu=0 --jobid=".$ENV{SLURM_JOB_ID}." -w";
} elsif ( exists $ENV{HOSTLIST} ) {
  @hostlist = split(',',$ENV{HOSTLIST});
} else {
  die "!!! Unable to determine host list for the job, abort!\n";
}
my $nhosts = $#hostlist + 1;
if ($opt_n) {
    $from = 1;
    $to = $nhosts;
    $step = 1;
}
die "!!! Too few hosts, abort!\n" unless ( $nhosts > 0 );
$host_exec ||= 'ssh ';   # unless given by $HOST_EXEC or set for SLURM
if ( $host_exec =~ /\bssh\b/ ) {   #TODO: better test
  # ssh does not transfer the environment, so we dump it to a file
  &Export_env($envfile);   #TODO: limit to those needed??
} else {
  open(OUT,">$envfile") or die "Could not write: '$envfile'\n";
  if (exists $ENV{SLURM_JOB_ID}) {
    print OUT "export SLURM_NODELIST=`hostname`\n";
  }
  close(OUT);
}

## Initialize before main loop
my $starttime = time;
chomp(my $now = qx(date));
my @reglines = ();
if ($signalfile) {
  print "--> Starting listener at $now based on signals from '$signalfile'\n";
  ## Wait for signalfile to exist, then open it
  print "--> INFO: waiting for signal file '$signalfile'\n";
  my $last_info = 0;
  while ( not -s $signalfile ) {
    sleep $sleeptime;
    my $elapsedtime = time - $starttime;
    if ( $elapsedtime > $patience ) {
##NOT IMPLEMENTED: sublisteners
##??      if ( $task eq 'Postpp' and $ENV{CONVERTFA} eq 'yes' and $ENV{ARCHIVE_FORMAT} eq 'grib' ) {
##??	&Append_file("$WRK/listener_pp.txt",'ABORTED');
##??      }
      die "!!! Ran out of patience, time elapsed: $elapsedtime\n";
    }
    if ( $elapsedtime - $last_info >= 60 ) {
      print "--> INFO: still waiting, time elapsed is $elapsedtime seconds.\n";
      $last_info = $elapsedtime;
    }
    stat($signalfile);
  }
  open(SIGF,$signalfile) or die "!!! Strange error, could not open signal file '$signalfile'!\n";
  ## Slurp registry file if it exists
  if ( -s $regfile ) {
    if ( open(REG,$regfile) ) {
      while (<REG>) {
	chomp;
	push @reglines, $_;
      }
      close(REG);
    } else {
      print "!!! Strange error, could not open registry file '$regfile'!\n";
    }
  } else {
    print "--> INFO: registry file '$regfile' not found.\n";
  }
}

## Spawn tasks
my %Host = ();
my %Nactive = ();
my %Cmd = ();
##?? my %Failed = ();
map { $Nactive{$_} = 0 } @hostlist;
my $nfailed = 0;
my $jhost = 0;
my $line;
my $last_pos = 0;
my $nbadlin = 0;
my $aborted = 0;
for( my $ll=$from; $ll<=$to; $ll+=$step ) {
  my $ready = 0;
  my $tries = 0;
  my $host;
  while( not $ready ) {
    $host = $hostlist[ $jhost % $nhosts ];
    if ( $Nactive{$host} >= $max_tasks_per_host ) {
      # try next host
      $jhost++;
      $tries++;
      if ($tries >= $nhosts) {
	# all hosts tried, wait and reset counter
	print "... All hosts fully loaded, waiting for some task to finish ...\n";
	&Wait_any_pid();
	$tries = 0;
      }
    } else {
      $ready = 1;
    }
  }
  my($command,$regline,$fulltask);
  if ( $signalfile ) {
    seek(SIGF,$last_pos,0);
    if ( eof(SIGF) ) {
      $last_pos = tell(SIGF);
      sleep 1;
      $ll -= $step;
      next;
    } else {
      $line = <SIGF>; chomp $line;
      $last_pos = tell(SIGF);
    }
    my($cmd,@rest) = split(' ',$line);
    if ($cmd eq 'COMPLETE' or $cmd eq 'ABORTED') {
      print "!!! $task $cmd\n";
      $aborted = ( $cmd eq 'ABORTED' );
      last;
    } elsif ($cmd eq $task or $cmd eq 'FAcat') {  # is this check necessary??
      # Excellent
      1;
    } else {
      $nbadlin++;
      if ( $nbadlin > 5 ) {
	die "!!! To many bad signalfile lines, abort!\n";
      }
      print "!!! Bad signalfile line: '$line', trying to reopen.\n";
      close(SIGF);
      sleep 1;
      open(SIGF,$signalfile) or die "!!! Fatal error, could not reopen signal file '$signalfile'!\n";
      seek(SIGF,$last_pos,0);
    }
    $fulltask = $envfile ? "$task_wrapper -E $envfile $cmd" : "$task_path/$cmd";
    $command = "$host_exec$host $fulltask " . join(' ',@rest);
    $regline = $line;
  } else {
    $fulltask = $envfile ? "$task_wrapper -E $envfile $task" : "$task_path/$task";
    $command = "$host_exec$host $fulltask $ll";
    $command .= " $to" if ($opt_n);
    $regline = "$task $ll";
  }
  my $pid = fork();
  if ( defined($pid) ) {
    if ($pid) {
      ## This is the parent
      $Host{$pid} = $host;
      $Nactive{$host}++;
      $Cmd{$pid} = $regline;
      print "--> '$command' submitted (pid=$pid) on host $host\n";
    } else {
      ## This is the child
      exec "$command 1>$WRK/pid-$$.log 2>&1";   # and never return
    }
  } else {
    die "!!! Fork of '$command' failed, abort!\n";
  }
  $jhost++;
}

## Wait for all tasks to finish
my $kids_left = scalar(keys(%Host));
while ( $kids_left > 0 ) {
  print "... Waiting for ALL tasks to finish ... $kids_left left\n";
  &Wait_any_pid();
  $kids_left = scalar(keys(%Host));
}
if ($nfailed) {
  die "!!! Aborting now since $nfailed tasks have failed!\n";
} elsif ( $aborted ) {
  die "!!! Aborting now since main listener aborted!\n";
} else {
  print "... all tasks completed successfully, goodbye!\n";
}

## Clean up
unlink $envfile if ($envfile);

sub Wait_any_pid {
  my $kid;
  my $nreaped = 0;
  my $start_wait = time;
  while ( $nreaped == 0 ) {
    for my $pid ( keys %Host ) {
      $kid = waitpid($pid,WNOHANG);    #check non-blocking
      if ($kid == $pid) {
	my $wait_time = time - $start_wait;
	# Child terminated, check exit status
	my($rc,$sig,$core) = ($? >> 8, $? & 127, $? & 128);
	my $msg = "Child process $kid ";
	if ($core) {
	  $msg .= "dumped core!";
	} elsif ($sig == 9) {
	  $msg .= "was killed brutally!";
	} else {
	  $msg .= "returned $rc";
	  $msg .= " after receiving signal $sig" if ($sig);
	}
	$nfailed++ if ($rc || $sig);
	print "--> $msg\n";
	my $host = $Host{$kid};
	$Nactive{$host}--;
	delete $Host{$kid};   # important!
	my $numpids = scalar(keys %Host);
	my $active = $numpids ? join(' ',keys %Host) : 'none';
	print "--> Waited $wait_time secs for child process $kid, still unreaped: $active\n";
	$nreaped++;
	my $log = "$WRK/pid-$kid.log";
	if ( -s $log ) {
	  my $cmd = $Cmd{$kid};
	  print " ===== Begin log of '$cmd' (pid=$kid) =================================================\n";
	  open(FH,$log);
	  while(<FH>) { print; }
	  close(FH);
	  print " ===== End of log '$cmd' (pid=$kid) ===================================================\n";
	  unlink $log unless($rc || $sig);   # keep logs when task fails
	} else {
	  print "!!! Child process $kid produced no output!\n";
	}
      }
    }
    sleep 5 unless $nreaped;
  }
}


sub Export_env {
  my @exclude = ( 'LOGNAME','USER','TMPDIR','SCRATCHDIR','TRUESCRATCHDIR',
		  'HISTFILE','TRUE_TMPDIR','DISPLAY','X11COOKIE','PS1','PWD',
		  'SHELL','SHLVL','HOST','HOSTNAME','HOSTPROMPT' );

  my $out = shift or die "Usage: $0 outputfile\n";
  open(OUT,">$out") or die "Could not write: '$out'\n";
  print OUT "ulimit -s unlimited\n";

  for my $var ( sort keys %ENV ) {
    next if ( grep /^$var$/, @exclude );
    next if ( $var =~ /\(\)$/ );   # exclude functions
    print OUT "export $var=\"".$ENV{$var}."\"\n";
  }
  close(OUT);
}
