%axis =(

 # Range on the Y axis for different variables
  
 # gp or sp variables
 PRE_PREHYD =>   { ymin => 1.e-6, ymax => 1.e-4, },
 PREHYDS =>      { ymin => 0.,    ymax => 5.e3,  },
 SRC =>          { ymin => 1.e-6, ymax => 1.e-5, },
 TEMP =>         { ymin => 250.,  ymax => 270.,  },
 TKE =>          { ymin => 0.,    ymax => 5.e-1, },
 D4 =>           { ymin => 1.e-6, ymax => 1.e-3, },
 DIV =>          { ymin => 1.e-6, ymax => 1.e-3, },
 VOR =>          { ymin => 1.e-7, ymax => 2.e-4, },
 CLOUD_FRACTI => { ymin => 0.,    ymax => 0.5,   },
 KE =>           { ymin => 0.,    ymax => 5.e2,  },
 GRAUPEL =>      { ymin => 1.e-9, ymax => 2.e-5, },
 RAIN =>         { ymin => 1.e-9, ymax => 2.e-5, },
 SNOW =>         { ymin => 1.e-9, ymax => 2.e-5, },
 SOLID_WATER =>  { ymin => 1.e-9, ymax => 2.e-5, },
 LIQUID_WATER => { ymin => 1.e-9, ymax => 5.e-5, },
 HUMI_SPECIFI => { ymin => 1.e-3, ymax => 5.e-3, },

 CPU => { lw => 1, unit => 'seconds', },
 costfun => { xlabel => "Iterations", unit => "Cost" , xscale => 1,},
 JO  => { xlabel => "Iterations", xscale => 1,},
 JB  => { xlabel => "Iterations", xscale => 1,},
 JC  => { xlabel => "Iterations", xscale => 1,},
 JT  => { xlabel => "Iterations", xscale => 1,},

 HU2m         => { title =>"Relative humidity 2m increments",           unit => "%",       },
 T2m          => { title =>"Temperature 2m increments",                 unit => "K",       },
 T2m_TOWN     => { title =>"Temperature 2m (town) increments",          unit => "K",       },
 LST_WATER    => { title =>"Lake surface temperature increments",       unit => "K",       },
 SST_SEA      => { title =>"Sea surface temperature increments",        unit => "K",       },
 TS_NATURE    => { title =>"Surface temperature (nature) increments",   unit => "K",       },
 TP_NATURE    => { title =>"Deep soil temperature (nature) increments", unit => "K",       },
 T_ROAD3_TOWN => { title =>"Road temperature (town) increments",        unit => "K",       },
 WS_NATURE    => { title =>"Surface soil water increments",             unit => "m3/m3",   },
 WP_NATURE    => { title =>"Root soil water increments",                unit => "m3/m3",   },
 TL_NATURE    => { title =>"Root frozen soil water increments",         unit => "m3/m3",   },
 SN_NATURE    => { title =>"Snow water equvivalent increments",         unit => "kg/m2",   },

);

sub plot_norm {
 #
 # Create gnuplot file and png plots
 #

 $infile = shift @_ ;
 $dtg    = shift @_ ;

 print "INFILE $infile \n";

 open INFILE, "<$infile" or print "WARNING:Could not find $infile \n";

 @labels = split(' ',<INFILE>);
 shift @labels ;

 $j = 1 ;
 foreach $label (@labels) {

   $j++ ;

   $fileout = "${label}_$dtg";
  
   open GP, ">$fileout.gp";

   # Type dependend settings
   if ( exists($axis{$label}{ymin}) ) {
      $yrange="set yrange[$axis{$label}{ymin}:$axis{$label}{ymax}]" 
   } else {
     $yrange="";
   } ;

   if ( exists($axis{$label}{unit}) ) {
     $ylabel="$axis{$label}{unit}" 
   } else {
     $ylabel="" ;
   } ;

   if ( exists($axis{$label}{xlabel}) ) {
      $xlabel="$axis{$label}{xlabel}" 
   } else {
     $xlabel="Hours from $dtg" ;
   } ;

   $xscale=$axis{$label}{xscale} or $xscale = 3600;
   $lw=$axis{$label}{lw} or $lw=4;

   print GP <<EOF;
    set terminal png
    set output '$fileout.png'
    set title "$label"
    set xlabel "$xlabel" ;
    set ylabel "$ylabel";
    $yrange
    set grid
    plot \\
EOF

   $add="";
   for ( $n=0 ; $n <= $nsearch ; $n++ ) {
     if ( $nsearch > 0 ) {
      $i = -$fcint * $n ;
      $sdtg =`mandtg $dtg + $i`; chop $sdtg;
      $tshift = $fcint * $n * 3600 ;
      $file="${type}_$sdtg.dat" ;
     } else {
      $file=$infile ;
      $sdtg = $dtg ;
      $tshift = 0 ;
     } ;

     $add ="," if $n > 0 ;
     if ( -s $file) { $add ="," if $n > 0 ; print GP "$add '$file' using (\$1-$tshift)/$xscale:$j title  '$sdtg' with lines lt $n+1 lw $lw"; }

   };

   print "Plot $fileout.png\n";
   system("gnuplot $fileout.gp") ;

 } ;

} ;

sub plot_cost {
 #
 # Create gnuplot file and png plots
 #

 $infile = shift @_ ;
 $dtg    = shift @_ ;

 print "INFILE $infile \n";

 open INFILE, "<$infile" or print "WARNING:Could not find $infile \n";

 @labels = split(' ',<INFILE>);
 shift @labels ;

 $fileout = "costfun_$dtg";
  
 open GP, ">$fileout.gp";

 # Type dependend settings
 if ( exists($axis{$type}{ymin}) ) {
   $yrange="set yrange[$axis{$type}{ymin}:$axis{$type}{ymax}]" ;
 } else {
   $yrange="";
 } ;

 if ( exists($axis{$type}{unit}) ) {
   $ylabel="$axis{$type}{unit}" ;
 } else {
   $ylabel="" ;
 } ;

 if ( exists($axis{$type}{xlabel}) ) {
    $xlabel="$axis{$type}{xlabel}"  ;
 } else {
   $xlabel="Hours from $dtg" ;
 } ;

 $xscale=$axis{$type}{xscale} or $xscale = 3600;
 $lw=$axis{$type}{lw} or $lw=4;

 print GP <<EOF;
  set terminal png
  set output '$fileout.png'
  set title "Cost functions"
  set xlabel "$xlabel" ;
  set ylabel "$ylabel";
  $yrange
  set grid
  plot \\
EOF

 $j = 1 ;
 $tshift = 0 ;
 $add ="" ;
 foreach $label (@labels) {
   $j++ ;
   if ( $costlabels =~ /$label/ ) {
     print GP "$add '$infile' using (\$1-$tshift)/$xscale:$j title  '$label' with lines lt $j lw $lw"; 
     $add ="," ;
   }; 
 };

 print "Plot $fileout.png\n";
 system("gnuplot $fileout.gp") ;

} ;

sub print_norm () {

  $filename = shift @_ ;
  $norm     = shift @_ ;

  print "$filename $norm\n";

  my $writeme = 1;
  @times = ();


  for $time ( keys %{$norm} ) {
       @times = (@times,$time);
  }

  @times = sort { $a <=> $b } @times;

  open OUTFILE,"> $filename ";
  print "Writing to $filename\n";

  for $key ( @times ) {

    if ( $writeme ) {

      # Write the header 
      # Remove . from labels, causes problem when plotting

      @A = ();
      for $role ( sort keys %{ ${$norm}{$key} } ) {
        @A = (@A,$role) ;
      } ;
      $txt = join(' ',@A);
      $txt =~ s/\./_/g;
      print OUTFILE "# $txt\n";
      $writeme = 0 ;
    } ;

    @B = ($key) ;
     for $role ( @A ) {
      @B = (@B,${$norm}{$key}{$role}) ;
    } ;

    $txt = join(' ',@B);
    print OUTFILE "$txt\n";

  };

  close OUTFILE ;

} ;

###############################
###############################
###############################

sub time_plot {

 #
 # Create gnuplot file and png plots
 #

 $type = shift @_ ;
 $sdtg = shift @_ ;
 $dtg  = shift @_ ;

 print "$type $sdtg $dtg \n";

 # Concatenate files
 while ( $sdtg <= $dtg ) {
   $infile="${type}_$sdtg.dat" ;
   if ( open INFILE, "<$infile" ) {
      @labels = split(' ',<INFILE>);
      $times{$sdtg} = <INFILE> ;
      print "read $sdtg \n" ;
      close INFILE ;
   } ;
   $sdtg =`mandtg $sdtg + $fcint` or die "ERROR\n"; chop $sdtg;
 } ;

 # Print the temporary file
 $fileout = "foo" ;
 open FILEOUT, ">foo" ;
 for $sdtg ( sort keys %times ) {
  $ymd = substr( $sdtg, 0, 8 ) ;
  $h   = substr( $sdtg, 8, 2 ) ;
  $times{$sdtg} =~ s/^0 /$ymd $h / ;
  print FILEOUT "$times{$sdtg}" ;
 } ; 

 shift @labels ;
 $ym = substr( $sdtg, 0, 6 ) ;

 $j = 2 ;
 foreach $label (@labels) {

   $j++ ;

   $fileout = "${label}_${ym}";
  
   open GP, ">$fileout.gp";

   $xlabel="Date\\nTime" ;
   $title="$axis{$label}{title}" or $title=$label ;

   print GP <<EOF;
    set terminal png
    set output '$fileout.png'
    set title "$title for $ym"
    set ylabel "$axis{$label}{unit}"
    set xlabel"$xlabel" 
    set timefmt "%Y%m%d %H"
    set xdata time
    set format x "%d/%m \\n %H:00"
    set grid
    plot 'foo' using 1:$j notitle with lines lw 5
EOF

   print "Plot $fileout.png\n";
   system("gnuplot $fileout.gp") ;

 } ;


} ;

1; 
