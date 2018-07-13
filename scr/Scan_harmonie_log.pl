#!/usr/bin/perl 
#
# Extract information from HARMONIE logfiles.
# - GPNORM and SPNORM from the forecast
# - CPU time from the forecast
# - Observation usage from the minimzation
# - Cost functions from the minimzation
# - Surface increments from SODA_OI_MAIN
#
# The input is assumed to be HM_Date_YYYYMMDDHH.html files since the 
# date is parsed from the file name.
#
# Ulf Andrae, SMHI, 2012-2013
#


my @expected_files = ('cpu','gpnorm','obsuse','spnorm');

push @INC, "$ENV{HM_LIB}/scr";
require log_parser;

$infile=$ARGV[0] or die "Please give an infile \n";

@tmp = split("_",$infile) ;
$date= pop(@tmp) ;
$date =~ s/\.html//g ;
$date =~ s/ //g;

print "Scan $infile\n\n";
$outfile="$date.dat" ;

# Check what we need to parse and exit if nothing is to be done.
$soda_oi_main_cnt=0;
$runminim_cnt=0;
$forecast_cnt=0;
$lnhdyn=0;

$soda_string="Soda_oi_main" ;
print "soda_string:$soda_string \n";

my $step  ;
open FILE, "< $infile" or die "Could not open $infile \n";

SEARCH : while ( <FILE> ) {

  if ( $_ =~/NAME=(.*)$soda_string\.((\d){1,})/ ) {
   if ( $2 > $soda_oi_main_cnt ) {
    print "Start scan surfass from $soda_string.$2 \n";
    &scan_surfass ;
    print "Complete scan surfass \n\n";
    $soda_oi_main_cnt = $2 ;
   }
  } ;

  if ( $_ =~/NAME=(.*)Minim\.((\d){1,})/ ) {
   if ( $2 > $runminim_cnt ) {
    print "Start scan minim from Minim.$2 \n";
    &scan_minim ;
    print "Complete scan minim \n\n";
    $runminim_cnt = $2 ;
   }
  } ;

 if ( $_ =~/NAME=(.*)Forecast\.((\d){1,})/ ) {
  if ( $2 > $forecast_cnt ) {
    $step=0 ;
    print "Start scan forecast from Forecast.$2 \n";
    &scan_forecast ;
    print "Complete scan forecast \n\n";
    $forecast_cnt = $2 ;
  } ;
 } ;


} ;

close FILE ;

#####################################
#####################################
#####################################

sub get_codetype() {
        chomp ;
        @tmp = split("===",$_);
        $codetype = $tmp[1];
        $codetype =~ s/Report//g;
        $codetype =~ s/\s+/ /g;
        $codetype =~ s/^\s+//g;
        $codetype =~ s/\s+$//g;
        $codetype =~ s/\s/-/g;
        $usage{$codetype} = 1;
};

#####################################
#####################################
#####################################

sub scan_surfass(){

   %surfass = ();
   %surftmp = ();

   PRE_SCAN : while ( <FILE> ) {
     if ( $_ =~/ASSIMILATIONS FOR (.*) POINTS/ ) { 
        last PRE_SCAN ;
     }; 
   }

   SURF_SCAN : while ( <FILE> ) {

     # Terminate scan
     if ( $_ =~/SODA ENDS CORRECTLY/ || $_ =~/after write in PREP file/ || $_ =~/Dir is / ) { 
        print "End with:$_ \n";
        last SURF_SCAN ;
     }; 

     # Recognize and store the increments
     if ( $_ =~ /Mean (.*) increments(.*)/ ) {

       @tmp = split(" ",$_);
       shift(@tmp);

       if ( $tmp[-2] =~ /(.*)\d{1,}(.*)/ ) {
         $num = pop(@tmp) ;
         $val = pop(@tmp) ;
       } else {
         $num = 1;
         $val = pop(@tmp) ;
       }
       if ( $tmp[-1] =~ /increments/ ) {
        $label = shift(@tmp);
       } else {
        $label = $tmp[0]."_".$tmp[3];
       }

       if ( exists( $surftmp{$label}{val} ) ) {
         $surftmp{$label}{val} += $val*$num ;
         $surftmp{$label}{num} += $num ;
       } else {
         $surftmp{$label}{val} = $val*$num ;
         $surftmp{$label}{num} = $num ;
       }
     } ;

   } ;

   for $label ( sort keys %surftmp ) {
     $surfass{0}{$label} = $surftmp{$label}{val} / $surftmp{$label}{num} ;
   }

   $outfile="surfass_$date.dat" ;
   &print_norm($outfile,'surfass');

};

#####################################
#####################################
#####################################

sub scan_forecast(){

   %spnorm = ();
   %gpnorm = ();
   %cpu    = ();
   @times  = () ;

   SCAN : while ( <FILE> ) {
     chomp ;

     # Terminate scan
     if ( $_ =~/END CNT3/ ) { 
        last SCAN ;
     }; 

     # Set time step
     if ( $_ =~/TSTEP=/ ) { ($tmp,$tstep) = split("=",$_); }

     # Check NH status
     if ( $_ =~/LNHDYN =/ ) { @tmp = split(" ",$_);
       $lnhdyn=1 if ( $tmp[5] =~ /T/ ) ;
     };

     # Update current step
     if ( $_ =~/ STEP (.*)H= / ) {
       @tmp = split(" ",$_);
       $step = $tmp[2] * $tstep ;
       $cpu{$step}{CPU} = $tmp[-1] ;
     }; 

     # Get the spectral norms
     if ( $_ =~/SPECTRAL NORMS/ ) {

       @tmp = split(" ",$_);
       $spnorm{$step}{PREHYDS} = pop(@tmp);
       $_ = <FILE> ;
       $_ = <FILE> ;
       @tmp = split(" ",$_);

       $spnorm{$step}{KE}   = pop(@tmp);
       $spnorm{$step}{TEMP} = pop(@tmp);
       $spnorm{$step}{DIV}  = pop(@tmp);
       $spnorm{$step}{VOR}  = pop(@tmp);

       if ( $lnhdyn == 1 ) {
         $_ = <FILE> ;
         $_ = <FILE> ;
         @tmp = split(" ",$_);
         $spnorm{$step}{D4} = pop(@tmp);
         $spnorm{$step}{PRE_PREHYD} = pop(@tmp);
       };

     } ;

     # Get the grid point norms
     if ( $_ =~/ GPNORM / ) {
        @tmp = split(" ",$_);
        $_ = <FILE> ;
        @t2 = split(" ",$_);
        unless ( $tmp[1] =~/OUTPUT/ ) {
          $gpnorm{$step}{$tmp[1]} = $t2[1];
        } ;
     } ;

   } ;

   # Delete the last timestep since
   # it does not have any norms

   delete $gpnorm{$step} ;
   delete $spnorm{$step} ;

   # Print the data files
   $outfile="cpu_$date.dat" ;
   &print_norm($outfile,'cpu');

   $outfile="gpnorm_$date.dat" ;
   &print_norm($outfile,'gpnorm');

   $outfile="spnorm_$date.dat" ;
   &print_norm($outfile,'spnorm');

};

#####################################
#####################################
#####################################

sub scan_minim () {

   %usage = ();
   %costfun = ();
   $codetype ;
   $var ;

   $outfile="obsuse_$date.dat";
   print "Writing to $outfile\n";
   open OUTFILE,"> $outfile ";

   GREP : while ( <FILE> ) {

     chomp ;

     # Terminate scan
     if ( $_ =~/End of variational job/ ) { last GREP ; } ;


     # Get costfunction evaluation
     if ( $_ =~/GREPCOST / ) {
       @tmp = split(" ",$_);
       @lab = split(",",$tmp[2]);
       $jt = 0 ;
       for ( $i=-1 ; $i>-6 ; $i-- ) {
          $costfun{$tmp[3]}{$lab[$i]} = $tmp[$i];
          $jt += $tmp[$i] ;
       } ;
       $costfun{$tmp[3]}{JT} = $jt ;
     } ;

     # Get codetype
     if ( $_ =~/Jo Global / ) { 
       @tmp = split(" ",$_);
       $jon = pop @tmp;
       print "Jo/N $jon \n";
     } ;

     if ( $_ =~/Codetype/ ) { &get_codetype ; } ;

     # Fill the usage hash
     if ( $_ =~/Variable      DataCount/ ) { 
       VAR : while (<FILE>) {
         
         if ( $_ =~/Codetype/ ) { &get_codetype ; next VAR ;};
         if ( $_ =~/Variable/ ) { next VAR ;                };
 
         if ( $_ =~/-----/ ) { last VAR ; } ;

         $_ =~ s/  / /g;
         @tmp = split(" ",$_);
         $var = $tmp[0] ;
         $usage{$codetype}{$var} = $tmp[1] ;
         print OUTFILE "$codetype:$var:$usage{$codetype}{$var} \n";

       }
     } ;

   } ;

   close OUTFILE ;

   $outfile="costfun_$date.dat" ;
   delete($costfun{999});

   &print_norm($outfile,'costfun');

} ;
