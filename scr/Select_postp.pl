#!/usr/bin/perl 
#
# Select fields for postprocessing  
#
# Ulf Andrae, SMHI, 2013
#
# 1. Define the variables and levels you would like to postprocess in NAMFPC
# 2. Define the selection of variables you would like to output with different frequency
#    At the moment there is only one selection for all timesteps, but we can easily define
#    new streams
# 3. Define the deviation depending on physics, ensemble member number, etc.
#

#
# Definitions
#

# Domain name
$DOMAIN = $ENV{DOMAIN};

# Define empty namelists
%namsats  = ();
%namfpc   = ();
%namppc   = ();
%namfpdy2 = ();
%namfpdyf = ();
%namfpdyh = ();
%namfpdyt = ();
%namfpdys = ();
%namfpdyv = ();
%namfpdyi = ();
%namfpdyp = ();

# Extract the model level list
chomp( $NRFP3S = qx(Vertical_levels.pl $ENV{VLEV} NRFP3S) );
$NRFP3S =~ s/NRFP3S=//g;
@nrfp3s = split(',',$NRFP3S);

#
# Main namelist file (fort.4) namelists
#

%namsats = (
  GENERAL => {
    LRTTOV_INTERPOL => '.FALSE.',
  },
);


# Basic definitions, for all types of runs
# These basic fields are just enough to make sure we can run
# the verification

%namfpc = (

  GENERAL => {
    LFPCAPEX =>'.TRUE.',
    LFPMOIS => '.FALSE.',
    NFPCLI => '1',
    NFPCAPE => '5',
    CFPFMT => "'LELAM'",
    CFPDOM  => "'$DOMAIN'",
    L_READ_MODEL_DATE => '.TRUE.',
            },

  CFP2DF => ['SURFPRESSION','MSLPRESSURE'],

  CFP3DF => ['GEOPOTENTIEL','TEMPERATURE','WIND.U.PHYS','WIND.V.PHYS',
             'HUMI_RELATIVE','HUMI.SPECIFI',
             'SOLID_WATER' ,'LIQUID_WATER','RAIN','SNOW','GRAUPEL'],

  CFPPHY => ['SURFTEMPERATURE','INTSURFGEOPOTENT','SURFRESERV.NEIGE'],

  CFPXFU => ['CLSTEMPERATURE','CLSHUMI.RELATIVE','CLSHUMI.SPECIFIQ','CLSVENT.ZONAL','CLSVENT.MERIDIEN',
             'CLSU.RAF.MOD.XFU','CLSV.RAF.MOD.XFU','CLSMAXI.TEMPERAT','CLSMINI.TEMPERAT',
             'SURFNEBUL.CONVEC','SURFNEBUL.HAUTE','SURFNEBUL.MOYENN','SURFNEBUL.BASSE',
             'SURFNEBUL.TOTALE'],

  # Vertical level definitions
  NRFP3S => [@nrfp3s],
  RFP3P => ['5000','10000.','15000.','20000.','25000.','30000.',
            '40000.','50000.','60000.','70000.','80000.',
            '85000.','90000.','92500.','95000.','100000.'],
  RFP3H => [],
  RFP3PV => [],
  RFP3I => [],

) ;

if ( $ENV{ENSMBR} < 0 or $ENV{ENSMBR} == $ENV{ENSCTL} ) {

  # Settings for deterministic/control runs. All inclusive!

  $namfpc{CFP2DF} = [@{ $namfpc{CFP2DF} },
                     'SURFTOT.WAT.VAPO','SURFISOTPW0.MALT','SURFCAPE.POS.F00',
                     'SURFCIEN.POS.F00','SURFLIFTCONDLEV','SURFFREECONVLEV',
                     'SURFEQUILIBRLEV'];

  $namfpc{CFP3DF} = [@{ $namfpc{CFP3DF} },
             'THETA_PRIM_W','PRESSURE','ABS_VORTICITY','VITESSE_VERTICALE','TEMPE_POTENT',
             'POT_VORTICIT','SIM_REFLECTI',
              'VERT.VELOCIT','DIVERGENCE',
             'THETA_VIRTUA','TKE','CLOUD_FRACTI','ISOT_ALTIT'];

  CFPPHY => ['SURFTEMPERATURE','INTSURFGEOPOTENT','SURFRESERV.NEIGE'];

  $namfpc{CFPXFU} = [@{ $namfpc{CFPXFU} },
                     'CLPMHAUT.MOD.XFU'];

  $namfpc{CFPCFU} = ['SURFTENS.TURB.ZO','SURFTENS.TURB.ME',
             'SOMMFLU.RAY.SOLA','SURFFLU.RAY.SOLA','SOMMFLU.RAY.THER','SURFFLU.RAY.THER','SURFFLU.LAT.MEVA',
             'SURFFLU.LAT.MSUB','SURFFLU.MEVAP.EA','SURFFLU.MSUBL.NE','SURFFLU.CHA.SENS','SURFRAYT SOLA DE',
             'SURFRAYT THER DE','SURFRAYT SOL CL','SURFRAYT THER CL'];


  # Upper levels
  $namfpc{RFP3H}  = ['20.','50.','100.','250.','500.','750.','1000.','1250.','1500.','2000.','2500.','3000.'];
  $namfpc{RFP3PV} = [1.5E-6,2.E-6];
  $namfpc{RFP3I}  = [-273.15,-263.15];

}

#
# Selection namelists
# Now we defined everything a second time with the same 
# separation between basic and pure deterministic setup
#

# Single level fields basic setup

%namfpphy = (

  CLPHY => ['SURFTEMPERATURE','INTSURFGEOPOTENT','SURFRESERV.NEIGE'],

  CLXFU => ['CLSTEMPERATURE','CLSHUMI.RELATIVE','CLSHUMI.SPECIFIQ','CLSVENT.ZONAL','CLSVENT.MERIDIEN',
            'CLSU.RAF.MOD.XFU','CLSV.RAF.MOD.XFU','CLSMAXI.TEMPERAT','CLSMINI.TEMPERAT',
            'SURFNEBUL.CONVEC','SURFNEBUL.HAUTE','SURFNEBUL.MOYENN','SURFNEBUL.BASSE',
            'SURFNEBUL.TOTALE'],

);

%namfpdy2 = (
  CL2DF => ['SURFPRESSION','MSLPRESSURE'],
);

if ( $ENV{ENSMBR} < 0 or $ENV{ENSMBR} == $ENV{ENSCTL} ) {

  $namfpphy{CLXFU} = [@{ $namfpphy{CLXFU} },
           'CLPMHAUT.MOD.XFU'];

  $namfpphy{CLCFU} = ['SURFTENS.TURB.ZO', 'SURFTENS.TURB.ME', 
            'SOMMFLU.RAY.SOLA', 'SURFFLU.RAY.SOLA', 'SOMMFLU.RAY.THER', 'SURFFLU.RAY.THER', 'SURFFLU.LAT.MEVA',
            'SURFFLU.LAT.MSUB', 'SURFFLU.MEVAP.EA', 'SURFFLU.MSUBL.NE', 'SURFFLU.CHA.SENS', 'SURFRAYT SOLA DE',
            'SURFRAYT THER DE' ];

  $namfpdy2{CL2DF} = [@{ $namfpdy2{CL2DF} },'SURFTOT.WAT.VAPO', 'SURFISOTPW0.MALT'];

}



# Model level fields
# The numbers corresponds to the ones in NRFP3S

%namfpdys = (

  # 'VERT.VELOCIT'   => [@nrfp3s],
    'RAIN'           => [$nrfp3s[-1]],
    'SNOW',          => [$nrfp3s[-1]],
    'LIQUID_WATER'   => [$nrfp3s[-1]],
    'SOLID_WATER'    => [$nrfp3s[-1]],
    'TEMPERATURE'    => [$nrfp3s[-1]],

);

if  ( $ENV{PHYSICS} eq 'arome' ) {
  $namfpdys{'GRAUPEL'} = [$nrfp3s[-1]]; 
};

# Pressure levels
# The numbers corresponds to the ones in RFP3P

@namfpdyp_lev = (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16) ;


if ( $ENV{ENSMBR} < 0 or $ENV{ENSMBR} == $ENV{ENSCTL} ) {

    %namfpdyp = (

      # For deterministic run or control
      GEOPOTENTIEL   => [@namfpdyp_lev],
      TEMPERATURE    => [@namfpdyp_lev],
      'WIND.U.PHYS'  => [@namfpdyp_lev],
      'WIND.V.PHYS'  => [@namfpdyp_lev],
      HUMI_RELATIVE  => [@namfpdyp_lev],
      'HUMI.SPECIFI' => [@namfpdyp_lev],
      THETA_PRIM_W   => [4,5,6,7,8,9,10,11,12,13,14,15,16],
      ABS_VORTICITY  => [6,8,9,10,12],
      POT_VORTICITY  => [@namfpdyp_lev],
      RAIN           => [@namfpdyp_lev],
      SNOW           => [@namfpdyp_lev],
      GRAUPEL        => [@namfpdyp_lev],
      SOLID_WATER    => [@namfpdyp_lev],
      LIQUID_WATER   => [@namfpdyp_lev],
      'VERT.VELOCIT' => [@namfpdyp_lev],
      DIVERGENCE     => [6,15],
      THETA_VIRTUA   => [9,10,11,12,13,14,15,16],
      CLOUD_FRACTI   => [@namfpdyp_lev],

    );

} else {

    %namfpdyp = (

      # Perturbed members: Minimum for verification
      GEOPOTENTIEL   => [@namfpdyp_lev],
      TEMPERATURE    => [@namfpdyp_lev],
      'WIND.U.PHYS'  => [@namfpdyp_lev],
      'WIND.V.PHYS'  => [@namfpdyp_lev],
      HUMI_RELATIVE  => [@namfpdyp_lev],
      'HUMI.SPECIFI' => [@namfpdyp_lev],

    );
}

if ( $ENV{ENSMBR} < 0 or $ENV{ENSMBR} == $ENV{ENSCTL} ) {

  # Height level fields
  # The numbers corresponds to the ones in RFP3H

  @namfpdyh_lev = (1,2,3,4,5,6,7,8,9,10,11,12) ;
  %namfpdyh = (

    TEMPERATURE   => [@namfpdyh_lev],
    'WIND.U.PHYS' => [@namfpdyh_lev],
    'WIND.V.PHYS' => [@namfpdyh_lev],
    HUMI_RELATIVE => [@namfpdyh_lev],
    PRESSURE      => [@namfpdyh_lev],
    RAIN          => [@namfpdyh_lev],
    SNOW          => [@namfpdyh_lev],
    GRAUPEL       => [@namfpdyh_lev],
    SOLID_WATER   => [@namfpdyh_lev],
    LIQUID_WATER  => [@namfpdyh_lev],
    CLOUD_FRACTI  => [@namfpdyh_lev],

  ) ;

  # PV level fields
  # The numbers corresponds to the ones in RFP3V

  @namfpdyv_lev = (1,2);
  %namfpdyv = (

    GEOPOTENTIEL  => [@namfpdyv_lev],
    'WIND.U.PHYS' => [@namfpdyv_lev],
    'WIND.V.PHYS' => [@namfpdyv_lev],
    TEMPE_POTENT  => [@namfpdyv_lev],
    ABS_VORTICITY => [@namfpdyv_lev],
    POT_VORTICITY => [@namfpdyv_lev],

  );

  # Isothermal surface level fields
  # The numbers corresponds to the ones in RFP3I

  %namfpdyi = (
     ISOT_ALTIT => [1,2],
  );


}


#
# Special treatment depending on physics
# Here we can define or remove fields
#
if ( $ENV{PHYSICS} eq 'alaro' ) {

  # Add alaro specific variables
  $namfpc{CFPCFU}  = [@{ $namfpc{CFPCFU} }, 'SURFPREC.EAU.CON','SURFPREC.NEI.CON','SURFPREC.NEI.GEC','SURFPREC.EAU.GEC'];
  $namfpphy{CLCFU} = [@{ $namfpphy{CLCFU} },'SURFPREC.EAU.CON','SURFPREC.NEI.CON','SURFPREC.NEI.GEC','SURFPREC.EAU.GEC'];

} elsif ( $ENV{PHYSICS} eq 'arome' ) {

  # Add arome specific variables
  $namfpc{CFPCFU}  = [@{ $namfpc{CFPCFU} },'SURFACCPLUIE','SURFACCNEIGE','SURFACCGRAUPEL'];
  $namfpphy{CLCFU} = [@{ $namfpphy{CLCFU} },'SURFACCPLUIE','SURFACCNEIGE','SURFACCGRAUPEL'];

  if ( $ENV{ENSMBR} < 0 or $ENV{ENSMBR} == $ENV{ENSCTL} ) {

    $namfpc{CFPXFU}  = [@{ $namfpc{CFPXFU} },'SURFDIAGHAIL','SURFINSPLUIE','SURFINSNEIGE','SURFINSGRAUPEL'];
    $namfpphy{CLXFU} = [@{ $namfpphy{CLXFU} },'SURFDIAGHAIL','SURFINSPLUIE','SURFINSNEIGE','SURFINSGRAUPEL'];
    $namfpdy2{CL2DF} = [@{ $namfpdy2{CL2DF} },'SURFCAPE.POS.F00','SURFCIEN.POS.F00','SURFLIFTCONDLEV','SURFFREECONVLEV','SURFEQUILIBRLEV'];

  }

}

#
# Special treatment if we run offline
#

if ( $ENV{FULLPOS_TYPE} eq 'offline' ) {
  $namfpc{GENERAL}{L_READ_MODEL_DATE} = '.FALSE.';

  if ( $ENV{FULLPOS_LL} == 0 ) {
    delete $namfpc{CFPCFU} ;
    delete $namfpc{CFPXFU} ;
    delete $namfpc{CFP2DF} ;
    delete $namfpphy{CLCFU} ;
    delete $namfpphy{CLXFU} ;
    delete $namfpdy2{CL2DF} ;
    delete $namfpdy2{CL3DF} ;
  }

}

# Write the addition to fort.4
@blev = ('namsats','namfpc');
open OUT, ">> fort.4";
for $namelist ( @blev ) { &write_blev($namelist); }
close OUT;

# Write the selection namelist
@slev = ('namfpphy','namppc','namfpdy2');
@mlev = ('namfpdyi','namfpdyv','namfpdyh','namfpdyp','namfpdys','namfpdyt','namfpdyf');


#
# Generate selection namelist for +0 (select_p0)
# and all other hourly timesteps ( select_p1)
#

for $files ("select_p1","select_p0") {

  open OUT, "> $files";

  for $namelist ( @slev ) { &write_slev($namelist); }
  for $namelist ( @mlev ) { &write_mlev($namelist); }

  close OUT;

}

#
# Generate selection namelist for sub-hourly timesteps ( select_p2)
#

#
# First the selection of the parameters
#

for $files ("select_p2") {

 # Model level fields

  %namfpdys = (

    TEMPERATURE   => [$nrfp3s[-1]],
    RAIN          => [$nrfp3s[-1]],
    SNOW          => [$nrfp3s[-1]],
    GRAUPEL       => [$nrfp3s[-1]],
    SOLID_WATER   => [$nrfp3s[-1]],
    LIQUID_WATER  => [$nrfp3s[-1]],
    TKE           => [$nrfp3s[-1]],

  );

  %namfpphy = (

    CLPHY =>['SURFTEMPERATURE','SURFRESERV.NEIGE'],

    CLXFU =>['CLSTEMPERATURE', 'CLSHUMI.RELATIVE', 'CLSVENT.ZONAL', 'CLSVENT.MERIDIEN', 'SURFNEBUL.TOTALE',
             'SURFNEBUL.CONVEC', 'SURFNEBUL.HAUTE', 'SURFNEBUL.MOYENN', 'SURFNEBUL.BASSE', 'CLSU.RAF.MOD.XFU',
             'CLSV.RAF.MOD.XFU', 'CLPMHAUT.MOD.XFU'],

    CLCFU =>[ 'SURFTENS.TURB.ZO', 'SURFTENS.TURB.ME',
              'SOMMFLU.RAY.SOLA', 'SURFFLU.RAY.SOLA', 'SOMMFLU.RAY.THER', 'SURFFLU.RAY.THER', 'SURFFLU.LAT.MEVA',
              'SURFFLU.CHA.SENS', 'SURFRAYT SOLA DE',
              'SURFRAYT THER DE' ],
  );

  if  ( $ENV{PHYSICS} eq 'arome' ) {

    $namfpphy{CLCFU} = [@{ $namfpphy{CLCFU} },'SURFACCPLUIE','SURFACCNEIGE','SURFACCGRAUPEL'];
    $namfpphy{CLXFU} = [@{ $namfpphy{CLXFU} },'SURFDIAGHAIL','SURFINSPLUIE','SURFINSNEIGE','SURFINSGRAUPEL'];

  }

#
# Second the creation of the namelist. Note that for this a small subroutine write_few has been
# added at the bottom of this script
#

  open OUT, "> $files" ;

  for $namelist ( @slev ) { &write_few($namelist); }
  for $namelist ( @mlev ) { &write_few($namelist); }

  close OUT;

}



############################################################
############################################################
############################################################
sub write_blev {


$nam = shift ;

$NAM= uc $nam;
print OUT "\&$NAM\n";

$i = 0;
for $key ( sort keys %${nam} ) {
   if ( $key eq 'GENERAL' ) {
     for $role ( sort keys %{ ${$nam}{$key} } ) {
         print OUT " $role=${$nam}{$key}{$role},\n";
     } 
   } else {
     for $role (  @{ ${$nam}{$key} } ) {
         $i++ ;
         if ( $key =~/C/ ) { $role="\'$role\'"; } ;
         print OUT " $key($i)=$role,\n";
     }
     $i = 0;
   } ;
} ;
print OUT "\/\n";

 
}
############################################################
############################################################
############################################################
sub write_slev {

$nam = shift ;

$NAM= uc $nam;
print OUT "\&$NAM\n";
$i = 0;
for $key ( sort keys %${nam} ) {
     for $role (  @{ ${$nam}{$key} } ) {
         $i++ ;
         print OUT " $key($i)=\'$role\',\n";
         $dkey = $key ;
         $dkey =~ s/CL/CLD/g;
         print OUT " $dkey($i)=\'$DOMAIN\',\n";
     }
     $i = 0;
} ;
print OUT "\/\n";

 
}
############################################################
############################################################
############################################################
sub write_mlev {

$nam = shift ;

$NAM= uc $nam ;
print OUT "\&$NAM\n";
     $i = 0;
for $key ( sort keys %${nam} ) {
         $i++ ;
         print OUT " CL3DF($i)=\'$key\',\n";
         $nlist = scalar(@{${$nam}{$key}}) ;
         $list = sprintf "@{${$nam}{$key}}";
         $list =~ s/ /,/g ;
         print OUT " IL3DF(1:$nlist,$i)=$list,\n";
         $j = 0;
         foreach (@{${$nam}{$key}}) {
           $j++ ;
           print OUT " CLD3DF($j,$i)=\'$DOMAIN\',\n";
         }
} ;
print OUT "\/\n";

 
}
############################################################
############################################################
############################################################
sub write_few {

$nam = shift ;

$NAM= uc $nam;
print OUT "\&$NAM\n";
if ( $NAM eq 'NAMFPPHY' ) {
     $i = 0;
     for $key ( sort keys %${nam} ) {
         for $role (  @{ ${$nam}{$key} } ) {
            $i++ ;
            print OUT " $key($i)=\'$role\',\n";
            $dkey = $key ;
            $dkey =~ s/CL/CLD/g;
            print OUT " $dkey($i)=\'$DOMAIN\',\n";
         }
         $i = 0;
     }
} ;
if ( $NAM eq 'NAMFPDYS' ) {
     $i = 0;
     for $key ( sort keys %${nam} ) {
         $i++ ;
         print OUT " CL3DF($i)=\'$key\',\n";
         $nlist = scalar(@{${$nam}{$key}}) ;
         $list = sprintf "@{${$nam}{$key}}";
         $list =~ s/ /,/g ;
         print OUT " IL3DF(1:$nlist,$i)=$list,\n";
         $j = 0;
         foreach (@{${$nam}{$key}}) {
           $j++ ;
           print OUT " CLD3DF($j,$i)=\'$DOMAIN\',\n";
         }
     }
} ;
print OUT "\/\n";
 
}
############################################################
############################################################
############################################################
