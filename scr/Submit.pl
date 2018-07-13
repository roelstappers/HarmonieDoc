#!/usr/bin/perl
# $Id: Submit.pl 4885 2007-01-24 19:13:26Z xiaohua $
# Analyse the arguments

$SCHEDULER = $ENV{SCHEDULER} || 'ECFLOW';

while ( $#ARGV >=0 )  {
  $_ = $ARGV[0];
  if ( s/^-// ) {
    if    ( /^o/	) {
      ( $jobout = $ARGV[1], shift ) if defined $ARGV[1] ;
      #die "$0: Bad jobout file: '$jobout'\n" unless ($jobout);
      my($pre,$tryno) = ($jobout =~ /^(.+)\.(\d+)$/);
      if ($tryno) {
        for $oldout (<$pre.*>) {
	  my($n) = ($oldout =~ /\.(\d+)$/);
	  ## Try numbers greater or equal this one must be old, remove those log files
	  if ($n >= $tryno) {
	    print "Removing old output file '$oldout'\n";
	    unlink $oldout;
	  }
        }
      }
    }
       
    if    ( /^y/	) { ( $YMD = $ARGV[1], shift ) if defined $ARGV[1] }
    if    ( /^h/	) { ( $HH = $ARGV[1], shift ) if defined $ARGV[1] }
    if    ( /^e/	) { ( $ENSMBR = $ARGV[1], shift ) if defined $ARGV[1] }
    if    ( /^d/	) { ( $HM_DATA = $ARGV[1], shift ) if defined $ARGV[1] }
    if    ( /^s/	) { ( $HOST = $ARGV[1], shift ) if defined $ARGV[1] }
    if    ( /^p/	) { ( $PORT = $ARGV[1], shift ) if defined $ARGV[1] }
  } else {
    die $usage if $jobfile;
    $jobfile = $_;
  }
  shift;
}
die $usage unless ( $jobfile && -s $jobfile );

# get the optional environment variables (possibly overridden by what is in the jobfile)
if ( $SCHEDULER eq "ECFLOW" ) {
   my $submitenv = "$HM_DATA/_ecFlow_submit_env";
   require "$submitenv" or die "Could not load $submitenv\n";
}

$__mSMS__ = $ENV{__mSMS__};

## Set up trap handler
$SIG{__DIE__} = sub {
   my($msg) = @_;
   chomp($msg);
   print STDERR "$msg\n" if ($msg); 
   if ( $SCHEDULER eq 'ECFLOW' ) {
     my $signal = $complete ? 'complete' : 'aborted';
     my $smsname = $ECF_NAME; $smsname =~ s~/~%~g;
     if ( open( JOBOUT, ">$jobout" ) ) {
       print JOBOUT " Task $signal before submission\n";
       close JOBOUT;
     }
     $ecf_command = "ecflow_client --force=$signal $ECF_NAME --port $PORT --host $HOST";
     system("$ecf_command");
   } else {
    if ( $__mSMS__ ) {	# signal mini-SMS
      my $signal = $complete ? 'complete' : 'aborted';
      if ( $ENV{mSMS_SIGNAL_TRANSPORT} eq 'http' ) {
	    system "msms_client -p $SMSNAME -s active";
	    system "msms_client -p $SMSNAME -s $signal";
      } else {
        my $smsname = $SMSNAME; $smsname =~ s~/~%~g;
        open SGN, ">$SMSFLAGDIR/$smsname.active";
        close SGN;
        if ( open( JOBOUT, ">$jobout" ) ) {
	     print JOBOUT "SMS-> $signal\n";
	     close JOBOUT;
	    }
	    open SGN, ">$SMSFLAGDIR/$smsname.$signal";
	    close SGN;
      }
    }
   }
  
   exit( $complete ? 0 : 1 );
};


$RCP = $ENV{ RCP } || "rcp";
$RSH = $ENV{ RSH } || "rsh";

# read the jobfile and extract environment variables
open( JOBF, "<$jobfile" ) or die "Cannot read $jobfile: $!\n";
@job = <JOBF>;
close JOBF;

# extract the exported variables from jobfile
foreach ( @job ) {
   if  ( m~(\w+)=(.*)\sexport\s+(\w+)\s*($|#)~ and $1 eq $3 ) {
      my ($var, $val ) = ( $1, $2 );
      $val  =~ s~\s*$~~;	# remove trailing white space
      $$var = $val;
   }
}
# get the required environment variables

foreach $var ( qw/ HM_LIB COMPCENTRE / ) {
   $$var=$ENV{$var} || die "Submit.pl:$var not in the environment\n";
}

use Cwd;

$hm_lib = "$HM_LIB/scr";
if ( $SCHEDULER eq 'ECFLOW' ) { $SMSNAME=$ECF_NAME ; }
$submission = $ENV{SUBMISSION} || "$hm_lib/submission.db";
unless ( do $submission ) {
   die "could not compile submission data: $@\n" if $@;
   die "could not load submission data: $!\n";
}

# skip completed job, but activate trap handler
die "\n" if ($complete);

# substitutions

# process headers and trailers
$headers  = Edit( $headers,  %edit );
$trailers = Edit( $trailers, %edit );

# write the jobfile
open( JOBF, ">$jobfile-q" ) or die "Cannot write $jobfile-q: $!\n";
print JOBF $headers;
foreach ( @job ) {
# if the line is to export a variable, export the new value
   if  ( m~(\w+)=(.*)\s+export\s(\w+)\s*($|#)~ and $1 eq $3 ) {
      print JOBF "$1=$$1 export $1\n";
   } else {
      print JOBF $_;
   }
}
print JOBF $trailers;
close JOBF;
chmod 0744, "$jobfile-q";

# the submission sequence
$submit  = Edit( $submit,  %edit );

# submit job
if ( $ENV{ DEBUG } > 8 ) {
   print "submit is $submit\n";
   die "job not submitted because DEBUG exceeds 8\n";
} else {

   local ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime();
   ( $year += 1900 ) if ( $year < 1900 );
   $mon ++;
   foreach ($hour,$min,$sec,$mday,$mon ){
      $_=sprintf "%2.2d",$_;
   }
   $curlog   = "[$hour:$min:$sec $mday.$mon.$year]";

   print "$curlog To submit: $submit\n";
   system( $submit ) && die "system( $submit ) failed: $?\n";
}

# ------------------------------------------------------------------------------
sub Edit{
# Edit: edit a string (NB: no recursion yet!)
# synopsis: $edited = Edit ( $unedited)
# author: Gerard Cats, 15 April 2004
   my $string = shift;
   my %edit   = @_;
   while (($key,$val) = each %edit ) {
      $string =~ s~%$key%~$val~g;
   }
   return $string;
}
# ------------------------------------------------------------------------------
# Exit:
# Upon exit, some information may have to be passed to (mini-)SMS:
# 1. If aborted, signal that
# 2. if OK, but $complete is set to non-zero, the job does not have to
#	be executed at all. In that case, signal 'complete'
# author: Gerard Cats, 18 April 2004
