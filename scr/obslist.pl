#!/usr/bin/perl -w

 #
 # Ulf Andrae, SMHI, 2004
 #

$PSDIR=".";


 opendir MYDIR, "$PSDIR" ;
 @FILES = grep !/^\.\.?/, readdir MYDIR ;
 close MYDIR ;
 @FILES = grep /vobs/, @FILES ;
 @FILES = sort @FILES  ;


 for ( $j = 0 ; $j < scalar(@FILES) ; $j++ ) {

   $TIMES[$j] = substr($FILES[$j],4,10) ;
   $FILES[$j] = $PSDIR."/".$FILES[$j] ;

 } ;

 $tmp = scalar(@TIMES) ;
 if ( $tmp == 0 )  { die "Found no vobs files, exit \n"; } ;

 print " TIMES FOUND : $tmp \n" ; 

#
# Define and scan through file
#
my @STATIONS ;
my @LATS ;
my @LONS ;
my @HEIGHTS ;

TIME : foreach $FILE ( @FILES ) {

   if ( ! -e $FILE ) { print " Could not find $FILE \n" ; next TIME } ;
   open FILE, "< $FILE" ;

   print " Scanning $FILE \n" ;

   $line =<FILE> ; chomp $line ; print "$line \n" ;
       @TMP=split (' ',$line) ;
@TMP = grep !/ /, @TMP ;
($nsynop,$ntemp) = @TMP ;
print " Found SYNOP $nsynop \n";
print " Found TEMP $ntemp \n";


   $line =<FILE> ; chomp $line ; print "Levels $line \n" ;
   $i=1 ;
   CLINE : while ( $i <= $nsynop) {
     @TMP=split (' ',<FILE>) ;
     $station = shift @TMP ;
     if ( $station == 0 ) { $i++ ; next CLINE ;} ;
     $lat     = shift @TMP ;
     $lon     = shift @TMP ;
     $height  = shift @TMP ;
     unless ( grep /$station/, @STATIONS ) { 
		@STATIONS = (@STATIONS,$station) ;
		@LATS = (@LATS,$lat) ;
		@LONS = (@LONS,$lon) ;
		@HEIGHTS = (@HEIGHTS,$height) ;
	 };
     $i++ ;
   };

   close FILE ;
};
   print "@STATIONS \n" ;
      $tmp = scalar(@STATIONS) ;
      print " STATIONS FOUND: $tmp \n" ;

#
# Make a list of what we found
#

 if ( scalar(@STATIONS) ) {
    open OFILE, "> found_list"  ;
    $i = 0;
    foreach ( @STATIONS ) { 
       print OFILE " $_ $LATS[$i] $LONS[$i] $HEIGHTS[$i] \n" ; 
       $i++ ;
    } ;
    close OFILE ;
 } ;

