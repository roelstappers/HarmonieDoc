#!/usr/bin/perl -w

#
# Parse norm output files and create plots and WebgraF interface
#
# Ulf Andrae, SMHI, 2012
#
# Usage: norm_plot.pl TYPE DTG
# where:
# type = spnorm|gpnorm
# dtg = YYYYMMDDHH|YYYYMM
#

# Load modules
push @INC, "$ENV{HM_LIB}/scr";
require log_parser ;

# Usage
$usage  = " \n USAGE: norm_plot.pl -t TYPE -d DTG [ -s SEARCHDIR ] [ -n NSEARCH ] [ -c CYCLE ] [ -af ]\n\n" ;
$usage .=" -h Displays this help \n" ;
$usage .=" -t Set type gpnorm|spnorm|costfun \n";
$usage .=" -d DTG or subpart of DTG ( for average )\n";
$usage .=" -n NSEARCH number of old cycles to plot \n";
$usage .=" -f forecast interval \n";
$usage .=" -s search directory when doing average \n";
$usage .=" -a Create an average for files matching DTG \n";
$usage .=" -c cycle to be used for average, leave empty for all \n";
$usage .=" -l Cost function curves to be plotted \n";
$usage .=" \n";



#
# Set default value
#

$nsearch = 0;
$type    = "gpnorm";
$psdir   = ".";
$average = 0;
$timeplot = 0;
$cycle   = "";
$costlabels ="JO JB JT" ;

$n = 0 ;
INPUT : while ( <@ARGV> ) {

   if ( /-h/) { die $usage ; } ;
   if ( /-t/) { $type = $ARGV[($n + 1)] } ;
   if ( /-f/) { $fcint = $ARGV[($n + 1)] } ;
   if ( /-ds/){ $sdtg = $ARGV[($n + 1)] ; $timeplot = 1 ; $n++ ; next INPUT ; } ;
   if ( /-d/) { $dtg  = $ARGV[($n + 1)] } ;
   if ( /-c/) { $cycle  = $ARGV[($n + 1)] } ;
   if ( /-l/) { $costlabels = $ARGV[($n + 1)] } ;
   if ( /-s/) { $psdir  = $ARGV[($n + 1)] } ;
   if ( /-n/) { $nsearch = $ARGV[($n + 1)] } ;
   if ( /-a/) { $average = 1 } ;

   $n++ ;

} ;

unless ( $fcint ) { $fcint=$ENV{FCINT} or $fcint=06 ; } ;
die $usage unless ( $dtg ) ;

if ( $timeplot ) {

  &time_plot($type,$sdtg,$dtg) ;
  exit ;

} elsif ( $average ) {
  &ave_norm ;
  $nsearch = 0 ;
  $infile="${type}_${dtg}_$cycle.dat";
} else {
  $infile="${type}_$dtg.dat";
};

if ( $type eq "costfun"  ) { 
  &plot_cost($infile,$dtg) ;
} else { 
  &plot_norm($infile,$dtg) ; 
} ;

sub ave_norm {

#
# Input arguments
#

print "Scan $psdir for files of type $type for period $dtg \n";

#
# Scan for input files, pick all ".dat" files
#

opendir MYDIR, "$psdir" ;
@FILES = grep !/^\.\.?/, readdir MYDIR ;
close MYDIR ;

@FILES = grep /$type/, @FILES ;
@FILES = grep /$dtg/, @FILES ;
@FILES = grep /$cycle.dat/, @FILES ;
@FILES = grep !/${dtg}_(.*)/, @FILES ;
@FILES = sort @FILES  ;

%norm = () ;
%times = () ;

$outfile="${type}_${dtg}_$cycle.dat";

 SCAN : foreach $file (@FILES) {

   if ( $file eq $outfile ) { next SCAN ; } ;
   
   open FILE, "< $file ";  
   print "Working with $file \n";
   @headers = split(" ",<FILE>);
   $nheaders = scalar (@headers) ;
   shift @headers ;
   while (<FILE>) {
     @line = split(" ",$_) ;
     $time = $line[0];
     $i = 0 ;

     foreach $header (@headers) {
       $i ++ ;
       unless ( exists( $norm{$time}{$header} ) ) { $norm{$time}{$header} = 0 ; } ;
       unless ( exists( $times{$time} )         ) { $times{$time} = 0 ; } ;

       $norm{$time}{$header} += $line[$i] ;
       $times{$time} += 1 ;

     };
   };
 };

 # Calc the average
 for $time ( sort keys %times ) {
   for $header ( sort keys %{ $norm{$time} } ) {
     if ( $times{$time} gt 0 ) {
       $norm{$time}{$header} = $norm{$time}{$header} / $times{$time} * $nheaders ;
     } ;
   } ;
 } ;

 &print_norm($outfile,'norm');

} ;
