#!/usr/bin/perl -w

#
# Parse output files from Get_obsusage.pl, create plots and WebgraF interface
#
# Ulf Andrae, SMHI, 2011
#


# Declarations
$missing ="-999.";
my %dates = () ;
my %ct = ();

#
# Input arguments
#

$PSDIR=$ARGV[0] or $PSDIR=".";
$pattern = $ARGV[1] or $pattern = "";

print "Scan $PSDIR for files with pattern $pattern \n";

#
# Scan for input files, pick all ".dat" files
#

opendir MYDIR, "$PSDIR" ;
@FILES = grep !/^\.\.?/, readdir MYDIR ;
close MYDIR ;
@FILES = grep /obsuse/, @FILES ;
@FILES = grep /dat/, @FILES ;
@FILES = sort @FILES  ;

print "@FILES \n";

#
# Scan through all the files 
#

$firstdate=$FILES[0] ;
$firstdate =~s/(obsuse_)(.*)(\.dat)/$2/g;

print "Read input files, firstdate=$firstdate \n";

TIME : foreach $FILE ( @FILES ) {

   if ( $pattern ne "" ) {
      unless ( $FILE =~ /$pattern/ ) { next TIME ; } ;
   } ;

   $date= $FILE ;
   $date =~s/(obsuse_)(.*)(\.dat)/$2/g;
   $lastdate = $date ;

   $dates{$date} = 1 ;
   $FILE="$PSDIR/$FILE";
   if ( ! -e $FILE ) { print " Could not find $FILE \n" ; next TIME } ;
   open FILE, "< $FILE" ;

   print "Scan $FILE\n";

   while (<FILE>) {
     chomp ;
     ($codetype,$var,$val) = split(":",$_);
     $ct{$codetype}{$var} = 1;
     ${$codetype}{$date}{$var} = $val;
     #print "$codetype $date $var ${$codetype}{$date}{$var} \n";
   } ;

   close FILE ;
};


#
# Fill missing data
#

$fcint=$ENV{FCINT} or $fcint=06;

print "Fill gaps with missing data \n";

FILL : while ( $firstdate <= $lastdate ) {

  print "DATE $firstdate \n";
  $firstdate=`mandtg $firstdate + $fcint`; chop $firstdate;


  if ( $pattern ne "" ) {
    if ( $firstdate =~ /$pattern/ ) { next FILL ; } ;
  } ;

  unless ( exists($dates{$firstdate} ) ) {

    for $codetype ( keys(%ct) ) {
       for $var ( sort keys %${codetype} ) {
          ${$codetype}{$firstdate}{$var} = $missing ; 
       } ;
    } ;
   
  } 

} ;




#
# Print usage per codetype
#
@HOURS  = ();
@OFILES = () ;
@CT     = () ;

$i = ( $lastdate % 100 ) % $fcint  ;
while ( $i < 24) { @HOURS = (@HOURS,$i); $i+=$fcint ;} ;

for $codetype ( keys(%ct) ) {

  @CT=(@CT,$codetype);

  for $hh (@HOURS) {
    
    $hh = sprintf("%.2i",$hh) ;
    $ofile = $codetype."_".$hh.".txt" ;
    @OFILES = (@OFILES,$ofile);
    open OFILE, ">$ofile";
    print "Create $ofile \n";
    $tmp = "";
    for $var ( sort keys %{$ct{$codetype}} ) { $tmp .=" ".$var ; } ;
    $tmp =~ s/^ //g;
    print OFILE "# $codetype $hh $tmp \n";

    DATES : for $date ( sort keys %${codetype} ) {

       unless ( $date % 100 == $hh  ) { next DATES ; } ;
       if ( $pattern ne "" ) { unless ( $date =~ /$pattern/ ) { next DATES ; } ; } ;

       # Fill empty values
       $tmp = ""; 
       for $var ( sort keys %{$ct{$codetype}} ) {
          unless ( exists ( ${$codetype}{$date}{$var} ) ) { print "Fill missing $date,$var \n"; ${$codetype}{$date}{$var} = $missing ; } ;
          $tmp = $tmp." ".${$codetype}{$date}{$var} ;
       } 
       print OFILE "$date $tmp\n";
   } ;
   close OFILE ; 
  } ;
} ;

#
# Create gnuplot file and png plots
#

@LABELS = ();

PLOTS : foreach $FILE ( @OFILES ) {

# Read labels
open FILE,"<$FILE";
@VAR = split(" ",<FILE>);
shift @VAR;
$label = shift @VAR;
$hh    = shift @VAR;
@LABELS = (@LABELS,$label);


$fileout = "${pattern}_${label}_${hh}" ;

open GP, ">$fileout.gp";

$lastvar=pop(@VAR);

print GP <<EOF;
#
#
set terminal png
set output '$fileout.png'

set datafile missing "$missing"
set title "Number of $label observations at $pattern $hh UTC"
set xlabel "Date and Time"
set ylabel "No of obs"
set timefmt "%Y%m%d%H"
set xdata time
set format x "%d/%m\\n%H"
set grid
plot \\
EOF

$i=1;
for $var (@VAR) {
  $i++ ;
  print GP "'$FILE' using 1:$i title  '$var' with lines lt $i lw 4, ";
};

$i++ ;
print GP "'$FILE' using 1:$i title  '$lastvar' with lines lt $i lw 4\n";
close GP ;

print "Plot $fileout.png\n";
system("gnuplot $fileout.gp") ;

};

#
# Create WebgraF interface
#

print "\nCreate WebgraF interface \n";

@CT= sort @CT;
$hours ='\''.join('\',\'',@HOURS).'\'';
$types ='\''.join('\',\'',@CT).'\'';

$types =~ s/\.txt//g;

open GP, ">input.js";

print GP <<EOF;
title='Observation usage timeseries'

loc = ['l','t','l']
mname=['Period','Obstype','Hour']

v[0] = ['$pattern']
t[0] = v[0]

v[1]=[$types]
t[1]=v[1]

v[2]=[$hours]
t[2]=v[2]

sep = '_'
ext='png'

pdir='obs_usage/'

EOF
