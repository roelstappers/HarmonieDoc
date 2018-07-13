##$DEBUG = 1;
##if ($DEBUG) {
##   open(DEBUG,">$ENV{HM_DATA}/debug.log");
##}

# look for suite specific configuration file
my $suite = $ENV{PLAYFILE} || 'harmonie';
eval { require $ENV{HM_LIB}."/msms/$suite.pm"; };
if ( $@ ) {
   print STDERR "$@\n";
   print STDERR "No suite specific definitions ($suite.pm) loaded.\n";
   exit 0;
} else {
   print STDERR "Loaded suite configuration $suite.pm.\n";
}

# special handling of FCINT
unless ( $ENV{FCINT} ) {
   $ENV{FCINT} = &Env('FCINT',-1);
}

my %DEFENV = %ENV;

for my $eee ( split(':',$ENV{ENSMSELX}) ) {
   my $file = "# Member specific settings\n";
   for my $var ( sort keys %env ) {
      $defenv = $ENV{$var};
      $newenv = &Env($var,$eee);
##      print STDERR "$eee $var '$defenv' -> '$newenv'\n";
      if ($newenv ne $defenv) {
	 $file .= "$var=\"$newenv\"\n";
      }
      $ENV{$var} = $newenv;
   }
   ## Special check on DTGBEG 
   my $dtgbeg = $ENV{DTGBEG} || $ENV{DTG};
   my $hhbeg = substr($dtgbeg,8,2);
   my @cycles = &expand_list($ENV{HH_LIST},"%d");
   push(@cycles,$cycles[0]+24);
   my $found = 0;
   my $next = -1;
   for (my $i=0; $i<=$#cycles; $i++) {
      my $hh = $cycles[$i];
      if ($hh == $hhbeg) {
	 $found = 1;
	 last;
      } elsif ( $hh > $hhbeg ) {
	 $next = sprintf "%02d", $hh % 24;
	 last;
      }
   }
   if ( not $found ) {
      if ( $next < 0 ) {
	 # This should never happen, but ...
	 die "Internal error, could not determine DTGBEG for member $eee\n";
      } else {
	 $file .= "DTGBEG=".substr($dtgbeg,0,8).$next."\n";
      }
   }
   $file .= "# End of member specific settings\n";
   my $ret = system "perl -S CheckOptions.pl -d";   # dry run
   if ($ret) {
      my $ensmbr = sprintf("%d",$eee);
      die "CheckOptions.pl failed for member $ensmbr - abort!\n";
   }
   $config_mbr = $ENV{HM_LIB}."/sms/config_mbr$eee.h";
   open CU, ">$config_mbr" or die "Cannot open $config_mbr\n";
   print CU $file;
   close CU;
   %ENV = %DEFENV;
}
