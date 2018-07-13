#!/usr/local/perl
# Actions.pl: take appropriate actions, as per first argument
#             invoked from scripts/Actions upon an action unknown to Actions
# method: the argument list contains:
#	1. action to be taken
#	2-n: arguments passed to action
#	The package 'actions' contains one exportable subroutine, 'actions::action',
#	which 'SelfLoad's the specificied action.
#	A number of actions ('privileged') are simply 'exec'-uted
#	(this requires that the action names an executable - albeit case insensitive)

# author: originated from HIRLAM-utilities by Gerard Cats, 27 November 2001

# allow some format deviations e.g. ignore case, or abbreviations
# ----------------------------
if ( $ARGV[0] =~ s/^\s*Prod\s*$/Prod/i ) {			# Prod
   $ARGV[0] = "Prod";
} elsif ( $ARGV[0] =~ /obsmonprod/ ) {                          # obsmonprod
   $ARGV[0] = "Prod";
} elsif ( $ARGV[0] =~ s/^\s*CleanUp\s*$/CleanUp/i ) {		# CleanUp
   $ARGV[0] = "CleanUp";
   foreach ( @ARGV ) { s/REMOVE=/REMOVE:/ }
} elsif ( $ARGV[0] =~ s/^\s*LocateSource\s*$/LocateSource/i ) {	# LocateSource
   $ARGV[0] = "LocateSource";
} elsif ( $ARGV[0] =~ s/^\s*print\s*$/echo/i ) {		# print -> echo
   $ARGV[0] = "echo";
} elsif ( $ARGV[0] =~ /^\s*showm/i ) {				# showm
   $ARGV[0] = "ShowMods";
} elsif ( $ARGV[0] =~ /^\s*(AnalyseLog|Foll)/i ) {		# AnalyseLog, Foll
   $ARGV[0] = "AnalyseLog";
}
# privileged HARMONIE utilities
# ---------------------------
unless ( $ARGV[0] eq "Prod" ) {
   foreach ( qw( Boot Co Diff diasim mandtg pgb2as ) ) {
      if ( /^\s*$ARGV[0]\s*$/io ) {				# case insensi
         $ARGV[0] = $_;
         exec $_ @ARGV or die "cannot exec @ARGV: $!\n";
      }
   }
}
# invoke action if not one of those utilities
# -------------
actions::action(@ARGV);

# ------------------------------------------------------------------------------
# actions--------------------------actions-------------------------------actions
# ------------------------------------------------------------------------------
package actions;
=head1 NAME

action - execute an action by invoking a subroutine with the name of the action

=head1 SYNOPSIS

action($action, @args_to_action)

=head1 DESCRIPTION

This package 'SelfLoad's the subroutine with name "$action" and
invokes it with arguments @args_to_action.

=head1 BUGS

=head1 AUTHOR

Gerard Cats, 27 November 2001

=cut

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(action);
@EXPORT_OK = qw(DEBUG);

$VERSION = "1.00";

use SelfLoader;
# ------------------------------------------------------------------------------
sub action{
# action: execute specified action
# synopsis: action($action, @args_to_action);
# author: Gerard Cats, 29 November 2001
   my $action = shift;

# requiring utilities
   push @INC, split(":",$ENV{PATH});
   if ( eval "require(\"util.plib\")" ) { $util_found = 1 } else { print $@ }

# invoke actions subroutine
   eval { &$action(@_) };

# print errors (if any), but modify the 'Undefined subroutine found' message
   if ( $error = $@ ) {
      if ( $error =~ /Undefined subroutine .*::$action / ) {
         print STDERR ("Actions.pl: action \"$action\" not implemented; command was: \"",
                       join( " ", @ARGV), "\"\n");
      } else {
         print STDERR "$@\n";
      }
   }
}
# ------------------------------------------------------------------------------
__DATA__
sub CleanUp{
# CleanUp: remove files as per argument list from HM_DATA on all hosts and HM_EXP
# synopsis: CleanUp("REMOVE:patt1,patt2", "REMOVE:patt3,patt4" [,etc] [,-k] [,-ALL] [,-go] );
# author: Gerard Cats, 29 November 2001
# args: if -go: remove, (default is to list but not remove the matching files)
#       if -k*: do not do the long term archive HM_EXP - so keep it
#       if -d*: combination of -k and -ALL (-d* means: disks)
#       if -ALL: treat all files and also (if -go) remove the directories
#       a pattern is usually a string without meta-characters. To this
#       a * is appended (so e.g. ob will affect all files ob*); this can
#       be inhibited by appending ~ (so ob~! translates to ob).
#       Also, files in all subdirectories P*_* will be affected
#       where P is the pattern [0-9][0-9], This resembles
#       a `CYCLEDIR'. So ob will result in 'ob* P*_*/ob*'.
#       The pattern P*_* will be prepended to every / in the pattern,
#       unless the / is preceded by ~ (which will be removed).
#       Hence, to remove e.g. all analyses from 1995, use 1995/an,
#       which translates to 1995[0-9][0-9]*_*/an*
#       (to be precise: use: CleanUp("REMOVE:1995/an", "-go");

  my @args =();
# process argument lists
   foreach ( @ARGV ) {
      ( $all = 1,	next ) if /^-ALL$/;
      ( $keep = 1,	next ) if /^-k/;
      ( $go = 1,	next ) if /^-go/;
      ( $all = $keep = 1,	next ) if /^-d/;
      push( @args, (split ",") ) if ( s/REMOVE:// );
   }
# append * unless ending in ~; prepend all CYCLEDIRs unless already something there
  my @dirs = ();
  foreach ( @args ) {
     $_ .= "*" unless s/~$//;
     if ( /\// ) {
        s(([^~])/)($1\[0-9][0-9]*_*/)g;
        s(^/)([0-9][0-9]*_*/);
        s(~/)(/)g;
     } else {
        push( @dirs, "[0-9][0-9]*_*/$_" );
     }
  }
# get required environment
   foreach $var ( qw / EXP HM_DATA HM_LIB ENV_SYSTEM /) {
      $$var=$ENV{$var} || die "$var not in the environment; stopped";
   }
# get the optional environment
   my $i = 0;
   $i ++ while ( $hosts[$i] = $ENV{"HOST$i"} ); $#hosts --;
   foreach $var ( qw / SMSNODE /) {
      $$var=$ENV{$var};
   }

# SMSNODE defaults to the current host
   $myhost = `hostname`; chomp( $myhost );
   $SMSNODE = $SMSNODE || $myhost;

# diagnose:
  print $go	? "removing " : "listing (give '-go' to remove) ",
        $all	? "directories " : "files " . join(", ", @args, @dirs) . "\nin ",
        $keep	? "" : "HM_EXP, HM_LIB and ", "HM_DATA on hosts: ",
        join(", ", @hosts), "\n";

# action: list, unless -go was set
   my $action = $go ? "" : "-ls";	# settings for HM_EXP

# cleanup HM_EXP
   unless ( $keep ) {
      foreach $var ( qw / HM_EXP COMPCENTRE /) {
         $$var=$ENV{$var} || die "$var not in the environment; stopped";
      }
      my @hm_exps = ( $HM_EXP );
      if ( $COMPCENTRE eq 'ECMWF' ) {
	 @hm_exps = ( "ec:$HM_EXP", "ectmp:$HM_EXP" );
      }
      for my $hm_exp ( @hm_exps ) {
	 print "\nTreating HM_EXP ($hm_exp):\n";
	 if ( $all ) {
#           system( qw/ perl -S Clean_lpfs.pl/, $action, "--", "*" );
	    my $act = $go ? "-rm" : "-ls";
	    system( "Access_lpfs $act $hm_exp" );	# recursive actions
	 } else {
	    system( "perl -S Clean_lpfs.pl", $action, "--", grep( !/\//, @args ) );
	 }
      }
   }
# action: list, unless -go was set
   my $rsh = $ENV{RSH} || 'rsh';
   my $rf = $all ? " -rf" :"";		# force!
   $action = $go ? "rm$rf" : "ls";	# settings for HM_DATA

# files, and directory
   $files = join( " ", @args, @dirs ) unless $all;
   $bck   = $all ? "/.." : "";		# remove hm_data from parent directory

# cleanup HM_DATA on all hosts, but treat SMSNODE (if in) separately, in the end
  my @cleandirs = ('HM_LIB','HM_DATA','PARCH');

  foreach my $cleand ( @cleandirs  ) {
   foreach my $host ( @hosts ) {
      next if ( $host eq $SMSNODE || $host eq $myhost );
      $hm_data=`( SMSHOST=$host; . $ENV_SYSTEM >/dev/null 2>&1 ; echo \$$cleand )`;
      chomp( $hm_data );
      next if ( $hm_data eq ""  ) ;
      print "\nTreating $cleand on $host ($hm_data):\n";
      $files = $hm_data if $all;	# remove the whole directory
      system "$rsh", $host, "bash", "-c", "'[ -d $hm_data ] || exit; cd $hm_data$bck; $action $files 2>/dev/null'";
   }
  }
# now do this host
  foreach my $host ( @hosts ) {
   foreach my $cleankey ( @cleandirs  ) {
      $cleand = $${cleankey} ;
      next unless ( $host eq $myhost );
      if ( -d $cleand ) {
         print "\nTreating $cleankey on $host ($cleand):\n";
         $files = $cleand if $all;	# remove the whole directory
         chdir "$cleand$bck";
         system "bash", "-c", "$action $files 2>/dev/null";
      }
      my $dir = "$ENV{ JOBOUTDIR }/$EXP";
      if ( -d $dir ) {
         print "\nTreating JOBOUTDIR on $host ($dir):\n";
         $files = $dir if $all;	# remove the whole directory
         chdir "$dir$bck";
         system "bash", "-c", "$action $files 2>/dev/null";
      }
   }
  }
# finally, do SMSNODE, unless this is myhost
  foreach my $cleand ( @cleandirs  ) {
   foreach my $host ( @hosts ) {
      next unless ( $host eq $SMSNODE );
      next if ( $host eq $myhost );
      $hm_data=`( SMSHOST=$host; . $ENV_SYSTEM >/dev/null 2>&1 ; echo \$$cleand )`;
      chomp( $hm_data );
      print "\nTreating $celand on $host ($hm_data):\n";
      $files = $hm_data if $all;	# remove the whole directory
      system "$rsh", $host, "bash", "-c", "'[ -d $hm_data ] || exit; cd $hm_data$bck; $action $files 2>/dev/null'";
   }
  }
}
# ------------------------------------------------------------------------------
sub echo{
# echo: print variables
# synopsis: echo([-csh,][-sh,]@vars)
# author: Gerard Cats, 3 December 2001
# method: print variables; if none given, print the environment
#	 if -csh or -sh: use shell syntax, else some pretty print
   my ( $string, $from, $sh);
# options and arguments:
   while ( $_[0] =~ s/^-// ) {
      $_ = shift;
      last if /^-$/;
      $sh = "csh" if /^csh$/;
      $sh = "sh"  if /^k?sh$/;
      $sh = "perl"  if /^pe/;
   }
# print environment if no arguments remain
   ( @_ )=  ( sort( keys %ENV ) ) unless defined( $_[0] );

   if ( $sh ) {
# some shell syntax
      foreach ( @_ ) {
         if ( defined( $ENV{$_} ) ) {
            if ( $sh eq "sh" ) {
               print "$_=\"$ENV{$_}\" export $_\n";
            } elsif ( $sh eq "perl" ) {
               print "\$ENV{$_} = '$ENV{$_}';\n";
            } else {
               print "setenv $_ \"$ENV{$_}\"\n";
            }
         } elsif ( defined( $$_ ) ) {
            if ( $sh eq "sh" ) {
               print "$_=\"$$_\"\n";
            } elsif ( $sh eq "perl" ) {
               print "\$$_ = '$$_';\n";
            } else {
               print "set $_=\"$$_\"\n";
            }
         }
      }

   } else {

# just some print
      format STDOUT =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<# @<<<<<
$string, $from
.
      foreach ( @_ ) {
         if ( defined( $ENV{$_} ) ) {
            $string = "$_=\"$ENV{$_}\""; $from = "envmt";
         } elsif ( defined( $$_ ) ) {
            $string = "$_=\"$$_\""; $from = "local";
         } elsif ( defined( $ENV{SETENV} ) and $util_found ) {
            my $var = $_;
            my $val = g_setenv( $var );
            if ( $val ) {
               $string = "$var=\"$val\""; $from = "SETENV";
            } else {
               $string = "$var="; $from = "notset";
            }
         } else {
            $string = "$_="; $from = "notset";
         }
         if ( length( $string ) < 72 ) {
            write;
         } else {
            print "$string # $from\n";
         }
      }
   }
}
# ------------------------------------------------------------------------------
sub LocateSource{
# LocateSource: print list of sources matching the patterns in ListOfFiles
# synopsis: LocateSource( @ListOfFiles);
   my %list = WhereSource( @_ );
   foreach ( @_ ) {
      my @files = split(" ", $list{$_});
      my @srcs = grep !/-d\.html$/, @files;
      my @html = grep  /-d\.html$/, @files;
      if ( @srcs ) {
          print "@srcs\n";
      } else {
          print STDERR "nothing matching $_\n";
      }
      print "@html\n" if @html;
   }
}
# ------------------------------------------------------------------------------
sub Prod{
# Prod: continue an experiment, start if new, but do nothing if running already
# synopsis: Prod( [-c,][-db,][-f,][--,] $schedule [$check_q] );
# author: Gerard Cats, 3 December 2001
# method:
#	If there is a file $check_q (default: check_q), execute
#	it. If this completes OK:
#	Check whether there is a Prod possibly still active (unless '-f')
#	Check whether there is a "DEFFILE" possibly still active (unless '-f')
#	Execute $schedule (default = schedule) if existing
#	Pass DTG, LL, PROD, ... as given in $schedule to the environment
#	Invoke "Actions $action" where $action is continue or start,
#	depending on the presence of $HM_WD/progress.log - but possibly
#	overridden by $schedule
# -c:	use the environment from $HM_DATA/_mSMS_env
#	(this file was written by an earlier execution of Prod)
# -db:	debug: just print the command to be executed, but do not submit it
# -f:	force execution even if another run is seemingly active

   my $continue; 	# read and/or write a continuation schedule
   my $debug; 		# print the command to be executed, do not submit it
   my $force; 		# force execution even if locks seem to exist
# list of environment variables likely to be transfered from the schedule
   my @env = ( qw/ DEBUG DTG DTGEND LL PLAYFILE PROD DTGPP / );


# get required environment
   foreach $var ( qw / HM_DATA HM_WD /) {
      $$var=$ENV{$var} || die "$var not in the environment; stopped";
   }
# get optional environment
#	some have  a default
   $ENV{PROD}     = $ENV{PROD}     || 1;
#	transfer into the corresponding local variables
   foreach ( @env ) {
      $$_ = $ENV{$_} || undef;
   }
# options and arguments:
   while ( $_[0] =~ s/^-// ) {
      $_ = shift;
      last if /^-$/;
      $continue = 1 if /^c$/;
      $debug = 1 if /^db$/;
      $force = 1 if /^f$/;
   }
   my $schedule = shift || "schedule";
   my $check_q  = shift || "check_q";
   my $cont_file = "$HM_DATA/_mSMS_env";

# execute the check-q (if found)
   if ( -s $check_q ) {
      eval `cat $check_q`;	# cannot use 'do' to allow exchange of lexicals
      die "$check_q failed: $@" if $@;
   }
# check no other mini-SMS active by the file $HM_DATA/mSMS.pid
   chdir $HM_DATA or die "could not chdir to $HM_DATA";
   if ( ! $force && -r "mSMS.pid" ) {
      print STDERR "file mSMS.pid exists\n",
                   "\tProd assumes there is a $PLAYFILE active\n",
                   "\tremove $HM_DATA/mSMS.pid if you want to start anyhow\n";
      exit;
   }

# inspect there is no PLAYFILE run active
# this is done by checking the last-modify time of all .check files
#   if ( ! $force && time - (stat( "$PLAYFILE.check" ))[9] < 300 ) {
#      print STDERR "file $PLAYFILE.check has recently been modified\n",
#                   "\tProd assumes there is a $PLAYFILE run active\n",
#                   "\tremove $HM_DATA/$PLAYFILE.check if you want to start anyhow\n";
#      exit;
#   }
# continuation? let the continuation file define the environment
   if ( $continue ) {
      if ( $ENV{SCHEDULER} ne "ECFLOW" and -s $cont_file ) {
         undef %ENV;
         eval `cat $cont_file`;	# cannot use 'do' to allow exchange of lexicals
         die "$cont_file failed: $@" if $@;
      }
   }
# if there is a progress.log, assume we want to continue, else start
   chdir $HM_WD or die "could not chdir to $HM_WD";
   my $action;
   if ( open (PROGRESS, "<progress.log") ) {
      $action = "continue";
      if (defined $DTG) {
	 $DTGPP = $DTG unless defined($DTGPP);
      } else { 
	 while ( <PROGRESS> ) {
	    $DTG = $1 if /^\s*DTG=([0-9]{10})/;
	 }
      }
      close PROGRESS;
   } else {
      $action = "start";
   }
   if ( open (PROGRESS, "<progressPP.log") ) {
      unless (defined $DTGPP) { 
	 while ( <PROGRESS> ) {
	    $DTGPP = $1 if /^\s*DTGPP=([0-9]{10})/;
	 }
      }
      close PROGRESS;
   }
   $DTGPP = $DTG unless defined($DTGPP);
# execute the schedule (if found)
   if ( -s $schedule ) {
      eval `cat $schedule`;	# cannot use 'do' to allow exchange of lexicals
      die "$schedule failed: $@" if $@;
   }
# DTGEND defaults to DTG if unset
   $DTGEND = $ENV{DTGEND} || $DTG;
   die "ERROR: DTGEND($DTGEND) should not be less than DTG($DTG)\n" if ( $DTGEND lt $DTG )  ;

# transfer the corresponding local variables into the environment
   foreach ( @env ) {
      if ( $$_ ) {
         $ENV{$_} = $$_;
      }
   }
# check consistency
   if ( $action =~ /prod/i ) {
      print STDERR "Warning: recurrent invocation of prod may cause infinite loop\n";
   }
# write the environment to the continuation file
#   if ( open( CONT, ">$cont_file") ) {
#      foreach ( sort keys %ENV ) {
#         print CONT '$ENV{' . "$_} = '$ENV{$_}';\n";
#      }
#      close CONT;
#   } else {
#      die "could not write to $cont_file, $!";
#   }
# act!
   print "to submit:$ll DTG=$ENV{DTG} DTGEND=$ENV{DTGEND} DTGPP=$ENV{DTGPP} Actions $action ", join(" ", @args),"\n";
   exit if $debug;
   $! = undef;
   $ENV{ HM_CLA } .= "$ll DTGEND=$ENV{DTGEND} DTGPP=$ENV{DTGPP}";
   system "Actions", $action, @args;
   print STDERR "'Actions $action ", join(" ", @args),"' reported: $!\n" if $!;

# cleaning up
END
# cleanup lock file
   {
# note that this will also happen if the lockfile was not produced
# by this run. So a next execution will not know about possible
# earlier ones. This 'feature' protects against the possibility that
# the lock file hung, but it will cause errors if there is an earlier
# run still active.
#??     unlink "$HM_DATA/_prod_$PLAYFILE.lock";
#??     close LOCKFILE;
   }
}
# ------------------------------------------------------------------------------
sub WhereSource{
# WhereSource: return a hash with the libraries containing the source(s)
# synopsis: %ListOfSources = WhereSource( @ListOfStartPatterns);
# author: Gerard Cats, 3 December 2001

   my @list = @_;
   my %locs = ();

# get required environment
   foreach $var ( qw / HM_REF_CP /) {
      $$var=$ENV{$var} || die "$var not in the environment; stopped";
   }
  chdir "$HM_REF_CP/src" or die "couldn't chdir to $HM_REF_CP/src\n";
  foreach $rcs ( <*/RCS> ) {
     my $lib = $rcs; $lib =~ s(/RCS$)();
     chdir $rcs;
     my @ls = <*,v>;
     foreach ( @ls ) { s/,v$// };
     foreach $file ( @list ) {
        $locs{$file} .= join("", map /^$file(\.|-|$)/i ? "$lib/$_ " : "", @ls);
     }
     chdir "../..";
  }
  return %locs;
}
# ------------------------------------------------------------------------------
sub AnalyseLog{
# AnalyseLog: display the mods by the current experiment
# synopsis: &AnalyseLog
# author: Gerard Cats, 3 January 2004

   my $HM_DATA = $ENV{ HM_DATA };
   my $PLAYFILE = $ENV{PLAYFILE} || "harmonie";
   die "Cannot read $HM_DATA/$PLAYFILE.log\n" unless -s "$HM_DATA/$PLAYFILE.log";

   print " submitd  active  - complete or aborted   note   node\n";
   print "OR:                 counter changed at  to       counter\n";
   open( LOG, "$HM_DATA/$PLAYFILE.log") or die "cannot open $HM_DATA/$PLAYFILE.log\n";
LINE: while ( <LOG> ) {
      my ( $log, $status, $node ) = ( m~# LOG:\[([^\]]+)\] ([^:]+):(.*)~ );
      if ( $status eq "complete" or $status eq "aborted" ) {
         my $s = $status eq "aborted" ? "[1maborted[m " : "        ";
         if ( defined $logs{ $node } ) {
            print "$logs{$node} - $log $s $node\n";
            delete $logs{ $node };		# allow again
         }
         next LINE;
      } elsif ( $status eq "active" or $status eq "submitted" ) {
   # skip if this is a family, remove family of which this is a child
         foreach $n ( keys %logs ) {
            if ( $n =~ m~^$node/~ ) {	# $node is a family containing $n
               next LINE;
            } elsif ( $node =~ m~^$n/~ ) {	# $n is a family containing $node
               delete $logs{ $n };
            }
         }
         $log =~ s~ .*~~;			# select time only
         if ( $status eq "submitted" ) {
           $logs{ $node } = $log;
         } else {
           $logs{ $node } .= " " . $log;
         }
         next LINE;
      }
# find counter upgrades
      ( $log, $node, $status ) = ( m~# LOG:\[([^\]]+)\] [^:]*:(.*) to (.*)~ );
      if ( $status ) {
         $status .= " " x ( 8-length($status) );
         print "                    $log $status $node\n";
         next LINE;
      }
   }
# remaining tasks are probably still active or submitted
   foreach ( keys %logs ) {
      if ( $logs{$_} =~ / / ) {
         print "$logs{$_} -                     active?  $_\n";
      } else {
         print "$logs{$_}          -                     submitd? $_\n";
      }
   }
   close LOG;
}
# ------------------------------------------------------------------------------
sub chgrp {
   my($newgrp) = shift;
   chomp(my $groups = qx(groups));
   die "Please give a group name, one of: $groups\n"
       unless ($newgrp);
   die "You don't appear to be member of group '$newgrp'\n"
       unless ($groups =~ /\b$newgrp\b/);
   
# get required environment
   foreach $var ( qw / EXP HM_DATA ENV_SYSTEM /) {
      $$var=$ENV{$var} || die "$var not in the environment; stopped";
   }
# get the optional environment
   my $i = 0;
   $i++ while ( $hosts[$i] = $ENV{"HOST$i"} ); $#hosts --;
   foreach $var ( qw / SMSNODE /) {
      $$var=$ENV{$var};
   }

# SMSNODE defaults to the current host
   chomp($myhost = qx(hostname));
   $SMSNODE = $SMSNODE || $myhost;

   my $action = "chgrp -Rh $newgrp .";
   my $rsh = $ENV{RSH} || 'rsh';

# treat HM_DATA on all hosts, but treat SMSNODE (if in) separately, in the end
   foreach my $host ( @hosts ) {
      next if ( $host eq $SMSNODE || $host eq $myhost );
      chomp($hm_data=qx(( SMSHOST=$host . $ENV_SYSTEM; echo \$HM_DATA )));
      print "treating HM_DATA on remote host $host ($hm_data):\n";
      my $cmd = "\'cd $hm_data \&\& $action\'";
      system "$rsh $host $cmd";
   }
# now do this host
   foreach my $host ( @hosts ) {
      next unless ( $host eq $myhost );
      if ( -d $HM_DATA ) {
         print "treating HM_DATA on $host ($HM_DATA):\n";
         chdir $HM_DATA;
         system "$action";
      }
      my $dir = "$ENV{JOBOUTDIR}/$EXP";
      if ( -d $dir ) {
         print "treating JOBOUTDIR on $host ($dir):\n";
         chdir $dir;
         system "$action";
      }
   }
# finally, do SMSNODE, unless this is myhost
   foreach my $host ( @hosts ) {
      next unless ( $host eq $SMSNODE );
      next if ( $host eq $myhost );
      chomp($hm_data=qx(( SMSHOST=$host . $ENV_SYSTEM; echo \$HM_DATA )));
      print "treating HM_DATA on $host ($hm_data):\n";
      system "$rsh", $host, "sh", "-c", "'[ -d $hm_data ] || exit; cd $hm_data; $action'";
   }
# treat HM_EXP (but only at ECMWF)
   foreach $var ( qw / HM_EXP COMPCENTRE /) {
      $$var=$ENV{$var} || die "$var not in the environment; stopped";
   }
   if ( $COMPCENTRE eq 'ECMWF' ) {
      for my $hm_exp (  "ec:$HM_EXP", "ectmp:$HM_EXP" ) {
	 print "treating HM_EXP ($hm_exp):\n";
	 system "~nhk/bin/edch -g $newgrp $hm_exp";
      }
   }
}
