#!/usr/bin/perl

#
# Extract observation usage from HARMONIE minimization logfiles.
# The input is assumed to be HM_Date_YYYYMMDDHH.html files since the 
# date is parsed from this one.

$infile=$ARGV[0] or die "Please give an infile \n";

@tmp = split("_",$infile) ;
$date= pop(@tmp) ;
$date =~ s/\.html//g ;
$date =~ s/ //g;
$outfile="$date.dat" ;


$continue=1;
$found=0;
open FILE, "< $infile" or die "Could not open $infile \n";
open OUTFILE,"> $outfile ";

print "Scanning $infile \n";

SEARCH : while ( $continue ) {
 $_ = <FILE> ;
 if ( $_ =~/MINIMISATION JOB/ ) {
    $continue = 0 ;
    $found = 1 ;
    last SEARCH ;
 }
 last if eof(FILE);
}

my %usage = ();
my $codetype ;
my $var ;


if ( $found ) {
   print"Writing to $outfile \n";
   $continue = 1;
   GREP : while ( $continue ) {
     $_ = <FILE> ;

     #print "CHECK $_";
     # Exit
     if ( $_ =~/End of JO-table/ ) { last GREP ; } ;

     if ( $_ =~/Obstype/ ) {
        @tmp = split(",",$_);
        @tmp = split("===",$tmp[0]);
        $tmp[1] =~ s/ //g;
     } ;

     if ( $_ =~/Codetype/ ) { &get_codetype ; } ;

     if ( $_ =~/Variable/ ) { 
       VAR : while (<FILE>) {

        #print "CHECK $_";

        if ( $_ =~/Codetype/ ) { &get_codetype ; next VAR ;}
        if ( $_ =~/Variable/ ) { next VAR ;                }

        if ( $_ =~/-----/ ) { last VAR ; }
         $_ =~ s/  / /g;
         @tmp = split(" ",$_);
         $var = $tmp[0] ;
         $usage{$codetype}{$var} = $tmp[1] ;
         #print "USAGE:$codetype:$var:$usage{$codetype}{$var} \n";
         print OUTFILE "$codetype:$var:$usage{$codetype}{$var} \n";
       }
     }
     last if eof(FILE);
   }
}

close FILE ;
close OUTFILE ; 

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
        #print "$codetype \n";
};
