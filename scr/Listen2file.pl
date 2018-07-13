# -*-cperl-*-

# Listens to the signal file created by task Listen
# and performs the requested actions
# perl version, Ole Vignes, MET Norway, June 2014

use strict;

## Configuration
my $patience = 14400;
my $sleeptime = 5;
my $retry_failed_tasks = 0;   # times to retry
my $maxwait = 180;   # max wait for io-server files ready
my $min_mtime_age = 15;   # files must be last modified these many secs ago
my $maxpids = $ENV{LISTENER_MAXPIDS} || 1;   # set elsewhere

## Invocation
if ( $#ARGV != 0 and $#ARGV != 2 ) {
  die "Usage: $0 task [me num]\n";
}
my $WRK = $ENV{WRK};
unless ( -d $WRK ) {
  die "!!! WRK '$WRK' is not a directory, abort!\n";
}
chdir($WRK);

## Initialize
$| = 1;
my $role = shift;
my $me = shift || 1;
my $num = shift || 1;
my($signalfile,$regfile,$cmd);

if ( $role eq 'Makegrib' or $role eq 'Postpp' ) {
  $signalfile = "$WRK/listener.txt";
  $regfile = "$WRK/registry_" . lc($role) . $me;
  $cmd = $role;
  unlink "$WRK/listener_pp.txt" if ($role eq 'Postpp');
} elsif ( $role eq 'Makegrib_pp' ) {
  $signalfile = "$WRK/listener_pp.txt";
  $regfile = "$WRK/registry_postpp_makegrib$me";
  $cmd = 'Makegrib';
} else {
  die "!!! $0: invalid argument: '$role'\n";
}
$ENV{REGFILE} = $regfile;
print "--> INFO: I am number $me out of $num listener(s) for '$cmd'\n";

my $starttime = time;
chomp(my $now = qx(date));
print "--> Starting listener at $now based on signals from '$signalfile'\n";

## Wait for signalfile to exist, then open it
print "--> INFO: waiting for signal file '$signalfile'\n";
my $last_info = 0;
while ( not -s $signalfile ) {
  sleep $sleeptime;
  my $elapsedtime = time - $starttime;
  if ( $elapsedtime > $patience ) {
    if ( $cmd eq 'Postpp' and $ENV{CONVERTFA} eq 'yes' and $ENV{ARCHIVE_FORMAT} eq 'grib' ) {
      &Append_file("$WRK/listener_pp.txt",'ABORTED');
    }
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
my @reglines = ();
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

## Initialize before main loop
my %active = ();
my %failed = ();
my %cmdline = ();
my %prereq = ();
my %link = ();
my %to_pp = ();
my $numpids = 0;
my $fc_complete = 0;
my $last_facat = '';
my $lineno = 0;
my $last_lineno = 0;
my $last_pos = 0;
my $nbadlin = 0;

## Main loop
while ( not $fc_complete ) {
  ## Read a line from the signal file
  while( my $line = <SIGF> ) {
    chomp $line;
    $lineno++;
    my($task,$ll,$filetype) = split(' ',$line);
    if ( $task eq $cmd || $task eq "FAcat" ) { 
      print "<-- $task $ll $filetype\n";
      my $done = grep /\#${task}\#${ll}\#${filetype}\#/, @reglines;
      my $mine = ( $lineno % $num == $me - 1 );
      if ( $mine and not $done ) {
	## This is our task
	my $cmdline = "$task $ll $filetype > $WRK/${task}_${ll}_${filetype}.log 2>&1";
	## Avoid too many child processes active at the same time
	&Wait_for_children($maxpids-1);
	## Prevent FAcat from running too early
	#&Check_files_ready($last_facat);
	#$ENV{TYPE} = $filetype;   # necessary for FAcat
	#$ENV{PREREQ_COMMAND} = $last_facat;   # for Makegrib/Postpp if io-server
	## Ready to fork a child worker
	my $pid = fork();
	if ( not defined($pid) ) {
	  print "!!! WARNING: no fork, executing '$cmdline' myself!\n";
	  my $rc = system $cmdline;
	  if ($rc != 0) {
	    $failed{$cmdline} = $rc;
	  }
	} elsif ( $pid == 0 ) {
	  # This is the child
	  exec $cmdline;   # and never return
	} else {
	  # This is the master if the fork was successful
	  my $link = "$WRK/L$me-$pid.log";
	  $active{$pid} = 1;
	  $link{$pid} = $link;
	  $cmdline{$pid} = $cmdline;
	  #$prereq{$pid} = $last_facat;
      if ( $task eq 'Postpp' and $ENV{CONVERTFA} eq 'yes' and $ENV{ARCHIVE_FORMAT} eq 'grib' ) {
	    $to_pp{$pid} = "Makegrib $ll $filetype";
	  }
	  $numpids++;
	  symlink "$WRK/${task}_${ll}_${filetype}.log", $link;
	  print "--> '$task $ll $filetype' executed by child process $pid\n";
	}
      } elsif ( $mine ) {
	print "... NOTE: command '$task $ll $filetype' found in $regfile\n";
      } else {
	print "... NOTE: command '$task $ll $filetype' is not my task.\n";
      }
    } elsif ( $task eq 'COMPLETE' or $task eq 'ABORTED' ) {
      print "!!! $cmd ". lc($task) . "\n";
      ## Wait for all child procs to finish
      &Wait_for_children(0);
      if ( $cmd eq 'Postpp' and $ENV{CONVERTFA} eq 'yes' and $ENV{ARCHIVE_FORMAT} eq 'grib' ) {
	&Append_file("$WRK/listener_pp.txt",$task);
      }
      if ($task eq 'COMPLETE') {
	$fc_complete = 1;
      } else {
	die "!!! Aborting since model aborted!\n";
      }
#    } elsif ( $task eq 'FAcat' ) {
#      $lineno--;
#      print "<-- '$line'\n";
#      $last_facat = $line;
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
      $lineno = $last_lineno;
    }
  }
  $last_pos = tell(SIGF);
  $last_lineno = $lineno;
  sleep $sleeptime;
  my $elapsedtime = time - $starttime;
  if ( $elapsedtime > $patience ) {
    if ( $cmd eq 'Postpp' and $ENV{CONVERTFA} eq 'yes' and $ENV{ARCHIVE_FORMAT} eq 'grib' ) {
      &Append_file("$WRK/listener_pp.txt",'ABORTED');
    }
    die "!!! Ran out of patience, time elapsed: $elapsedtime\n";
  }
  seek(SIGF,$last_pos,0);
}
close(SIGF);

## Failed tasks??, retry without forking
while ( $retry_failed_tasks > 0 ) {
  for my $pid ( keys %failed ) {
    my $cmdline = $cmdline{$pid};
    #$ENV{PREREQ_COMMAND} = $prereq{$pid};
    print "--> Retrying failed command: '$cmdline'\n";
    my $rc = system $cmdline;
    my $link = $link{$pid};
    &Print_file($link,$cmdline);
    if ($rc == 0) {
      delete $failed{$pid};
      unlink $link;
    } else {
      print "!!! Return code: $rc\n";
    }
  }
  $retry_failed_tasks--;
}
my $nfailed = scalar( keys %failed );
die "Failed tasks: $nfailed, abort!\n" if ($nfailed);
## ---------------------------------------------------------------------------

sub Print_file {
  ## Print content of log file
  my($file,$cmdline) = @_;
  if ( open(FH,$file) ) {
    print "====== Output from '$cmdline'\n";
    while(<FH>) {
      print;
    }
    close(FH);
    print "====== End of file $file ======\n";
  } else {
    print "!!! Could not print log file '$file'\n";
  }
}

sub Append_file {
  ## Append a string to a file
  my($file,$string) = @_;
  if ( open(FH,">>$file") ) {
    print FH "$string\n";
    close(FH);
  } else {
    print "!!! ERROR appending '$string' to $file\n";
  }
}

sub Wait_for_children {
  ## Wait for child processes until $numpid <= $maxpids
  my($MAXPIDS) = shift;
  while ( $numpids > $MAXPIDS ) {
    print "--> INFO: too many unreaped children, numpids(=$numpids) > maxpids(=$MAXPIDS)\n";
    my $start_wait = time;
    my $pid = waitpid(-1,0);
    my $wait_time = time - $start_wait;
    my ($rc,$sig,$core) = ($? >> 8, $? & 127, $? & 128);
    if ($core){
      print "!!! Child process $pid dumped core!\n";
    } elsif ($sig == 9) {
      print "!!! Child process $pid was killed!\n";
    } else {
      print "--> Child process $pid returned $rc";
      print ( $sig ? " after receiving signal $sig\n" : "\n" );
      if ($rc != 0) {
	$failed{$pid} = $rc;
      }
    }
    if ( exists $active{$pid} ) {
      delete $active{$pid};
      my $link = $link{$pid};
      my $cmdline = $cmdline{$pid};
      unless ( exists $failed{$pid} ) {
	delete $cmdline{$pid};
	delete $link{$pid};
      }
      $numpids--;
      my $active = $numpids ? join(' ',keys %active) : 'none';
      print "--> Waited $wait_time secs for child process $pid, still unreaped: $active\n";
      if ( exists $to_pp{$pid} ) {
	&Append_file("$WRK/listener_pp.txt",$to_pp{$pid});
	delete $to_pp{$pid};
      }
      &Print_file($link,$cmdline);
      unlink $link unless(exists $failed{$pid});
    } else {
      print "!!! WARNING: waitpid unexpectedly returned '$pid' after $wait_time seconds\n";
    }
  }
}

sub Check_files_ready {
  my $facat = shift;
  return 0 unless( $facat );
  my @args = split(' ',$facat);
  unless( $args[0] eq 'FAcat' ) {
    print "!!! WARNING: bad command: '$facat', expect disaster!\n";
    return 1;
  }
  shift(@args);   # remove first word 'FAcat'
  my $outfile = pop(@args);   # remove output file name
  my $ok = 0;
  my $starttime = time;
  while ( not $ok ) {
    my $lok = 1;
    my $now = time;
    if ( $now - $starttime > $maxwait ) {
      print "!!! WARNING: reached maxwait=$maxwait for '$facat', expect disaster!\n";
      return 1;
    }
    my $minage = 999999;
    for my $infile ( @args ) {
      if ( -s $infile ) {
	my $mtime = (stat(_))[9];
	my $age = $now - $mtime;
	if ($age < $min_mtime_age) {
	  $lok = 0;
	  print "... file '$infile' too recent (age=$age), waiting.\n";
	}
	if ($age < $minage) { $minage = $age; }
      } else {
	## Probably FAcat has already been run
	if ( -s $outfile ) {
	  print "... FAcat output file '$outfile' exists.\n";
	  return 0;
	}
	$lok = 0;
	print "... file '$infile' does not exist, waiting.\n";
      }
    }
    $ok = $lok;
    if ( not $lok ) {
      my $pause = $min_mtime_age + 1 - $minage;
      sleep $pause;
    } else {
      print "... Check_files_ready: minage = $minage seconds\n";
    }
  }
  return 0;
}
