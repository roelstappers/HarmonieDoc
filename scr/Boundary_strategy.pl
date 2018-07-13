#!/usr/bin/perl 
#
# Find best fitted boundaries in BDPATH
#
# Ulf Andrae, SMHI 2008
#
# Strategies defined are:
#
# available    : Search for available files in BDDIR, try to keep forecast consistency
#                This is meant to be used operationally
# same_forecast: Use all boundaries from the same forecast, start from analysis
# enda         : Same as same_forecast but for ECMWF ENDA data 
#                06 and 18 UTC: same cycle
#                00 and 12 UTC: 6h earlier ENDA data 
# eps_ec       : Like enda but from the GLAMEPS archive of ECMWF ENS data
# eps_ec_oper  : Like enda but from ECMWF operational ENS runs
# analysis_only: Use only analysises as boundaries
# latest       : Use the latest possible boundary with the shortest forecast length
# RCR_operational : Mimic the behaviour of the RCR runs, ie
#                   12h old boundaries at 00 and 12 and
#                   06h old boundaries at 06 and 18
# simulate_operational :  Mimic the behaviour of the operational runs using ECMWF LBC, ie, 6 hour old boundary.
#
# The output bdstrategy file has the format of 
# NNN|YYYYMMDDHH INT_BDFILE BDFILE BDFILE_REQUEST_METHOD
#
# Where 
# NNN        is the input hour
# YYYYMMDDHH is the valid hour for this boundary
# INT_BDFILE is the final boundary file
# BDFILE     is the input boundary file
# BDFILE_REQUEST_METHOD is the method to the request BDFILE from e.g. MARS, ECFS or via scp
#
# Extended usage
# EXT_BDDIR and EXT_ACCESS can be defined by user
# If we in sms/config_exp.h define and export e.g.
# EXT_BDDIR=smhi:/data/ariv/E11/@YYYY@/@MM@/@DD@/@HH@/E11_@YYYY@@MM@@DD@@HH@00+0@LLL@H00M
# with optional EXT_BDFILE=SOME_FILENAME
# EXT_ACCESS=scp
# We would expect to make an scp of EXT_BDDIR/EXT_BDFILE to BDDIR
# 
# Rules for name convention and access is defined in %rules below.
#
# Alternatively nameing can be given in sms/config_exp.h via BDDIR
# ("+" must be included) e.g.
# BDDIR=/hirlam/RCRa/@YYYY@/@MM@/@DD@/@HH@/fc@YYYY@@MM@@DD@@HH@00+@LLL@md
# With filenames without the "+" you must define and export BDFILE in sms/config_exp.h
#
# Defined rules depending on HOST_MODEL

require($ENV{HM_LIB}.'/scr/utils.pm');
require($ENV{HM_LIB}.'/msms/harmonie.pm');


 %rules = (
   'hir' => {
      INT_SINI_FILE =>$ENV{WRK}.'/SURFXINI.'.$ENV{SURFEX_OUTPUT_FORMAT},
      INT_BDFILE =>$ENV{WRK}.'/ELSCF'.$ENV{CNMEXP}.'ALBC@NNN@',
      FC => 'fc@YYYY@@MM@@DD@_@HH@+@LLL@',
      AN => 'an@YYYY@@MM@@DD@_@HH@+@LLL@',
      EXT_ACCESS => 'Access_lpfs -from',
      EXT_BDDIR =>'ec:/hirlam/'.$ENV{BDLIB}.'/@YYYY@/@MM@/@DD@/@HH@',
      FC_SFX    => 'fc@YYYY@@MM@@DD@_@HH@+@LLL@',
      AN_SFX    => 'an@YYYY@@MM@@DD@_@HH@+@LLL@',
   },
   'ifs' => {
      INT_SINI_FILE =>$ENV{WRK}.'/SURFXINI.'.$ENV{SURFEX_OUTPUT_FORMAT},
      INT_BDFILE =>$ENV{WRK}.'/ELSCF'.$ENV{CNMEXP}.'ALBC@NNN@',
      FC => 'fc@YYYY@@MM@@DD@_@HH@+@LLL@',
      AN => 'fc@YYYY@@MM@@DD@_@HH@+@LLL@',
      EXT_ACCESS => 'MARS_umbrella',
      EXT_BDDIR =>'',
      FC_SFX    =>  'fc@YYYY@@MM@@DD@_@HH@+@LLL@',
      AN_SFX    => 'fc@YYYY@@MM@@DD@_@HH@+@LLL@',
   },
   'ald' => {
      INT_SINI_FILE =>$ENV{WRK}.'/SURFXINI.'.$ENV{SURFEX_OUTPUT_FORMAT},
      INT_BDFILE =>$ENV{WRK}.'/ELSCF'.$ENV{CNMEXP}.'ALBC@NNN@',
      FC => 'ICMSH'.$ENV{CNMEXP}.'+0@LLL@',
      AN => 'ANAB1999+0@LLL@',
      EXT_ACCESS => 'Access_lpfs -from',
      EXT_BDDIR => $ENV{ECFSLOC}.':/'.$ENV{USER}.'/harmonie/'.$ENV{BDLIB}.'/@YYYY@/@MM@/@DD@/@HH@',
   },
 ) ;

 # For EC EPS use GLAMEPS ECFS archive
 if ( $ENV{BDSTRATEGY} eq "eps_ec" ) { $rules{'ifs'}{'EXT_ACCESS'}='ECFS_getbd_mbr'; }


# Set if the initial value input file for surfex should come from surfex or not
if ( $ENV{HOST_SURFEX} eq "yes" ) {
  if ( $ENV{SURFEX_INPUT_FORMAT} eq "lfi" ) {
    $rules{'ald'}{'FC_SFX'}='AROMOUT_.0@LLL@.lfi';
    $rules{'ald'}{'AN_SFX'}='PREP.lfi';
  }else{
  if ( $ENV{SURFEX_LSELECT} eq "yes" ) {
    $rules{'ald'}{'FC_SFX'}='ICMSHFULL+0@LLL@.sfx';
  }else{
    $rules{'ald'}{'FC_SFX'}='ICMSH'.$ENV{CNMEXP}.'+0@LLL@.sfx';
  }
    $rules{'ald'}{'AN_SFX'}='ICMSH'.$ENV{CNMEXP}.'INIT.sfx';
  }
}else{
  $rules{'ald'}{'FC_SFX'}=$rules{'ald'}{'FC'};
  $rules{'ald'}{'AN_SFX'}=$rules{'ald'}{'AN'};
}
# Let the rules for alaro and arome be the same as for aladin
$rules{'ala'} = $rules{'ald'} ;
$rules{'aro'} = $rules{'ald'} ;



# Copy environment information

$dtg        = $ENV{DTG} or die "DTG not set, unable to continue \n";;
$hh         = $dtg % 100 ;
$ll         = $ENV{LL} ; 

if ( $ENV{LLSHIFT} ) { 
  $llshift = $ENV{LLSHIFT};
} else {
  $llshift = -1 ;
} ;
 
$strategy   = $ENV{BDSTRATEGY};
$bdint      = $ENV{BDINT};
$host_model = $ENV{HOST_MODEL};
$bdcycle    = &get_bdcycle ;
$ensmbr     = $ENV{ENSMBR};
$ensbdmbr   = &Env('ENSBDMBR',$ensmbr);
if ( $ensbdmbr eq '' and $ensmbr >= 0 ) { 
  $ensbdmbr = $ensmbr ;
} elsif ( $ensbdmbr eq '' || $ensmbr < 0 ) { 
  $ensbdmbr = -1 ;
}

if ( $ENV{ENS_BD_CLUSTER} eq 'yes' ) {
  # Get the representative member from the cluster
  $repm = $ensbdmbr ; 
  open FILE, "< $ENV{WRK}/../cluster.txt" or die "Could not open the cluster file\n";
  while ( <FILE> ) {
    @tmp = split(" ",$_);
    $clust = $tmp[1] ;
    if ( $clust eq $ensbdmbr ) { $repm = $tmp[5] ; }
  }
  $ensbdmbr = $repm ;
}

if ( ( $strategy eq 'eps_ec'  or $strategy eq 'enda' ) && $host_model ne 'ifs') { die "$strategy only meaningful for HOST_MODEL=ifs\n"; } ;

$do_search=0;

print " Boundary strategy\n" ;
print "\n";
print "       DTG: $dtg\n";
print "        LL: $ll\n";
if ( $ENV{LLSHIFT} ) { print "   LLSHIFT: $llshift\n"; } ;
print "     BDINT: $bdint\n";
print "   BDCYCLE: $bdcycle\n";
print "BDSTRATEGY: $strategy\n";
print "     BDDIR: $ENV{BDDIR}\n";
print "    ENSMBR: $ensmbr\n";
print "  ENSBDMBR: $ensbdmbr\n";
if ( $ENV{BDFILE}     ) { 
     $rules{$host_model}{BDFILE}     = $ENV{BDFILE}      ; 
     print "    BDFILE: $ENV{BDFILE}\n";
} ;
print "HOST_MODEL: $ENV{HOST_MODEL}\n";

$rules{$host_model}{BDDIR} = $ENV{BDDIR} ;

# Pick up environment driven rules
$ext_access_changed = 0 ;
if ( $ENV{INT_BDFILE} ) {
   $rules{$host_model}{INT_BDFILE} = $ENV{INT_BDFILE}  ; 
   print "INT_BDFILE: $rules{$host_model}{INT_BDFILE}\n";
} ;
if ( $ENV{EXT_BDDIR}  ) {
   $rules{$host_model}{EXT_BDDIR}  = $ENV{EXT_BDDIR}   ;
   print " EXT_BDDIR: $rules{$host_model}{EXT_BDDIR}\n";
} ;
if ( $ENV{EXT_BDFILE} ) {
   $rules{$host_model}{EXT_BDFILE} = $ENV{EXT_BDFILE}  ;
   print "EXT_BDFILE: $rules{$host_model}{EXT_BDFILE}\n";
} ;
if ( $ENV{EXT_ACCESS} ) {
    $rules{$host_model}{EXT_ACCESS} = $ENV{EXT_ACCESS} ; $ext_access_changed = 1 ;
    print "EXT_ACCESS: $rules{$host_model}{EXT_ACCESS}\n";
 } ;

# Create a list of expected boundaries

if ( $ENV{'SURFACE'} eq "surfex" ) {
  $write_surf_ini = 1 ;
}else{
  $write_surf_ini = 0 ;
}
$first_dtg = 0;
if ( ( $strategy eq 'enda' )
     && $dtg >= 2010010100 ) { 
   if ( $hh == 0 || $hh == 12 ) { 
     $hh_offset = 6;
   } else { 
     $hh_offset = 0;
   } ;
} elsif ( $strategy eq 'eps_ec' ) { 
## For EC-EPS at 00/06/12/18:
   if ( $hh >= 0 && $hh < 6 ) {
     $hh_offset = 12 + $hh;
   } elsif ( $hh >= 6 && $hh < 18 ) {
     $hh_offset = $hh;
   } elsif ( $hh >= 18 && $hh < 24 ) {
     $hh_offset = $hh - 12;
   } ;
} else {
   $hh_offset = $hh % $bdcycle;
}

print " HH_OFFSET: $hh_offset\n";

print "\n# The output bdstrategy file has the format of \n";
print "# NNN|YYYYMMDDHH INT_BDFILE BDFILE BDFILE_REQUEST_METHOD \n";
print "# where \n";
print "# NNN        is the input hour\n";
print "# YYYYMMDDHH is the valid hour for this boundary\n";
print "# INT_BDFILE is the final boundary file\n";
print "# BDFILE                is the input boundary file\n";
print "# BDFILE_REQUEST_METHOD is the method to the request BDFILE from e.g. MARS, ECFS or via scp\n\n";


for ($i=0; $i <= $ll + $bdint - 1; $i += $bdint) {

  $nsearch = 0;
  $forward_search = 1;
  $found_file_bd  = 0;
  $found_file_sfx = 0;

  SEARCH : while ( $found_file_bd == 0 && $found_file_sfx == 0 ) { 

    $int_bdfile = $rules{$host_model}{INT_BDFILE} ;
    $bdpath     = $rules{$host_model}{BDDIR} ;
    $ext_bdpath = $rules{$host_model}{EXT_BDDIR} ;
    if ( $write_surf_ini ) {
      $int_sini_file  = $rules{$host_model}{INT_SINI_FILE} ;
      $bdpath_sfx     = $rules{$host_model}{BDDIR} ;
      $ext_bdpath_sfx = $rules{$host_model}{EXT_BDDIR} ;
    }
    SWITCH: {

    if ( $strategy eq 'available' ) { 
       if ( $i == 0 && $nsearch == 0 ) {
          $ii   = $hh_offset ;
          $mdtg =`mandtg $dtg + -$hh_offset`; chop $mdtg;
          $ldtg = $mdtg ;
       } else {
          if ( $nsearch == 0 ) {
             $ii = $ii + $bdint ;
          } else {
             $vdtg =`mandtg $dtg + $i`; chop $vdtg;

             if ( $forward_search ) {
              $mdtg =`mandtg $mdtg + $bdcycle`; chop $mdtg;
              $ii   =`mandtg $vdtg - $mdtg`; chop $ii;
              if ( $ii < 0 ) { 
               $mdtg = $ldtg ;
               $forward_search = 0 ;
              }
             } ;

             unless ( $forward_search ) {
              $mdtg =`mandtg $mdtg + -$bdcycle`; chop $mdtg;
              $ii   =`mandtg $vdtg - $mdtg`; chop $ii;
             } ;
          } ;
       } ;
       $do_search=1;
       last SWITCH;
    }

    if ( $strategy eq 'latest') { 
       $vdtg =`mandtg $dtg + $i`; chop $vdtg;
       $ii   = substr($vdtg,8,2) % $bdcycle ;
       $mdtg =`mandtg $vdtg + -$ii`; chop $mdtg; 
       last SWITCH;
    }

    if ( $strategy eq 'same_forecast' || $strategy eq 'enda' || $strategy eq 'eps_ec' ) { 
       $ii=$i + $hh_offset;
       if ( $first_dtg == 0 ) { $mdtg=`mandtg $dtg + -$hh_offset`; chop $mdtg; $first_dtg=$mdtg} ;
       $mdtg=$first_dtg;
       last SWITCH;
    }

    if ( $strategy eq 'analysis_only' || $strategy eq 'era' ) { 
       $ii   = 0;
       $n    = int ($i/$bdcycle) * $bdcycle - $hh_offset ;
       $mdtg = $dtg;
       $mdtg=`mandtg $mdtg + $n`; chop $mdtg; 
       last SWITCH;
    }

    if ( $strategy eq 'simulate_operational' || $strategy eq 'eps_ec_oper') { 
       if ( $first_dtg == 0 ) { 
          $hh_offset = $bdcycle + $hh_offset ;
          $mdtg=`mandtg $dtg + -$hh_offset`; chop $mdtg; $first_dtg=$mdtg ;
       } ;
       $mdtg=$first_dtg;
       $ii=$i + $hh_offset ;
       last SWITCH;
    }

    if ( $strategy eq 'RCR_operational') { 
       if ( $first_dtg == 0 ) { 
          if ( $hh_offset == 0 ) { $hh_offset = $bdcycle ;} else { $hh_offset = 06 } ;
          $mdtg=`mandtg $dtg + -$hh_offset`; chop $mdtg; $first_dtg=$mdtg ;
       } ;
       $mdtg=$first_dtg;
       $ii=$i + $hh_offset ;
       last SWITCH;
    }

    die "No such strategy implemented : $strategy \n";

    }

    if ( ( $strategy eq 'analysis_only' || $strategy eq 'era' ) && $bdint < $bdcycle ) { 
      die "ERROR: BDCYCLE($bdcycle) must not be greater than BDINT($bdint) \n\n"; 
    } ;

    
    # Sanity check
    $vdtg=`mandtg $dtg + $i`; chop $vdtg;
    $vvdtg=`mandtg $mdtg + $ii`; chop $vvdtg;
    unless ( $vvdtg == $vdtg ) { die "Stupid programmer $vvdtg != $vdtg \n"; } ;

    %keywords=(
      '@YYYY@' => substr($mdtg,0,4),
      '@MM@'   => substr($mdtg,4,2),
      '@DD@'   => substr($mdtg,6,2),
      '@HH@'   => substr($mdtg,8,2),
      '@LLLL@'  => $ii,
      '@LLL@'  => $ii,
      '@LL@'   => $ii,
      '@NNN@'  => $i / $bdint,
      '@MBR@'  => sprintf('%03d',$ensbdmbr),
    );

    %org_keywords=(
      '@YYYY@' => substr($dtg,0,4),
      '@MM@'   => substr($dtg,4,2),
      '@DD@'   => substr($dtg,6,2),
      '@HH@'   => substr($dtg,8,2),
      '@LLLL@'  => $ii,
      '@LLL@'  => $ii,
      '@LL@'   => $ii,
      '@NNN@'  => $i / $bdint,
      '@MBR@'  => sprintf('%03d',$ensbdmbr),
    );

    # Add file name to bdpath 
    if ( exists ( $rules{$host_model}{BDFILE} ) ) {
         $bdpath    = $bdpath.'/'.$rules{$host_model}{BDFILE}; 
         $bdpath_an = $bdpath.'/'.$rules{$host_model}{BDFILE}; 
    } else {
     unless ( $bdpath =~ /\+/ ) {
      if ( $ii == 0 ) { 
         $bdpath    = $bdpath.'/'.$rules{$host_model}{FC}; 
         $bdpath_an = $bdpath.'/'.$rules{$host_model}{AN}; 
      } else {
         $bdpath    = $bdpath.'/'.$rules{$host_model}{FC}; 
      } ;
     } ;
    };

    if ( $write_surf_ini ) {
      if ( $ENV{BDPATH_SFX} ) {
        $bdpath_sfx    = $ENV{BDPATH_SFX};
      } elsif ( exists ( $rules{$host_model}{BDFILE} ) ) {
        $bdpath_sfx    = $bdpath_sfx.'/'.$rules{$host_model}{BDFILE};
        $bdpath_an_sfx = $bdpath_sfx.'/'.$rules{$host_model}{BDFILE};
      } else {
        unless ( $bdpath_sfx =~ /\+/ ) {
          if ( $ii == 0 ) {
            $bdpath_sfx    = $bdpath_sfx.'/'.$rules{$host_model}{FC_SFX};
            $bdpath_an_sfx = $bdpath_sfx.'/'.$rules{$host_model}{AN_SFX};
          } else {
            $bdpath_sfx    = $bdpath_sfx.'/'.$rules{$host_model}{FC_SFX};
          } ;
        } ;
      };
    }

    # Add file name to ext_bdpath
    if ( $ext_bdpath ) {
      if ( exists ( $rules{$host_model}{EXT_BDFILE} ) ) {

         if ( $ii == 0 ) { 
           $ext_bdpath = $ext_bdpath.'/'.$rules{$host_model}{EXT_BDFILE}; 
         } else {
           $ext_bdpath = $ext_bdpath.'/'.$rules{$host_model}{EXT_BDFILE};
         } ;

      } else {

         unless ( $ext_bdpath =~ /\+/ ) {
           if ( $ii == 0 ) {
             $ext_bdpath = $ext_bdpath.'/'.$rules{$host_model}{AN}; 
           } else {
             $ext_bdpath = $ext_bdpath.'/'.$rules{$host_model}{FC}; 
           } ;
         } ;

     } ;
    } ;

    if ( $write_surf_ini ) {
      if ( $ext_bdpath_sfx ) {
        if ( exists ( $rules{$host_model}{EXT_BDFILE_SFX} ) ) {
          if ( $ii == 0 ) {
            $ext_bdpath_sfx = $ext_bdpath_sfx.'/'.$rules{$host_model}{EXT_BDFILE};
          } else {
            $ext_bdpath_sfx = $ext_bdpath_sfx.'/'.$rules{$host_model}{EXT_BDFILE};
          } ;
        } else {
          unless ( $ext_bdpath_sfx =~ /\+/ ) {
            if ( $ii == 0 ) {
              $ext_bdpath_sfx = $ext_bdpath_sfx.'/'.$rules{$host_model}{AN_SFX};
            } else {
              $ext_bdpath_sfx = $ext_bdpath_sfx.'/'.$rules{$host_model}{FC_SFX};
            } ;
          } ;
        } ;
      } ;
    }
    # Build file path
    for $key ( keys %keywords ) { $bdpath     = change_key($key,$keywords{$key},$bdpath   ); } ;
    for $key ( keys %keywords ) { $bdpath_an  = change_key($key,$keywords{$key},$bdpath_an); } ;
    for $key ( keys %keywords ) { $int_bdfile = change_key($key,$org_keywords{$key},$int_bdfile); } ;
    if ( $write_surf_ini ) {
      for $key ( keys %keywords ) { $bdpath_sfx     = change_key($key,$keywords{$key},$bdpath_sfx   ); } ;
      for $key ( keys %keywords ) { $bdpath_an_sfx  = change_key($key,$keywords{$key},$bdpath_an_sfx); } ;
      for $key ( keys %keywords ) { $int_sini_file  = change_key($key,$org_keywords{$key},$int_sini_file); } ;
    }
    if ( $ext_bdpath ) {
      for $key ( keys %keywords ) { $ext_bdpath = change_key($key,$keywords{$key},$ext_bdpath); } ;
    } ; 
    if ( $write_surf_ini ) {
      if ( $ext_bdpath_sfx ) {
        for $key ( keys %keywords ) { $ext_bdpath_sfx = change_key($key,$keywords{$key},$ext_bdpath_sfx); } ;
      } ;
     }
     if ( $nsearch > 25 ) { die "Could not find boundary data for $dtg+$i \nLast search:$bdpath\n" ; } ;

    $nsearch++ ;

  
    # For BDSTRATEGY=available we have to try both AN and FC case
    if ( $strategy eq 'available' &&  $ii == 0 ) { 
      $bdpath_an = $bdpath if ( -s $bdpath_an ) ;
    }

    $write_bd=0;
    $write_sfx_in=0;
    if ( $do_search == 0 ) {
      $write_bd=1;
      if ( $write_surf_ini ) {
        $write_sfx_in=1;
      }
    }else {
      if (( $write_surf_ini == 1 ) && ( -s $bdpath_sfx )) {
        $write_sfx_in=1;
      }
      if ( -s $bdpath ) {
        $write_bd=1;
        $ldtg = $mdtg ; 
      }
    }

    if ( $write_bd || $write_sfx_in ) {
       $vdtg=`mandtg $dtg + $i`; chop $vdtg;
       $pi=sprintf("%3.3i",$i);

       if ( $rules{$host_model}{EXT_ACCESS} || $rules{$host_model}{EXT_BDDIR} ) {

          if ( ( $host_model eq 'ifs' ) && ( ! $ext_access_changed ) &&
               ( $ENV{COMPCENTRE} eq 'ECMWF' || $ENV{COMPCENTRE} eq 'SMHI' || $ENV{COMPCENTRE} eq 'METNO' || $ENV{COMPCENTRE} eq 'METIE'  )
             ) {

             # Build boundary strategy rule for ECMWF data
             $mdate= substr($mdtg,0,8) ;
             $mhour= substr($mdtg,8,2) ;
             if ( $write_sfx_in ) {
               print "SURFEX_INI| $int_sini_file $bdpath_sfx $rules{$host_model}{EXT_ACCESS} -b $bdpath -k $i -d $mdate -h $mhour -l $ii -t\n";
               $write_surf_ini = 0;
             }
             if ( $write_bd && $i >= $llshift ) { print "$pi|$vdtg $int_bdfile $bdpath $rules{$host_model}{EXT_ACCESS} -b $bdpath -k $i -d $mdate -h $mhour -l $ii -t\n";} 
          } else {
             if ( $write_sfx_in ) {
               print "SURFEX_INI| $int_sini_file $bdpath_sfx $rules{$host_model}{EXT_ACCESS} $ext_bdpath_sfx \n";
               $write_surf_ini = 0;
             }
             # Build boundary strategy rule for other data
             if ( $write_bd && $i >= $llshift ) { print "$pi|$vdtg $int_bdfile $bdpath $rules{$host_model}{EXT_ACCESS} $ext_bdpath \n";} 
          } ;
       } else {
         if ( $write_sfx_in ) {
           print "SURFEX_INI| $int_sini_file $bdpath_sfx\n";
           $write_surf_ini = 0;
         }
          if ( $write_bd && $i >= $llshift ) { print "$pi|$vdtg $bdpath\n";} 
       }
       
       if ( $write_bd ) { $found_file_bd = 1;}
       if ( $write_surf_ini == 0 ) {$found_file_sfx = 1;}
    }

   }

}

sub change_key {

 my ($old,$new,$tmp) = @_ ;

 $lo = length($old)-2;
 $ln = length($new);

 while ( $ln lt $lo ) { 
    $new = "0".$new;
    $ln = length($new);
 } ;

 $tmp =~ s/$old/$new/g ;

 return $tmp ;

}
