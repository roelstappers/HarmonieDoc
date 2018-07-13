#!/usr/bin/perl

foreach $file (@ARGV) {

   $total = 0;
   ($dum,$type,$dtg) = split('_',$file) ;
   $dtg =substr($dtg,0,10);

   open FILE,"<$file" or die "Could not read $file \n";

   while (<FILE>) {
      chomp ;
      if ( /INFO SBU\s+: ([\d\.]+)/ ) {
	 $total += $1;
      }
   }

   close FILE;
   printf "Total SBU for %15s %d: %9.3f\n", $type, $dtg, $total;

}
