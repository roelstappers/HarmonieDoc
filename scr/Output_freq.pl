#!/usr/bin/perl -w
use List::Util qw(first);

require($ENV{HM_LIB}.'/scr/utils.pm');


# Return list of valid output time steps according to
# the following HARMONIE environment variables.
#
# TSTEP        = time step [s]
# LL           = forecast length [h]
# TFLAG        = output time described based on hours or minutes
# HWRITUPTIMES = output for history files
# SWRITUPTIMES = output for surfex files
# SFXFULLTIMES = output for full surfex files
# PWRITUPTIMES = output for postprocessed files
# VERITIMES    = output for verification
#
# Usage:
#
# Output_freq.pl TEST         = Check that all environment variables are set correctly
# Output_freq.pl NHISTS       = builds namelist variable NHISTS
# Output_freq.pl NSHISTS      = builds namelist variable NSHISTS
# Output_freq.pl NPOSTS       = builds namelist variable NPOSTS
# Output_freq.pl VERILIST     = returns VERITIMES list for full hours ( hour | time steps )
# Output_freq.pl TDF_VERILIST = returns VERITIMES list for full hours for tdf file ( hour based )
# Output_freq.pl OUTLIST      = returns combined output list ( hour | time steps )
# Output_freq.pl TDF_OUTLIST  = returns combined output list for tdf file ( hour based )
# Output_freq.pl POSTLIST     = returns post-processing list ( hour | time steps )
# Output_freq.pl TDF_POSTLIST = returns post-processing list for tdf file ( hour based )
# Output_freq.pl SFXLIST      = returns surfex output list   ( hour | time steps )
# Output_freq.pl SFXFLIST     = returns surfex full output list   ( hour | time steps )
# Output_freq.pl PP N         = builds a list of valid output times 
#                               for individual Postpp call. N=hour. Returns ( hour | minutes )
# Output_freq.pl PP_TS N      = builds a list of valid output times 
#                               for individual Postpp call. N=hour. Returns ( hour | time steps )
# Output_freq.pl MG N         = builds a list of valid output times 
#                               for individual Makegrib call. N=hour. Returns ( hour | minutes )
# Output_freq.pl MG_TS N      = builds a list of valid output times 
#                               for individual Makegrib call. N=hour. Returns ( hour | time steps )
# Output_freq.pl VL N         = builds a list of valid verification times 
#                               for individual verification call. N=hour. Returns ( hour | minutes )
# Output_freq.pl VL_TS N      = builds a list of valid verification times 
#                               for individual verification call. N=hour. Returns ( hour | time steps )
#
# The routine prints out a list. If conditions can not be fullfilled the script returns blank
#  Explanation for N[XXX]TS:
#             1) if N[XXX]TS(0)=0 action if MOD(JSTEP,NFR[XXX])=0
#             2) if N[XXX]TS(0)>0 N[XXX]TS(0) significant numbers in
#                N[XXX]TS are then considered and:
#                action for JSTEP=N[XXX]TS(.)*NFR[XXX]
#             3) IF N[XXX]TS(0)<0
#                action for JSTEP=(N[XXX]TS(.)/DELTAT)*NFR[XXX]
#
# Method:
# The lists outlist, sfxlist, postlist and verilist are generated for the forecast scope and from the environment variables
# These list are processed for the user given options
#
# Return empty string if too few or many arguments
die("Error in number of arguments \n") if (( @ARGV == 0 ) || ( @ARGV > 2 ) );

$type="";
$time="";
$ll="";
@valid_arguments = ("TEST", "NHISTS", "NSHISTS", "NPOSTS","NRAZTS",
                    "VERILIST", "POSTLIST", "OUTLIST","SFXLIST","SFXFLIST",
                    "PP", "VL", "MG", "PP_TS", "VL_TS", "MG_TS",
                    "GUSTPERIOD",
                    "TDF_VERILIST","MIN_VERI_DIFF");

if ( @ARGV > 0 ) { 
  $type  = $ARGV[0];
  # Return empty string if invalid option

  unless ( grep /\b$type\b/, @valid_arguments ) {
   die("$type is not a valid argument\n Use any of:@valid_arguments\n") ;
  }   

}

if ( ($type eq "TDF_OUTLIST" ) || ($type eq "TDF_POSTLIST" ) || ($type eq "TDF_VERILIST" ) ) {
  if ( @ARGV > 1 ) { $ll = $ARGV[1] ; } else { die "\n" ; } ;
} else {
   die("Missing LL\n") unless ( $ENV{LL} );
   $ll = $ENV{LL} ;
   if ( @ARGV > 1 ) { $time = $ARGV[1]; }
} ;

# Check that necessary variables exist in environment
foreach $var ( qw/ TFLAG TSTEP LL FCINT
                   SIMULATION_TYPE
                   HWRITUPTIMES SWRITUPTIMES PWRITUPTIMES
                   SFXFULLTIMES
                   VERITIMES VERIFY 
                   FREQ_RESET_TEMP FREQ_RESET_GUST
                   / ) {
   if ( exists $ENV{$var} ) {
      $$var=$ENV{$var};
   } else {
      push @lackenv, $var;
   }
}

if ( @lackenv ) {
   print "The following environment variables are needed but missing:\n\t";
   print join("\n\t", @lackenv);
   die "\n$0 failed\n";
}

die("MOD(TSTEP,3600) is not zero\n") if ( 3600 % $ENV{TSTEP} != 0 );
die("TSTEP=$ENV{TSTEP} is negative\n") if ( $ENV{TSTEP} <= 0 );

# Settings for hourly based and minute (time-step) based output
if ( $ENV{TFLAG} eq "min" ) {
  $sign="";
  $fcll=$ENV{LL}*3600/$ENV{TSTEP};                 # LL in time steps
  $FCINT=$FCINT*3600/$ENV{TSTEP};                  # cycle interval in timesteps
  $fcll2=$ENV{LL}*60;                              # LL in minutes
} else {
  $sign="-";
  $fcll=$ll ;
  $fcll2=$ll ;
}
# Remove leading zeros
$fcll += 0;
$fcll2 += 0;

#
# CREATE LISTS BASED INDIVIDUALLY FROM HWRITUPTIMES, SWRITUPTIMES, PWRITUPTIMES and VERITIMES
# OR FROM REGULAR OUTPUT INTERVAL
#

#
# Define and print namelist variable NRAZTS
#
if ( $type eq "NRAZTS" ) {
  # Build NRAZTS based on the reset frequency
  $nrazts=$ENV{FREQ_RESET_TEMP} or $nrazts=6;
  if ( $ENV{TFLAG} eq "min" ) {
    $nrazts=$ENV{FREQ_RESET_TEMP}*60 or $nrazts=360;
    $nrazts=($nrazts*60)/$ENV{TSTEP};
  } 
  $nraztslist="";
  for ( $ii=0; $ii<=$fcll; $ii=$ii+$nrazts ) {
    # If TFLAG=min can only write full minutes 
    if ( $ENV{TFLAG} eq "min" ) {
      if ( ($ii * 60 ) % 60 == 0 ) {
        # remove leading zeros
        $ii += 0;
        $nraztslist="$nraztslist $ii";
      }
    } else {
      $nraztslist="$nraztslist $ii";
    }
  }
  @tmp=split(' ',$nraztslist);
  $size=@tmp;
  $nrazts="$sign"."$size".",";
  if ( @tmp > 0 ) {
    for ( $ii=0; $ii<$size-1; $ii++ ) { $nrazts=$nrazts.$sign.$tmp[$ii].","; }
    $nrazts=$nrazts.$sign.$tmp[$size-1];
  }
  print "$nrazts\n";
}

# Historic files
  # Create an uniqe list of times inside the forecast scope for historic files
  # histlist is based on HWRITUPTIMES 
  @histlist=split(':',&gen_list($ENV{HWRITUPTIMES}));
  $histlist=&arrange_list(@histlist) ;

# Surfex files
  # Create an uniqe list of surfex output times inside the forecast scope
  # SURFEX output list based on SWRITUPTIMES 

  @sfxlist=split(':',&gen_list($ENV{SWRITUPTIMES}));
  $sfxlist=&arrange_list(@sfxlist) ;

  # Make sure we write the last surfex file
  if ( $ENV{SIMULATION_TYPE} eq "climate" ) { $sfxlist=$sfxlist." ".$fcll ; }

# Surfex full files
  # Create an uniqe list of surfex output times inside the forecast scope
  # SURFEX output list based on SFXFULLTIMES 

  @sfxflist=split(':',&gen_list($ENV{SFXFULLTIMES}));
  $sfxflist=&arrange_list(@sfxflist) ;

  # Make sure we write the last surfex file
  if ( $ENV{SIMULATION_TYPE} eq "climate" ) { 
   $sfxflist=$sfxflist." ".$fcll ; 
  } else {
   $sfxflist=$sfxflist." ".($FCINT, $fcll)[$FCINT > $fcll] ;
  }

# Verification files
  # Create an uniqe list of verification times inside the forecast scope
  # verilist is based on VERITIMES 

  @verilist=split(':',&gen_list($ENV{VERITIMES}));
  $verilist=&arrange_list(@verilist) ;

# Post-processed files
  # Create an uniqe list of post-processing times inside the forecast scope
  # postlist is based on PWRITUPTIMES 

  @postlist=split(':',&gen_list($ENV{PWRITUPTIMES}));
  $postlist=&arrange_list((@verilist,@postlist)) ;

# Merging HWRITUPTIMES, PWRITUPTIMES to $outlist
# PWRITUPTIMES is only added if offline fullpos is used

if ( $ENV{TFLAG} eq "min" ) {
 $highest=$fcll2*60/$ENV{TSTEP};
} else {
 $highest=$fcll2;
}

@outlist=('histlist') ;
push(@outlist,'postlist') if ( $ENV{'POSTP'} eq "offline" ) ;

%fflist = () ;
for $list (@outlist) {
 foreach (split(' ',${$list})) {
  $fflist{$_} = 1 if ( $_ <= $highest ) ;
 } 
};

@outlist=();
for $key (  sort { $a <=> $b } keys %fflist ) {
 push(@outlist,$key) ;
} ;
$outlist=join(' ',@outlist);

###########################################################################################
###########################################################################################
#
#  HERE YOU CAN DEFINE NEW VARIABLES
#
###########################################################################################
###########################################################################################

#
# Define and print namelist variable GUSTPERIOD
#

if ( $type eq "GUSTPERIOD" ) {

  if ( $ENV{TFLAG} eq "min" ) { die "GUSTPERIOD not implemented for minutes \n"; }

  $gustlist=&arrange_list((@histlist,@postlist,@verilist)) ;
  @gustlist=split(' ',$gustlist);

  $i = first { $gustlist[$_] == $time } 0..$#gustlist;

  if ( $i == 0 ) {
   print "0\n" ;
  } else {
   $x = $gustlist[$i] - $gustlist[$i-1] ;
   $y = $ENV{FREQ_RESET_GUST} ;
   $i = ($x, $y)[$x < $y];
   print "$i\n";
  }
}

#
# Print OUTLIST. The list of hours (time steps if TFLAG=min) that should be written
#
if (( $type eq "OUTLIST" ) || ( $type eq "TDF_OUTLIST" ) ){

 if ( $type eq "OUTLIST" ) {

   print "$outlist\n";

 } elsif ( $type eq "TDF_OUTLIST" ) {
   # The tdf file needs whole hours that should processed.
   # Must loop all values and generate a list for hours if TFLAG=min 
   if ( $ENV{TFLAG} eq "min" ) {
     $last_written=-99;
     $tdf_outlist="";
     @tmp=split(' ',$outlist);
     for ( $ii=0; $ii<@tmp; $ii++ ){
       $ww=$tmp[$ii];
       # This corresponds to the following hour if exact hour
       if ( (( $ww * $ENV{TSTEP} ) % 3600 ) == 0 ) {
         $ww=int(( $ww * $ENV{TSTEP} ) / 3600. );
       # hour + 1 if not exact
       } else {
         $ww=int(( $ww * $ENV{TSTEP} ) / 3600. );
         $ww++;
       }
       # If this hour is not already processed, add it to tdf_outlist
       if ( $ww != $last_written ) { 
         $ww = $ww * 1 ;
         $tdf_outlist=$tdf_outlist. $ww." ";
         $last_written=$ww;
       }
     }
     print "$tdf_outlist\n";
   } else {
     print "$outlist\n";
   }
 }
}

#
# Print SFXLIST. The list of hours ( time steps if TFLAG=min) that should be written
#
if ( $type eq "SFXLIST" ) {
 print "$sfxlist\n";
}

#
# Print SFXFLIST. The list of hours ( time steps if TFLAG=min) that should be written
#
if ( $type eq "SFXFLIST" ) {
 print "$sfxflist\n";
}

#
# Print POSTLIST. The list of hours ( time steps if TFLAG=min) that should be post-processed
#
if (( $type eq "POSTLIST" ) || ( $type eq "TDF_POSTLIST" )) {
  if ( $type eq "POSTLIST" ) {
    print "$postlist\n";
  } elsif ( $type eq "TDF_POSTLIST" ) {
    # The tdf file needs whole hours that should be processed.
    # Must loop all values and generate a list for hours if TFLAG=min 
    if ( $ENV{TFLAG} eq "min" ) {
      $last_written=-99;
      $tdf_postlist="";
      @tmp=split(' ',$postlist);
      for ( $ii=0; $ii<@tmp; $ii++ ){
        $pp=$tmp[$ii];
        # This corresponds to the following hour if not exact hour
        if ( (( $pp * $ENV{TSTEP} ) % 3600 ) == 0 ) {
          $pp=int(( $pp * $ENV{TSTEP} ) / 3600. );
          # hour + 1 if not exact
        } else {
          $pp=int(( $pp * $ENV{TSTEP} ) / 3600. );
          $pp++;
        }
        # If this hour is not already processed, add it to tdf_outlist
        if ( $pp != $last_written ) {
          $pp = $pp * 1 ;
          $tdf_postlist=$tdf_postlist. $pp." ";
          $last_written=$pp;
        }
      }
      print "$tdf_postlist\n";
    } else {
      print "$postlist\n";
    }
  }
}

#
# Define and print namelist variable NHISTS
#
if ( $type eq "NHISTS" ) {
  @tmp=split(' ',$outlist);
  $size=@tmp;
  $nhists="$sign"."$size".",";
  if ( @tmp > 0 ) {
    for ( $ii=0; $ii<$size-1; $ii++ ) { $nhists=$nhists.$sign.$tmp[$ii].","; }
    $nhists=$nhists.$sign.$tmp[$size-1];
  }
  print "$nhists\n";
}

#
# Define and print namelist variable NPOSTS
#
if ( $type eq "NPOSTS" ) {
  @tmp=split(' ',$postlist);
  $size=@tmp;
  $nposts="$sign"."$size".",";
  if ( @tmp > 0 ) {
    for ( $ii=0; $ii<$size-1; $ii++ ) { $nposts=$nposts.$sign.$tmp[$ii].","; }
    $nposts=$nposts.$sign.$tmp[$size-1];
  }
  print "$nposts\n";
}


#
# Define and print namelist variable NSHISTS
#
if ( $type eq "NSHISTS" ) {
  @tmp = split(' ',$sfxlist);
  $size=@tmp;
  $nshists="$sign"."$size".",";
  if ( @tmp > 0 ) {
    for ( $ii=0; $ii<$size-1; $ii++ ) { $nshists=$nshists.$sign.$tmp[$ii].","; }
    $nshists=$nshists.$sign.$tmp[$size-1];
  }
  print "$nshists\n";
}

#
# Define hour based list VERITIMES
#
# If minute based output is requested then verification is
# done only on full hours. 
# TDF_VERILIST is at the moment same as 
# VERILIST but with output in hours.

if ( ( $type eq "VERILIST" ) || ( $type eq "TDF_VERILIST" ) || ( $type eq "MIN_VERI_DIFF" ) ){

  $min_veri_diff=999 ;
  $veritimes="";
  @tmp=split(' ',$verilist);
  if ( $ENV{TFLAG} eq "min" ) {
    $i=0 ;
    foreach ( @tmp ) {
      # Convert from time step to minute 
      $vv=$_*$ENV{TSTEP}/60;
      # Only if full hour do verification
      if ( ( $vv % 60 ) == 0  ) {
        if ( $type eq "VERILIST" ) {
          $vv_hour=$vv*60/$ENV{TSTEP};
        } elsif ( ( $type eq "TDF_VERILIST" ) || ( $type eq "MIN_VERI_DIFF" ) ) {
          $vv_hour=$vv*60/3600;
          if ( $i == 0 ) {
             $vv_hour_last = $vv_hour ;
          } else {
             $tmp = $vv_hour - $vv_hour_last ;
             if ( ($tmp) < $min_veri_diff ) { $min_veri_diff = $tmp } ;
             $vv_hour_last = $vv_hour ;
          } ;
        }
        $veritimes=$veritimes.$vv_hour." ";
      }
      $i++ ;
    }
  } else {
    $i=0 ;
    foreach ( @tmp ) { 
      $vv=$_;
      if ( $type eq "TDF_VERILIST" ) { $vv = $vv * 1 ; } ;
      $veritimes=$veritimes.$vv." ";
      if ( $i == 0 ) {
         $vv_hour_last = $_ ;
      } else {
         $tmp = $_ - $vv_hour_last ;
         if ( ($tmp) < $min_veri_diff ) { $min_veri_diff = $tmp } ;
         $vv_hour_last = $_ ;
      } ;
      $i++ ;
    }
  }
  if ( $type eq "MIN_VERI_DIFF"  ){
     print "$min_veri_diff\n";
  } else {
     print "$veritimes\n";
  }
}

#
# Define PP list containg all the times needed to be postprocessed
# between the time window N-1 - N h. Returning output hour or number of time steps if TFLAG=min
#

if ( ( $type eq "PP" ) || ( $type eq "PP_TS") ) {

  if ( $time ne "" ){
    @pplist=split(' ',$postlist);
    if ( $ENV{TFLAG} eq "min" ) {
      foreach ( @pplist ) { $_=$_*$ENV{TSTEP}/60; }
      $pp_start=($time-1)*60; 
      $pp_end=($time)*60;
    } else {
      $pp_start=($time-1); 
      $pp_end=$time;
    }
    $pp="";
    foreach ( @pplist ) { 
      $p=$_;
      if ( $p > $pp_start && $p <= $pp_end ) {
        # If minutely output, check what the user wants back
        if ( $ENV{TFLAG} eq "min" ) {
          if ( $type eq "PP_TS" ) {
            $p=$p*60/$ENV{TSTEP};
            $pp=$pp.$p." ";
          } elsif ( $type eq "PP" ) {
            $pp=$pp.$p." ";
          } else {
            $pp="";
          }
        # Hourly output is always hour
        }else{
          $pp=$pp.$p." ";
        }
      }
    }
    print "$pp\n";

  } else {
    print "\n";
  }
}

#
# Define MG list containg all the times between the time window N-1 - N h
# where grib conversion is needed. 
# MG_TS: Returning output hour or number of time steps if TFLAG=min
#    MG: Returning output hour or minutes if TFLAG=min
#

if (( $type eq "MG" ) || ( $type eq "MG_TS" )) {

  if ( $time ne "" ) {

    @mglist = split(' ',$outlist);
    if ( $ENV{TFLAG} eq "min" ) { 
      # mglist from t-step to min
      foreach ( @mglist ) { $_=$_*$ENV{TSTEP}/60; }
      $mg_start=($time - 1 )*60; 
      $mg_end=($time)*60;
    } else {
      $mg_start=($time - 1); 
      $mg_end=$time;
    }
    $mg="";
    foreach ( @mglist ) { 
      $m=$_;
      if ( $m > $mg_start && $m <= $mg_end ) {
        # If minutely output, check what the user wants back
        if ( $ENV{TFLAG} eq "min" ) {
          if ( $type eq "MG_TS" ) {
            $m=$m*60/$ENV{TSTEP};
            $mg=$mg.$m." ";
          } elsif ( $type eq "MG" ) {
            $mg=$mg.$m." ";
          } else {
            $mg="";
          }
        # Hourly output is always hour
        }else{
          $mg=$mg.$m." ";
        }
      }
    }
    print "$mg\n";

  } else { 
    print "\n";
  }
}

#
# Define VL list containg all the times between the time window N-1 - N h
# where verification can be done is needed. 
# VL_TS: Returning output hour or number of time steps if TFLAG=min
#    VL: Returning output hour or minutes if TFLAG=min
#

if (( $type eq "VL" ) || ( $type eq "VL_TS" )) {

  if ( $time ne "" ) {

    @vvlist = split(' ',$verilist);
    if ( $ENV{TFLAG} eq "min" ) {
      # vvlist from t-step to min
      foreach ( @vvlist ) { $_=$_*$ENV{TSTEP}/60; }
      $vv_start=($time - 1 )*60;
      $vv_end=($time)*60;
    } else {
      $vv_start=($time - 1);
      $vv_end=$time;
    }
    $vv="";
    foreach ( @vvlist ) {
      $v=$_;
      if ( $v > $vv_start && $v <= $vv_end ) {
        # If minutely output, check what the user wants back
        if ( $ENV{TFLAG} eq "min" ) {
          if ( $type eq "VL_TS" ) {
            if ( ( $v % 60 ) == 0  ) {
              $v=$v*60/$ENV{TSTEP};
              $vv=$vv.$v." ";
            }
          } elsif ( $type eq "VL" ) {
            if ( ( $v % 60 ) == 0  ) { $vv=$vv.$v." "; }
          } else {
            $vv="";
          }
        # Hourly output is always hour
        }else{
          $vv=$vv.$v." ";
        }
      }
    }
    print "$vv\n";

  } else {
    print "\n";
  }
}

sub arrange_list(){

 my @list = @_ ;
 my %fflist = () ;
 my $vv ;	

  foreach $vv (@list) {
   if ( $ENV{TFLAG} eq "min" ) {
    # Only write output for whole minutes
    if ( ($vv*60) % $ENV{TSTEP} == 0 ) {
      $vv=$vv*60/$ENV{TSTEP};
    }
   }
   $vv+=0;
   $fflist{$vv} = 1 if ( $vv <= $fcll ) ;
  };

  @list=();
  for my $key ( sort { $a <=> $b } keys %fflist ) {
   push(@list,$key) ;
  } ;

  return join(' ',@list);

}

1;
