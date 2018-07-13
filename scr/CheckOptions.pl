use POSIX ;
require($ENV{'HM_LIB'}."/scr/Harmonie_domains.pm");
require($ENV{'HM_LIB'}."/scr/utils.pm");

#
# Check consistency of choices in config_exp.h
# The method is copied from hirlam/scripts/
#

# Get domain
$DOMAIN=$ENV{'DOMAIN'} || die "\nERROR: DOMAIN is not set!\n";

# Get the domain properties
my %domain_props=&Harmonie_domains($DOMAIN);
for my $var ( sort keys %domain_props ) {
  $$var=$domain_props{$var};
}


# Get the required environment variables
# -----------------------------------------
foreach $var ( qw/ HM_LIB 
                   SIMULATION_TYPE
                   DOMAIN ARCHIVE_ROOT
                   PHYSICS DYNAMICS SURFACE DFI
                   ANAATMO ANASURF
                   FCINT BDINT
                   HOST_MODEL HOST_SURFEX
                   NOUTERLOOP ILRES DOMAIN
                   TFLAG SCHEDULER
                   f_JBCV f_JBBAL
                   VERIFY OBSEXTR VOBSDIR
                   COMPCENTRE VLEV LSMIXBC
                   ENSMSEL ENSINIPERT
                   TESTBED_LIST
                   HWRITUPTIMES SWRITUPTIMES
                   SURFEX_SEA_ICE
                   SURFEX_OUTPUT_FORMAT SURFEX_LSELECT
                   SFXFULLTIMES
                   HH_LIST LL_LIST
                   ECOCLIMAP_DATA_PATH GMTED2010_DATA_PATH
                   PGD_DATA_PATH E923_DATA_PATH
                   BDSTRATEGY
                   FREQ_RESET_GUST
                   ARCHIVE_FORMAT MAKEGRIB_VERSION CONVERTFA
                   / ) {
   if ( exists $ENV{$var} ) {
      $$var=$ENV{$var};
   } else {
      push @lackenv, $var;
   }
}

# Some required environment variables missing?
# ------------------------------------------------

if ( @lackenv ) {
   print STDERR "The following environment variables are needed but missing:\n\t";
   print STDERR join("\n\t", @lackenv);
   die "\n$0 failed\n";
}

# Scan the arguments
$dry = 0 ;
$ensmbr = -1;

while ( <@ARGV> ) {

   if (/^-d/) { $dry = 1; }

}

#
# Define config file to append to
#

if ( not $dry ) {
   $config_updated="$HM_LIB/sms/config_updated.h";
   open CU, ">$config_updated" or die "cannot open $config_updated\n";
}


# 3.  check options
# -----------------

# Check validity/consistency of HH_LIST and LL_LIST
my @cycles = &gen_list($HH_LIST,"%d");
my @fclen = split(',',$LL_LIST);   #TODO: improve
if ( scalar(@cycles) % scalar(@fclen) != 0 ) {
   $error .= "The HH_LIST and LL_LIST lists have incompatible lengths!\n"
       . "   HH_LIST has length: ".scalar(@cycles)."\n"
       . "   LL_LIST  has length: ".scalar(@fclen)."\n\n";
}
if ( scalar(@cycles) > 1 ) {
   $FCINT = $cycles[0] + 24 - $cycles[-1];
   for (my $i=1; $i<=$#cycles; $i++) {
      my $fcint = $cycles[$i] - $cycles[$i-1];
      if ($fcint != $FCINT) {
	 $error .= "The HH_LIST array does not give a fixed forecast interval FCINT!\n"
	     . "   This is currently not allowed.\n\n";
	 last;
      }
   }
} else {
   $FCINT = 24;
}
$ENV{FCINT} = $FCINT;

#
# Define physics options
#

%trgt_model = (

    'arome'  => {
       'surfex'       => 'yes',
       'nh'           => 'yes',
    },

    'aladin'  => {
       'surfex'       => 'yes',
       'old_surface'  => 'yes',
       'nh'           => 'yes',
       'h'            => 'yes',
    },

    'alaro'  => {
       'surfex'       => 'yes',
       'old_surface'  => 'yes',
       'nh'           => 'yes',
       'h'            => 'yes',
    },

);

#
# Check IFS LBCs
#
$dtg = $ENV{DTG};
$playfile = $ENV{PLAYFILE} or $playfile="harmonie";
if ( ($BDINT lt 3) && ($HOST_MODEL eq "ifs")  && ($dtg lt 2011111512) &&
($playfile eq "harmonie")) {
  $error .= "ERROR: BDINT must be >= 3 to use $HOST_MODEL LBCs before 2011111512\n       Please change value of BDINT in sms/config_exp.h\n\n";
};

if ( ($BDINT lt 3) && ($BDSTRATEGY eq "eps_ec") ) {
  $error .= "ERROR: BDINT must be >= 3 for BDSTRATEGY=$BDSTRATEGY \n       Please change value of BDINT in sms/config_exp.h\n\n";
};

#
# Check PHYSICS
#
unless ( exists( ${trgt_model}{$PHYSICS}) ) {
  $error .= " Cannot handle physics option PHYSICS=$PHYSICS \n";
} ;


#
# Check DYNAMICS
#

unless ( exists( ${trgt_model}{$PHYSICS}{$DYNAMICS}) ) {
  $error .= " Cannot handle dynamics option DYNAMICS=$DYNAMICS for PHYSICS=$PHYSICS \n";
} ;


#
# Check SURFACE
#

unless ( exists( ${trgt_model}{$PHYSICS}{$SURFACE}) ) {
  $error .= " Cannot handle dynamics option SURFACE=$SURFACE for PHYSICS=$PHYSICS \n";
} ;

# Some host models are not defined with SURFEX
if ( $HOST_SURFEX eq "yes"  && ( $HOST_MODEL eq "ifs"  ||  $HOST_MODEL eq "hir" )) {
  $error .= " HOST_MODEL=$HOST_MODEL does not have SURFEX as surface model!\n";
};

# Some host models must have SURFEX as surface
if ( $HOST_SURFEX ne "yes"  && $HOST_MODEL eq "aro" ) {
  $error .= " HOST_MODEL=$HOST_MODEL does not have meaning without having SURFEX as surface model!\n";
};

# SURFEX_LSELECT=yes has not been tested with SURFEX_OUTPUT_FORMAT=lfi
if ( $SURFACE eq "surfex" && $SURFEX_LSELECT eq "yes"  && $SURFEX_OUTPUT_FORMAT eq "lfi" ) {
  $error .= " SURFEX_LSELECT=yes has not been tested with SURFEX_OUTPUT_FORMAT=lfi!\n";
};

# SURFEX_SEA_ICE=sice has only been tested with HOST_MODEL=ifs
if ( $SURFEX_SEA_ICE eq "sice" && $HOST_MODEL ne "ifs" ) {
print STDERR " SURFEX_SEA_ICE=sice has only been tested with HOST_MODEL=ifs!\n";
};

#
# Check DFI
#
if ( $ANAATMO eq none && $DFI eq idfi ) {
  $error .= " IDFI is not meaningful with ANAATMO=none \n";
}

# Reject JB_ENS_MEMBER
   if ( exists $ENV{'JB_ENS_MEMBER'} ) {
  $error .= " JB_ENS_MEMBER is now changed into ENS_MEMBER. Correct and resubmit\n";
};

#
# Check output options
#

if ( 3600 % $TSTEP != 0 ) {
  $error .= " The time step TSTEP should be a factor of one hour (3600 seconds) \n";
};

if ( $SIMULATION_TYPE eq 'nwp' ) {

 #
 # Check upper air assimilation options
 #

 $bdcycle = &get_bdcycle ;

 if ( $ANAATMO =~ /VAR/ ) {
   if ( $f_JBBAL eq 'undefined' || $f_JBCV eq 'undefined' ) {
      $error .= " No JB statistics for this DOMAIN=$DOMAIN\n";
      $error .= " Please set f_JBCV and f_JBBAL\n";
   }

   if ( $FCINT < $BDINT && $FCINT < $bdcycle ) {
      $error .= " FCINT=$FCINT < BDINT=$BDINT and BDCYCLE=$bdcycle\n Assimilation cycle cannot be shorter than available boundary data frequency!\n";
   }
 } else {
   if ( $LSMIXBC eq 'yes' ) {
      $error .= " LSMIXBC=yes is not meaningful with ANAATMO=$ANAATMO\n";
   }
 }

 if ( $ANAATMO eq '4DVAR' ) {
   if ( $FCINT < 1 ) {
       $error .= " 4D-Var only works for FCINT>=1 at the moment\n";
   }
 }


 #
 # Check surface assimilation options
 #

 if ( $ANASURF =~ /CANARI/ ) {

   if ( ( $ANASURF eq 'CANARI_OI_MAIN' || $ANASURF eq 'CANARI_EKF_SURFEX' ) && $SURFACE eq 'old_surface' ) {
      $error .= " ANASURF=CANARI_OI_MAIN has do be run together with SURFACE=surfex \n";
   } ;

   if ( $ANASURF eq 'CANARI' && $SURFACE eq 'surfex' ) {
      $error .= " ANASURF=CANARI has do be run together with SURFACE=old_surface \n";
   } ;

   if  ( $FCINT < $BDINT && $FCINT < $bdcycle ) {
      $error .= " FCINT=$FCINT < BDINT=$BDINT and BDCYCLE=$bdcycle . Assimilation cycle cannot be shorter than available boundary data frequency \n"; 
   }

 } ;

 if ( $ANAATMO eq '3DVAR' and $ANASURF_MODE eq 'both' and $ANASURF ne "none" ) {
  $error .= " ANASURF_MODE=both is not allowed for 3D-Var \n";  
 }
 if ( $ANAATMO eq '3DVAR' and $ANASURF_MODE eq 'after' and $ANASURF ne "none" ) {
  $error .= " Sorry CANARI does not work yet for an analysis having forecast length equal zero :-( \n";
 }


 #
 # Check assimilation combinations options together with EPS options
 #

 if ( $ANAATMO eq 'none' and $ANASURF ne 'none' and $ENSINIPERT ne 'randb' ) {
  if ( $ENSMSEL eq '' ) {
    $error .= " ANAATMO=$ANAATMO and ANASURF=$ANASURF is not a healthy combination\n";
  } elsif ( $ENSINIPERT  !~ /bnd/ ) {
    $error .= " ANAATMO=$ANAATMO and ANASURF=$ANASURF is not a healthy combination if ENSINIPERT=$ENSINIPERT\n";
  }
 }


 #
 # Check that necessary first guess files are produced for continued runs
 #
 my $dtgbeg = $ENV{DTGBEG} || $ENV{DTG};
 my $dtgend = $ENV{DTGEND} || $ENV{DTG};
 chomp(my $dtgcont = qx(mandtg $dtgbeg + $FCINT));
 if ( ($ANAATMO =~ /^[34]DVAR$/ or $ANASURF ne 'none') and ($dtgend >= $dtgcont) ) {
  # Check HWRITUPTIMES
  my $found = 0;
  my $fac = $FCINT ;
  if ( $TFLAG eq "min" ) { $fac = $FCINT * 60 ; }
  for my $ll ( split(':',&gen_list($HWRITUPTIMES)) ) {
    if ( $ll == $fac ) { $found = 1; last; }
  }
  if ( not $found ) {
    $error .= " FCINT=$fac not found in HWRITUPTIMES, first guess will be missing at $dtgcont !\n";
  }
  # Check SWRITUPTIMES if necessary
  if ( $SURFACE eq 'surfex' ) {
    my $found = 0;
    if ( $SURFEX_LSELECT eq "no" ) {
     for my $ll ( split(':',&gen_list($SWRITUPTIMES)) ) {
       if ( $ll == $fac ) { $found = 1; last; }
     }
     if ( not $found ) {
       $error .= " FCINT=$fac not found in SWRITUPTIMES, surfex first guess will be missing at $dtgcont !\n";
     }
    }
  }
 }

} else {

 if ( $SCHEDULER ne MSMS ) {
   $error .= " SIMULATION_TYPE=$SIMULATION_TYPE does not yet work with SCHEDULER=$SCHEDULER \n";
 }

}# End check SIMULATION_TYPE

#
# Check verification options
#

if ( $VERIFY eq yes ) {

 if ( $OBSEXTR eq none ) { 
      $error .= " OBSEXTR should not be none when VERIFY is $VERIFY \n";
 }

 if ( $OBSEXTR eq vobs and $VOBSDIR eq none) { 
      $error .= " VOBSDIR should not be none when OBSEXTR is $OBSEXTR \n";
 }

}


# Check the vertical level definition

$msg =`Vertical_levels.pl $VLEV TEST `;
if ($? != 0) { $error .= $msg ; } ; 
$NLEV =`Vertical_levels.pl $VLEV NLEV `;
chomp $NLEV ;

# Check grid truncation if it is a linear grid (needed for spectrally smoothed orography)
my $nfac=qx(factor $NLON);
my $lfac=qx(factor $NLAT);
chomp $nfac;
chomp $lfac;
my @nfac=split(" ",$nfac);
my @lfac=split(" ",$lfac);
# Remove first value (same as input)
shift @nfac;
shift @lfac;

my $facstr="";
my $facerror=0;
foreach my $fac (@nfac){
  $facstr.=" $fac";
  if ( $fac > 5 ) { $facerror=1;} 
}
if ( $facerror ) { $error .= "NLON $NLON has factor(s) that are greater than 5. Factors: 1$facstr.\n";}

$facstr="";
$facerror=0;
foreach my $fac (@lfac){
  $facstr.=" $fac";
  if ( $fac > 5 ) { $facerror=1;}
}
if ( $facerror ) { $error .= "NLAT $NLAT has factor(s) that are greater than 5. Factors: 1$facstr.\n";}

#
# Check grid truncation. Linear grid needed for spectral smoothed orography
if ( $DOMAIN ne "MUSC" ) {
if ( ( $NLON - 2 )% 2 != 0 ){
  $error .= "NLON $NLON is not divisible by 2\n";
}
if ( ( $NLAT - 2 )% 2 != 0 ){
  $error .= "NLAT $NLAT is not divisible by 2\n";
}
} ;
if ( $ANAATMO eq "4DVAR" ){
  foreach my $res (split(',',$ILRES))  {
    if ( $res != 0 ) {
      my $nlon=$NLON / $res;
      my $nlat=$NLAT / $res;
      if ( ( $nlon - 2 )% 2 != 0 ){
        $error .= "nlon $nlon is not divisible by 2 for ilres $res\n";
      }
      if ( ( $nlat - 2 )% 2 != 0 ){
        $error .= "nlat $nlat is not divisible by 2 for ilres $res\n";
      }
    }else{
      $error .= "res = 0. Check that ILRES is properly set!\n";
    }
  }
}

#
# Check ARCHIVE_FORMAT consistency
#

if ( $CONVERTFA eq "yes" ) {
 if ( $ARCHIVE_FORMAT eq "GRIB2" && $MAKEGRIB_VERSION ne "grib_api" ){
  $error .= "MAKEGRIB_VERSION=$MAKEGRIB_VERSION does not work with ARCHIVE_FORMAT=$ARCHIVE_FORMAT, use MAKEGRIB_VERSION=grib_api instead\n";
 }

 if ( $ARCHIVE_FORMAT eq "nc" && $SIMULATION_TYPE ne "climate" ){
  $error .= "ARCHIVE_FORMAT=$ARCHIVE_FORMAT does not work with SIMULATION_TYPE=$SIMULATION_TYPE\n";
 }
}

#
# 9.Error exit
# ------------

die "\n$error\n Check hirlam.org for further information. \n\n" if $error;


if ( not $dry and $ensmbr < 0 ) {

  # Put levels together with domain information
  $domain_props{'NLEV'}=$NLEV;

  #
  # Update the sms/config_update.h file
  #
  print CU "\n# Domain definitions for domain ".$DOMAIN."\n";
  for my $var ( sort keys %domain_props ) {
    print CU "export $var=".$domain_props{$var}."\n";
  }

  print CU "\n# Other definitions for domain ".$DOMAIN."\n";

  # Default forecast interval
  print CU "export FCINT=$FCINT\n";

  # Archive path
  print CU 'export ARCHIVE=$ARCHIVE_ROOT/$YY/$MM/$DD/$HH/'."\n";

  # Check LMPOFF
  unless ( $ENV{LMPOFF} ) { print CU "export LMPOFF=.FALSE. \n" ; }

  # NXGUSTPERIOD
  if ( $FREQ_RESET_GUST == -1 ) {
   $nxgp = -1 ;
  } else {
   $nxgp = $FREQ_RESET_GUST * 3600 ;
  }
  print CU "export NXGSTPERIOD=$nxgp\n";

  # Model
  print CU "export MODEL=\${MODEL-MASTERODB}\n";

  # Expand and set EPS variables
  $ENSMSELX = `Ens_util.pl ENSMSEL $ENSMSEL` ;
  print CU "export ENSMSELX=$ENSMSELX\n";

  # Insert computation of forecast length
  if ( $ENV{SIMULATION_TYPE} eq "climate" ) {
     print CU 'LL=$( Update_LL )'."\n";
  } else {
     print CU 'LL=$( HH2LL.pl $HH $ENSMBR )'."\n";
  }
  print CU "export LL\n";

  # Set number of testbed cases
  $TESTBED_LIST =~ s/( ){1,}/ /g ;
  @tmp = split(' ',$TESTBED_LIST)  ;
  $testbed_cases = scalar(@tmp) ;	
  print CU "export TESTBED_CASES=$testbed_cases\n";

  # For ensemble members, source member specific settings
  print CU "if \[ \$\{ENSMBR--1\} -ge 0 \]; then\n"; 
  print CU "  if \[ -s \$HM_LIB/sms/config_mbr\$ENSMBR.h \]; then\n";
  print CU ". \$HM_LIB/sms/config_mbr\$ENSMBR.h\n";
  print CU "  fi\n";
  print CU "fi\n";

  close CU;

}
