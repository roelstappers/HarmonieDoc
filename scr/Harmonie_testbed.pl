#!/usr/bin/perl -w

my $HM_LIB=$ENV{'HM_LIB'};
my $HM_DATA=$ENV{'HM_DATA'};
require("$HM_LIB/scr/Harmonie_configurations.pm");
use strict;

#
# Definitions for HARMONIE standard test configurations
#
# Arguments : [ -c CONFIGURATION_NAME ] [ -g get_val ] [ -s ]
# 
# Each configuration defines the departure from the default 
# sms/config_exp.h and scr/include.ass
#
# A new experiment will be created and launched 
#

# Scan the arguments
my $config  = "undefined";
my $get_val = "undefined";
my $mode=2;
my $default_submit=0;

my $n = 0 ;
while ( <@ARGV> ) {
   if ( /-c/) { $config  = $ARGV[($n + 1)] ;} ;
   if ( /-g/) { $get_val = $ARGV[($n + 1)] ;} ;
   if ( /-s/) { $default_submit = 1 ;} ;
   $n++ ;
} ;

if (!defined($config)) { $config  = "undefined";}
if ( $config eq "undefined" ) { 
  print "Usage: Harmonie_testbed.pl -c config [ -g get_val ] [ -s ]\n";
  print "-s runs with default Env_submit\n";
  exit;
}

#
# Define standard test date and forecast length
# Verification dates and settings are defined further down
#

my $dtg       = 2017093018;
my $dtgend    = 2017100100;
my $ll        = 6;

#
# Find host
#

my $host;
$host=`hostname` or $host="default";
chomp $host; 
# Met Éireann PCs
if ( $host =~ /realin/ ) { $host="realin"; }
# Force ecg* hostname to ecgate
if ( $host =~ /ecg[a|b]/ ) { $host="ecgate"; }

# Set experiment name
my $EXP; 
$EXP = $ENV{EXP} or $EXP = 'EXP';

#
# Default settings for domains, physics etc.
#

 my $NESTED_3WAY  = 'TEST_2.5';
 my $NESTED_2WAY  = 'TEST_8';
 my $NESTED_1WAY  = 'TEST_11';
 my $VAR4D_DOMAIN = 'SCANDINAVIA';
         my $VLEV = 'HIRLAM_60';
      my $CLIMDIR = '$HM_DATA/../'.$EXP.'/climate/$DOMAIN/$PHYSICS';
my $DECOMPOSITION = '2D';

#
# Define host specific settings
# These will be added to any chosen configuration
#

my %host_defs = (

  'default' => {
   'LL_LIST'          => $ll,
   'BINDIR'         => '$HM_DATA/../'.$EXP.'/bin',
   'BUILD'          => 'no',
   'BUILD_ROOTPACK' => 'no',
   'CONVERTFA'      => 'yes',
   'INT_SINI_FILE'  => '$ARCHIVE_ROOT/$YY/$MM/$DD/$HH/SURFXINI.$SURFEX_OUTPUT_FORMAT',
   'INT_BDFILE'     => '$ARCHIVE_ROOT/$YY/$MM/$DD/$HH/ELSCF${CNMEXP}ALBC@NNN@',
   'BDDIR'      => '$HM_DATA/../'.$EXP.'/$BDLIB/$DOMAIN',
   'OBDIR'      => '$HM_DATA/../'.$EXP.'/observations/$DOMAIN',
   'CLIMDIR'        => '$HM_DATA/../'.$EXP.'/climate/$DOMAIN/$PHYSICS',
   'SMSTASKMAX'     => '-1',
   'ARCHIVE_ECMWF'  => 'no',
  },

  'realin' => {
   'BDDIR'      => '/opt/metdata/harmonie_testbed/40h1/$BDLIB/$DOMAIN',
   'OBDIR'      => '/opt/metdata/harmonie_testbed/40h1/observations/$DOMAIN',
   'JBDIR'      => '/opt/metdata/harmonie_testbed/40h1/jb_data',
  },

  'reaserve' => {
   'BDDIR'      => '/data/nwp/harmonie_testbed/40h1/$BDLIB/$DOMAIN',
   'OBDIR'      => '/data/nwp/harmonie_testbed/40h1/observations/$DOMAIN',
   'JBDIR'      => '/data/nwp/harmonie_testbed/40h1/jb_data',
  },

  'godset' => {
   'BDDIR'      => '$HOME/testdata/testbed_data/38h1/$BDLIB/',
   'OBDIR'      => '$HOME/testdata/testbed_data/38h1/observations/',
   'JBDIR'      => '$HOME/testdata/testbed_data/38h1/jbdata',
  },
  'pc4384' => {
   'BDDIR'      => '/disk1/HARMONIE/TESTBED_DATA/38h1/$BDLIB/',
   'OBDIR'      => '/disk1/HARMONIE/TESTBED_DATA/38h1/observations/',
   'JBDIR'      => '/disk1/HARMONIE/TESTBED_DATA/38h1/jbdata',
  },
  'pc4495' => {
   'BDDIR'      => '/disk1/testbed_data/38h1/$BDLIB/',
   'OBDIR'      => '/disk1/testbed_data/38h1/observations/',
   'JBDIR'      => '/disk1/testbed_data/38h1/jbdata',
   'SMSTASKMAX'=> '2',
  },
  'pc4161' => {
   'BDDIR'      => '/disk1/HM_const/testbed_data/38h1/$BDLIB/',
   'OBDIR'      => '/disk1/HM_const/testbed_data/38h1/observations/',
   'JBDIR'      => '/disk1/HM_const/testbed_data/38h1/jbdata',
   'SMSTASKMAX' => '2',
  },
 );

unless ( exists $host_defs{$host} ) { $host_defs{$host}=$host_defs{default}; } ;
 # Merge host definitions with default
 if ( $host ne "default" ){
   for my $role ( sort keys %{ $host_defs{'default'} } ) {
     unless ( exists  $host_defs{$host}{$role} ) {
        $host_defs{$host}{$role}=$host_defs{'default'}{$role} ;
      } ;
   } ;
 }

 # Default settings
 unless ( exists $host_defs{$host}{'DTG'} )           { $host_defs{$host}{'DTG'}           = $dtg ; } ;
 unless ( exists $host_defs{$host}{'DTGEND'} )        { $host_defs{$host}{'DTGEND'}        = $dtgend ; } ;
 unless ( exists $host_defs{$host}{'DOMAIN'} )        { $host_defs{$host}{'DOMAIN'}        = $NESTED_1WAY ; } ;
 unless ( exists $host_defs{$host}{'VLEV'} )          { $host_defs{$host}{'VLEV'}          = $VLEV ; } ;
 unless ( exists $host_defs{$host}{'CLIMDIR'} )       { $host_defs{$host}{'CLIMDIR'}       = $CLIMDIR ; } ;
 unless ( exists $host_defs{$host}{'DECOMPOSITION'} ) { $host_defs{$host}{'DECOMPOSITION'} = $DECOMPOSITION ; } ;


 my %test_defs;
 # Merge host specific settings to the chosen configuration
 for my $role ( sort keys %{ $host_defs{$host} } ) {
     unless ( exists  $test_defs{$config}{$role} ) {
        $test_defs{$config}{$role}=$host_defs{$host}{$role} ;
     } ;
 } ;

 # Possibe configuration deviations
 ###########################################################################################################################
 # AROME deviations                                                                                                        #
 ###########################################################################################################################
 $test_defs{'AROME_CLIMSIM'}{'DTG'}     = '2012053100';
 $test_defs{'AROME_CLIMSIM'}{'DTGEND'}  = '2012060200';

 # AROME 3DVAR
 $test_defs{'AROME_3DVAR'}{'config'}  = 'AROME_3DVAR' ;
 $test_defs{'AROME_3DVAR'}{'DOMAIN'}  = 'IRELAND150';

 # ALARO 3DVAR
 $test_defs{'ALARO_3DVAR'}{'config'}  = 'ALARO_3DVAR' ;
 $test_defs{'ALARO_3DVAR'}{'DOMAIN'}  = 'IRELAND150';

 # AROME SURFEX 2 patches
 $test_defs{'AROME_3DVAR_2P'}{'config'}       = 'AROME_3DVAR' ;
 $test_defs{'AROME_3DVAR_2P'}{'NPATCH'}       = '2' ;
 $test_defs{'AROME_3DVAR_2P'}{'LISBA_CANOPY'} = '.FALSE.' ;
 $test_defs{'AROME_3DVAR_2P'}{'CLIMDIR'}      = '$HM_DATA/../'.$EXP.'/climate/$DOMAIN/2P';
 $test_defs{'AROME_3DVAR_2P'}{'OBSMONITOR'}   = 'no' ;

 # AROME -> AROME_BD_ARO
 $test_defs{'AROME_BD_ARO_2P'}{'config'}     = 'AROME_3DVAR' ;
 $test_defs{'AROME_BD_ARO_2P'}{'NPATCH'}      = '2' ;
 $test_defs{'AROME_BD_ARO_2P'}{'LISBA_CANOPY'} = '.FALSE.' ;
 $test_defs{'AROME_BD_ARO_2P'}{'CLIMDIR'}    = '$HM_DATA/../'.$EXP.'/climate/$DOMAIN/2P';
 $test_defs{'AROME_BD_ARO_2P'}{'DOMAIN'}     = $NESTED_2WAY;
 $test_defs{'AROME_BD_ARO_2P'}{'BDLIB'}      = 'AROME_3DVAR_2P' ;
 $test_defs{'AROME_BD_ARO_2P'}{'HOST_MODEL'} = 'aro' ;
 $test_defs{'AROME_BD_ARO_2P'}{'HOST_SURFEX'}= 'yes' ;
 $test_defs{'AROME_BD_ARO_2P'}{'SURFEX_PREP'}= 'yes' ;
 $test_defs{'AROME_BD_ARO_2P'}{'SURFEX_INPUT_FORMAT'}= 'fa' ;
 $test_defs{'AROME_BD_ARO_2P'}{'BDINT'}      = '3' ;
 $test_defs{'AROME_BD_ARO_2P'}{'BDCYCLE'}    = '3' ;
 $test_defs{'AROME_BD_ARO_2P'}{'BDSTRATEGY'} = 'same_forecast' ;
 $test_defs{'AROME_BD_ARO_2P'}{'ANAATMO'}    = 'none' ;
 $test_defs{'AROME_BD_ARO_2P'}{'ANASURF'}    = 'none' ;
 $test_defs{'AROME_BD_ARO_2P'}{'BDCLIM'}     = '$HM_DATA/../'.$EXP.'/climate/'.$NESTED_1WAY.'/2P/' ;
 $test_defs{'AROME_BD_ARO_2P'}{'BDDIR'}      = '$HM_DATA/../'.$EXP.'/archive_AROME_3DVAR_2P/@YYYY@/@MM@/@DD@/@HH@/';

 # AROME 4DVAR
 $test_defs{'AROME_4DVAR'}{'config'}         = 'AROME_4DVAR' ;
 $test_defs{'AROME_4DVAR'}{'ANAATMO'}        = '4DVAR' ;
 $test_defs{'AROME_4DVAR'}{'DOMAIN'}         = 'SCANDINAVIA' ;
 $test_defs{'AROME_4DVAR'}{'VLEV'}           = 'HIRLAM_60' ;
 $test_defs{'AROME_4DVAR'}{'OBSMONITOR'}     = 'plotlog' ;
 $test_defs{'AROME_4DVAR'}{'DTG'}            = '2017093021';
 $test_defs{'AROME_4DVAR'}{'DTGEND'}         = '2017100100';
 $test_defs{'AROME_4DVAR'}{'LL_LIST'}        = '3' ;
 $test_defs{'AROME_4DVAR'}{'HWRITUPTIMES'}   = '"00-06:1"' ;
 $test_defs{'AROME_4DVAR'}{'SWRITUPTIMES'}   = '"00-06:1"' ;

 # AROME MUSC
 $test_defs{'AROME_MUSC'}{'config'}     = 'AROME';
 $test_defs{'AROME_MUSC'}{'ANAATMO'}    = 'none' ;
 $test_defs{'AROME_MUSC'}{'ANASURF'}    = 'none' ;
 $test_defs{'AROME_MUSC'}{'PLAYFILE'}   = 'musc' ;
 $test_defs{'AROME_MUSC'}{'HOST_MODEL'} = 'aro'  ;
 $test_defs{'AROME_MUSC'}{'HOST_SURFEX'}= 'yes'  ;
 $test_defs{'AROME_MUSC'}{'DOMAIN'}     = 'MUSC' ;
 $test_defs{'AROME_MUSC'}{'BDSTRATEGY'} = 'available' ;
 $test_defs{'AROME_MUSC'}{'BDDIR'}      = '$HM_DATA/../'.$EXP.'/archive_AROME/@YYYY@/@MM@/@DD@/@HH@/';
 $test_defs{'AROME_MUSC'}{'BDCLIM'}     = $host_defs{$host}{'CLIMDIR'} ;
 $test_defs{'AROME_MUSC'}{'BDCLIM'}     =~ s/\$DOMAIN/$NESTED_1WAY/;
 $test_defs{'AROME_MUSC'}{'SURFEX_INPUT_FORMAT'} = 'fa' ;
 $test_defs{'AROME_MUSC'}{'SURFEX_LSELECT'} = 'no' ;

 # HarmonEPS
 $test_defs{'HarmonEPS'}{'config'}         = 'AROME' ;
 $test_defs{'HarmonEPS'}{'description'}    = 'Basic HARMONIE EPS forecast' ;
 $test_defs{'HarmonEPS'}{'IO_SERVER'}      = 'yes' ;
 $test_defs{'HarmonEPS'}{'IO_SERVER_BD'}   = 'yes' ;
 $test_defs{'HarmonEPS'}{'ENSMSEL'}        = '0-3' ;
 $test_defs{'HarmonEPS'}{'ENSINIPERT'}     = 'bnd' ;
 $test_defs{'HarmonEPS'}{'PERTSURF'}       = 'model' ;
 $test_defs{'HarmonEPS'}{'DFI'}            = 'none' ;
 $test_defs{'HarmonEPS'}{'LL_LIST'}        = '06' ;
 $test_defs{'HarmonEPS'}{'OBSMONITOR'}     = 'no' ;
 $test_defs{'HarmonEPS'}{'HOST_MODEL'}     = 'ifs' ;
 $test_defs{'HarmonEPS'}{'BDSTRATEGY'}     = 'simulate_operational' ;
 $test_defs{'HarmonEPS'}{'PLAYFILE'}       = 'harmonie' ;
 $test_defs{'HarmonEPS'}{'CLIMDIR'}        = '$HM_DATA/../'.$EXP.'/climate/$DOMAIN/EPS';
 $test_defs{'HarmonEPS'}{'INT_SINI_FILE'}  = '$WRK/SURFXINI.$SURFEX_OUTPUT_FORMAT';
 $test_defs{'HarmonEPS'}{'INT_BDFILE'}     = '$WRK/ELSCF${CNMEXP}ALBC@NNN@';
 $test_defs{'HarmonEPS'}{'USE_SMSTASKMAX'} =  $host_defs{$host}{'SMSTASKMAX'};
 $test_defs{'HarmonEPS'}{'PFFULLWTIMES' }  = '00' ;
 $test_defs{'HarmonEPS'}{'VERITIMES' }     = '00-60:1' ;
 
 my $bddir=$host_defs{$host}{'BDDIR'}.'/mbr000';
 my $obdir=$host_defs{$host}{'OBDIR'}.'/mbr000';
 $test_defs{'AROME_EPS_COMP'}{'config'}     = 'AROME_3DVAR' ;
 $test_defs{'AROME_EPS_COMP'}{'description'}= 'AROME EPS control comparison' ;
 $test_defs{'AROME_EPS_COMP'}{'DFI'}        = 'none' ;
 $test_defs{'AROME_EPS_COMP'}{'LL_LIST'}      = '6' ;
 $test_defs{'AROME_EPS_COMP'}{'HOST_MODEL'} = 'ifs' ;
 $test_defs{'AROME_EPS_COMP'}{'BDSTRATEGY'} = $test_defs{'HarmonEPS'}{'BDSTRATEGY'} ;
 $test_defs{'AROME_EPS_COMP'}{'BDDIR'}      = $bddir ;
 $test_defs{'AROME_EPS_COMP'}{'OBDIR'}      = $obdir ;

 $bddir=$host_defs{$host}{'BDDIR'}.'/mbr001';
 $obdir=$host_defs{$host}{'OBDIR'}.'/mbr001';
 $test_defs{'ALARO_EPS_COMP'}{'config'}     = 'ALARO_3DVAR' ;
 $test_defs{'ALARO_EPS_COMP'}{'description'}= 'ALARO EPS control comparison' ;
 $test_defs{'ALARO_EPS_COMP'}{'DFI'}        = 'none' ;
 $test_defs{'ALARO_EPS_COMP'}{'LL_LIST'}      = '6' ;
 $test_defs{'ALARO_EPS_COMP'}{'HOST_MODEL'} = 'ifs' ;
 $test_defs{'ALARO_EPS_COMP'}{'BDSTRATEGY'} = $test_defs{'HarmonEPS'}{'BDSTRATEGY'} ;
 $test_defs{'ALARO_EPS_COMP'}{'BDDIR'}      = $bddir ;
 $test_defs{'ALARO_EPS_COMP'}{'OBDIR'}      = $obdir ;

 # AROME -> AROME_BD_ARO 
 $test_defs{'AROME_BD_ARO'}{'config'}     = 'AROME' ;
 $test_defs{'AROME_BD_ARO'}{'DOMAIN'}     = $NESTED_2WAY;
 $test_defs{'AROME_BD_ARO'}{'BDLIB'}      = 'AROME' ;
 $test_defs{'AROME_BD_ARO'}{'HOST_MODEL'} = 'aro' ;
 $test_defs{'AROME_BD_ARO'}{'HOST_SURFEX'}= 'yes' ;
 $test_defs{'AROME_BD_ARO'}{'SURFEX_PREP'}= 'yes' ;
 $test_defs{'AROME_BD_ARO'}{'SURFEX_INPUT_FORMAT'}= 'fa' ;
 $test_defs{'AROME_BD_ARO'}{'BDINT'}      = '3' ;
 $test_defs{'AROME_BD_ARO'}{'BDCYCLE'}    = '3' ;
 $test_defs{'AROME_BD_ARO'}{'BDSTRATEGY'} = 'same_forecast' ;
 $test_defs{'AROME_BD_ARO'}{'ANAATMO'}    = 'none' ;
 $test_defs{'AROME_BD_ARO'}{'ANASURF'}    = 'none' ;
 $test_defs{'AROME_BD_ARO'}{'BDCLIM'}     = '$HM_DATA/../'.$EXP.'/climate/'.$NESTED_1WAY.'/arome/' ;
 $test_defs{'AROME_BD_ARO'}{'BDDIR'}      = '$HM_DATA/../'.$EXP.'/archive_'. $test_defs{'AROME_BD_ARO'}{'config'}.'/@YYYY@/@MM@/@DD@/@HH@/';
 $test_defs{'AROME_BD_ARO'}{'TFLAG'}    = 'min' ;
 $test_defs{'AROME_BD_ARO'}{'HWRITUPTIMES'}    = '0-360:180';
 $test_defs{'AROME_BD_ARO'}{'PWRITUPTIMES'}    = '0-360:15';
 $test_defs{'AROME_BD_ARO'}{'VERITIMES'}       = '0-360:15';
 $test_defs{'AROME_BD_ARO'}{'SFXFULLTIMES'}    = '0-360:180';

 # ALARO_NONE -> AROME_NONE_BD_ALA_NONE
 $test_defs{'AROME_NONE_BD_ALA_NONE'}{'config'}     = 'AROME' ;
 $test_defs{'AROME_NONE_BD_ALA_NONE'}{'ANAATMO'}    = 'none' ;
 $test_defs{'AROME_NONE_BD_ALA_NONE'}{'ANASURF'}    = 'none' ;
 $test_defs{'AROME_NONE_BD_ALA_NONE'}{'DOMAIN'}     = $NESTED_2WAY;
 $test_defs{'AROME_NONE_BD_ALA_NONE'}{'BDLIB'}      = 'ALARO_NONE' ;
 $test_defs{'AROME_NONE_BD_ALA_NONE'}{'HOST_MODEL'} = 'ala' ;
 $test_defs{'AROME_NONE_BD_ALA_NONE'}{'HOST_SURFEX'}= 'yes' ;
 $test_defs{'AROME_NONE_BD_ALA_NONE'}{'BDINT'}      = '1' ;
 $test_defs{'AROME_NONE_BD_ALA_NONE'}{'BDSTRATEGY'} = 'available' ;
 $test_defs{'AROME_NONE_BD_ALA_NONE'}{'BDCLIM'}     = '$HM_DATA/../'.$EXP.'/climate/'.$NESTED_1WAY ;
 $test_defs{'AROME_NONE_BD_ALA_NONE'}{'BDDIR'}      = '$HM_DATA/../'.$EXP.'/archive_ALARO_NONE/@YYYY@/@MM@/@DD@/@HH@/';

 # AROME_NONE -> AROME_NONE_BD_IFS_ARO_NONE
 $test_defs{'AROME_NONE_BD_ARO_NONE'}{'config'}     = 'AROME' ;
 $test_defs{'AROME_NONE_BD_ARO_NONE'}{'ANAATMO'}    = 'none' ;
 $test_defs{'AROME_NONE_BD_ARO_NONE'}{'ANASURF'}    = 'none' ;
 $test_defs{'AROME_NONE_BD_ARO_NONE'}{'DOMAIN'}     = $NESTED_2WAY;
 $test_defs{'AROME_NONE_BD_ARO_NONE'}{'BDLIB'}      = 'AROME_NONE' ;
 $test_defs{'AROME_NONE_BD_ARO_NONE'}{'HOST_MODEL'} = 'aro' ;
 $test_defs{'AROME_NONE_BD_ARO_NONE'}{'HOST_SURFEX'}= 'yes' ;
 $test_defs{'AROME_NONE_BD_ARO_NONE'}{'BDINT'}      = '1' ;
 $test_defs{'AROME_NONE_BD_ARO_NONE'}{'BDSTRATEGY'} = 'available' ;
 $test_defs{'AROME_NONE_BD_ARO_NONE'}{'BDCLIM'}     = '$HM_DATA/../'.$EXP.'/climate/'.$NESTED_1WAY ;
 $test_defs{'AROME_NONE_BD_ARO_NONE'}{'BDDIR'}      = '$HM_DATA/../'.$EXP.'/archive_AROME_NONE/@YYYY@/@MM@/@DD@/@HH@/';

 # ALARO_3DVAR -> AROME_BD_ALA
 $test_defs{'AROME_BD_ALA'}{'config'}     = 'AROME' ;
 $test_defs{'AROME_BD_ALA'}{'DOMAIN'}     = $NESTED_2WAY;
 $test_defs{'AROME_BD_ALA'}{'BDLIB'}      = 'ALARO' ;
 $test_defs{'AROME_BD_ALA'}{'HOST_MODEL'} = 'ala' ;
 $test_defs{'AROME_BD_ALA'}{'HOST_SURFEX'}= 'yes' ;
 $test_defs{'AROME_BD_ALA'}{'SURFEX_PREP'}= 'yes' ;
 $test_defs{'AROME_BD_ALA'}{'SURFEX_INPUT_FORMAT'}= 'fa' ;
 $test_defs{'AROME_BD_ALA'}{'BDINT'}      = '3' ;
 $test_defs{'AROME_BD_ALA'}{'BDCYCLE'}    = '3' ;
 $test_defs{'AROME_BD_ALA'}{'BDSTRATEGY'} = 'same_forecast' ;
 $test_defs{'AROME_BD_ALA'}{'ANAATMO'}    = 'none' ;
 $test_defs{'AROME_BD_ALA'}{'ANASURF'}    = 'none' ;
 $test_defs{'AROME_BD_ALA'}{'BDCLIM'}     = '$HM_DATA/../'.$EXP.'/climate/'.$NESTED_1WAY.'/alaro/' ;
 $test_defs{'AROME_BD_ALA'}{'BDDIR'}      = '$HM_DATA/../'.$EXP.'/archive_'. $test_defs{'AROME_BD_ALA'}{'BDLIB'}.'/@YYYY@/@MM@/@DD@/@HH@/';

 # ALARO_3DVAR -> AROME_BD_ALA -> AROME_BD_AROME_ALA
 $test_defs{'AROME_BD_ALA_ARO'}{'config'}     = 'AROME' ;
 $test_defs{'AROME_BD_ALA_ARO'}{'DOMAIN'}     = $NESTED_3WAY;
 $test_defs{'AROME_BD_ALA_ARO'}{'BDLIB'}      = 'AROME_BD_ALA' ;
 $test_defs{'AROME_BD_ALA_ARO'}{'HOST_MODEL'} = 'aro' ;
 $test_defs{'AROME_BD_ALA_ARO'}{'HOST_SURFEX'}= 'yes' ;
 $test_defs{'AROME_BD_ALA_ARO'}{'BDINT'}      = '1' ;
 $test_defs{'AROME_BD_ALA_ARO'}{'BDSTRATEGY'} = 'available' ;
 $test_defs{'AROME_BD_ALA_ARO'}{'BDCLIM'}     = '$HM_DATA/../'.$EXP.'/climate/'.$NESTED_2WAY ;
 $test_defs{'AROME_BD_ALA_ARO'}{'BDDIR'}      = '$HM_DATA/../'.$EXP.'/archive_AROME_BD_ALA/@YYYY@/@MM@/@DD@/@HH@/';

 # AROME_EKF
 $test_defs{'AROME_EKF'}{'config'}                                = 'AROME' ;
 $test_defs{'AROME_EKF'}{'ANAATMO'}                               = 'blending' ;
 $test_defs{'AROME_EKF'}{'ANASURF'}                               = 'CANARI_EKF_SURFEX' ;
 $test_defs{'AROME_EKF'}{'HWRITUPTIMES'}                          = '0-12:1' ;
 $test_defs{'AROME_EKF'}{'CONVERTFA'}                             = 'yes' ;

 # AROME_JB
 $test_defs{'AROME_JB'}{'INT_BDFILE'}     = '$WRK/ELSCF${CNMEXP}ALBC@NNN@';

 $test_defs{'AROME_1D'}{'config'}         = 'AROME' ;
 $test_defs{'AROME_1D'}{'DECOMPOSITION'}  = '1D' ;
 $test_defs{'AROME_1D'}{'IO_SERVER'}      = 'yes' ;
 $test_defs{'AROME_1D'}{'IO_SERVER_BD'}   = 'yes' ;

 $test_defs{'AROME_2D'}{'config'}         = 'AROME' ;
 $test_defs{'AROME_2D'}{'DECOMPOSITION'}  = '2D' ;

 $test_defs{'AROME_NONE'}{'config'}  = 'AROME' ;
 $test_defs{'AROME_NONE'}{'ANAATMO'} = 'none' ;
 $test_defs{'AROME_NONE'}{'ANASURF'} = 'none' ;

 $test_defs{'AROME_NONE_2D'}{'config'}        = 'AROME' ;
 $test_defs{'AROME_NONE_2D'}{'DECOMPOSITION'} = '2D' ;
 $test_defs{'AROME_NONE_2D'}{'ANAATMO'}       = 'none' ;
 $test_defs{'AROME_NONE_2D'}{'ANASURF'}       = 'none' ;

 ###########################################################################################################################
 # ALARO deviations                                                                                                        #
 ###########################################################################################################################
 $test_defs{'ALARO_MUSC'}{'config'}     = 'ALARO' ;
 $test_defs{'ALARO_MUSC'}{'ANAATMO'}    = 'none' ;
 $test_defs{'ALARO_MUSC'}{'ANASURF'}    = 'none' ;
 $test_defs{'ALARO_MUSC'}{'PLAYFILE'}   = 'musc' ;
 $test_defs{'ALARO_MUSC'}{'HOST_MODEL'} = 'ala' ;
 $test_defs{'ALARO_MUSC'}{'HOST_SURFEX'}= 'yes' ;
 $test_defs{'ALARO_MUSC'}{'DOMAIN'}     = 'MUSC' ;
 $test_defs{'ALARO_MUSC'}{'BDSTRATEGY'} = 'available' ;
 $test_defs{'ALARO_MUSC'}{'BDDIR'}      = '$HM_DATA/../'.$EXP.'/archive_ALARO/@YYYY@/@MM@/@DD@/@HH@/';
 $test_defs{'ALARO_MUSC'}{'BDCLIM'}     = $host_defs{$host}{'CLIMDIR'} ;
 $test_defs{'ALARO_MUSC'}{'BDCLIM'}     =~ s/\$DOMAIN/$NESTED_1WAY/;
 $test_defs{'ALARO_MUSC'}{'SURFEX_INPUT_FORMAT'} = 'fa' ;
 $test_defs{'ALARO_MUSC'}{'SURFEX_LSELECT'} = 'no' ;

 $test_defs{'ALARO_1D'}{'config'}         = 'ALARO' ;
 $test_defs{'ALARO_1D'}{'DECOMPOSITION'}  = '1D' ;
 $test_defs{'ALARO_1D'}{'IO_SERVER'}      = 'yes' ;

 $test_defs{'ALARO_MF_60'}{'config'}  = 'ALARO' ;
 $test_defs{'ALARO_MF_60'}{'VLEV'}    = 'MF_60' ;

 $test_defs{'ALARO_OLD'}{'config'}  = 'ALARO' ;
 $test_defs{'ALARO_OLD'}{'SURFACE'} = 'old_surface';
 $test_defs{'ALARO_OLD'}{'ANASURF'} = 'CANARI';

 $test_defs{'ALARO_3DVAR_OLD'}{'config'}  = 'ALARO_3DVAR' ;
 $test_defs{'ALARO_3DVAR_OLD'}{'SURFACE'} = 'old_surface';
 $test_defs{'ALARO_3DVAR_OLD'}{'ANASURF'} = 'CANARI';

 $test_defs{'ALARO1_3DVAR_OLD'}{'config'}  = 'ALARO_3DVAR' ;
 $test_defs{'ALARO1_3DVAR_OLD'}{'SURFACE'} = 'old_surface';
 $test_defs{'ALARO1_3DVAR_OLD'}{'ANASURF'} = 'CANARI';
 $test_defs{'ALARO1_3DVAR_OLD'}{'ALARO_VERSION'} = '1';

 $test_defs{'ALARO_OLD_MUSC'}{'config'}     = 'ALARO_3DVAR' ;
 $test_defs{'ALARO_OLD_MUSC'}{'SURFACE'}    = 'old_surface';
 $test_defs{'ALARO_OLD_MUSC'}{'ANAATMO'}    = 'none' ;
 $test_defs{'ALARO_OLD_MUSC'}{'ANASURF'}    = 'none' ;
 $test_defs{'ALARO_OLD_MUSC'}{'PLAYFILE'}   = 'musc' ;
 $test_defs{'ALARO_OLD_MUSC'}{'HOST_MODEL'} = 'ala' ;
 $test_defs{'ALARO_OLD_MUSC'}{'HOST_SURFEX'}= 'yes' ;
 $test_defs{'ALARO_OLD_MUSC'}{'DOMAIN'}     = 'MUSC' ;
 $test_defs{'ALARO_OLD_MUSC'}{'BDSTRATEGY'} = 'available' ;
 $test_defs{'ALARO_OLD_MUSC'}{'BDDIR'}      = '$HM_DATA/../'.$EXP.'/archive_ALARO_3DVAR_OLD/@YYYY@/@MM@/@DD@/@HH@/';
 $test_defs{'ALARO_OLD_MUSC'}{'BDCLIM'}     = $host_defs{$host}{'CLIMDIR'} ;
 $test_defs{'ALARO_OLD_MUSC'}{'BDCLIM'}     =~ s/\$DOMAIN/$NESTED_1WAY/;
 $test_defs{'ALARO_OLD_MUSC'}{'SURFEX_INPUT_FORMAT'} = 'fa' ;

 # ALARO_EKF
 $test_defs{'ALARO_EKF'}{'config'}        = 'ALARO' ;
 $test_defs{'ALARO_EKF'}{'ANAATMO'}       = 'blending' ;
 $test_defs{'ALARO_EKF'}{'ANASURF'}       = 'CANARI_EKF_SURFEX' ;

 $test_defs{'ALARO_NH_1D'}{'config'}               = 'ALARO' ;
 $test_defs{'ALARO_NH_1D'}{'DYNAMICS'}             = 'nh' ;
 $test_defs{'ALARO_NH_1D'}{'SURFACE'}              = 'surfex';
 $test_defs{'ALARO_NH_1D'}{'DECOMPOSITON'}         = '1D';

 $test_defs{'ALARO_NH_2D'}{'config'}               = 'ALARO' ;
 $test_defs{'ALARO_NH_2D'}{'DYNAMICS'}             = 'nh' ;
 $test_defs{'ALARO_NH_2D'}{'DECOMPOSITON'}         = '2D';

 $test_defs{'ALARO_2D'}{'config'}                  = 'ALARO' ;
 $test_defs{'ALARO_2D'}{'DECOMPOSITON'}            = '2D';

 $test_defs{'ALARO_NONE'}{'config'}  = 'ALARO' ;
 $test_defs{'ALARO_NONE'}{'ANAATMO'} = 'none' ;
 $test_defs{'ALARO_NONE'}{'ANASURF'} = 'none' ;

 #
 # Set the configuration
 # List available configurations if the requested is not recognized
 my ($domain,$vertlev);
 if ( defined($test_defs{$config}{'DOMAIN'})) {
   $domain=$test_defs{$config}{'DOMAIN'};
 }else{
   $domain="undefined";
 }
 if ( defined($test_defs{$config}{'VLEV'})) {
   $vertlev=$test_defs{$config}{'VLEV'};
 }else{
   $vertlev="undefined";
 }

 my %config_defs;
 my $standard_conf;
 my $mitproc;
 # If a default config is defined, we need to find and merge this
 if ( defined($test_defs{$config}{'config'})) {
   $standard_conf=$test_defs{$config}{'config'};
 }else{
   $standard_conf=$config;
 }
 if ( $get_val eq "undefined" ) { print " Using the configuration $config\n\n";}
 %config_defs=&Harmonie_configurations($standard_conf,$domain,$vertlev,$mode);
 # Merge the test definition and default configuration
 for my $role ( sort keys %{ $config_defs{$standard_conf} } ) {
   unless ( exists  $test_defs{$config}{$role} ) {
      $test_defs{$config}{$role}=$config_defs{$standard_conf}{$role} ;
   } ;
 } ;

 unless ( exists  $test_defs{$config}{'PLAYFILE'} ) { $test_defs{$config}{'PLAYFILE'}='harmonie' ; } ;

 #
 # Return the requested value if -g is given
 unless ( $get_val eq "undefined" ) {
   unless ( exists  $test_defs{$config}{$get_val} ) { die "Value $get_val not defined for $config \n"; } ;
   print "$test_defs{$config}{$get_val}\n";
   exit 0 ;
 } ;

 #
 # Get current revision
 #

 open HM, "< config-sh/hm_rev" or die "cannot open config-sh/hm_rev \n";
 my $hm_rev=<HM>;
 close HM;
 chomp $hm_rev;

my $HM_WD=$ENV{HM_WD} ;
 if ( !defined($HM_WD)) {
   print "ERROR: HM_WD is not defined!\n";
   exit;
 }

 #
 # Update harmonie.pm if requested
 #

 my @exclude=("description","config","harmonie.pm",
              "DTG","DTGEND","DECOMPOSITION", "SMSTASKMAX") ;
 
 if ( exists($test_defs{$config}{'harmonie.pm'} )) {
  @exclude = (@exclude,&update_harmonie_pm($HM_WD));
 }


 #
 # Update include.ass and config_exp.h
 #
 
 my $add_missing = 0;

 for my $config_file ('scr/include.ass','sms/config_exp.h') {

  @exclude = (@exclude,&update_settings($config_file,$HM_WD));
  $add_missing = 1;

 } ;

 #
 # Copy the host job submission details in Env_submit if any information has been given and was well defined
 #

 unless ( $default_submit ) {
   my @submit_not_defined;
   if (( exists($test_defs{$config}{'DECOMPOSITION'}) ) ){
       unless ( $test_defs{$config}{'Env_submit'}{'nprocx'} ){
     $test_defs{$config}{'Env_submit'}{'nprocx'}=&submission_host_defs($host,$test_defs{$config}{'DOMAIN'},$test_defs{$config}{'DECOMPOSITION'},'nprocx');
       }
       unless ( $test_defs{$config}{'Env_submit'}{'nprocy'} ){
     $test_defs{$config}{'Env_submit'}{'nprocy'}=&submission_host_defs($host,$test_defs{$config}{'DOMAIN'},$test_defs{$config}{'DECOMPOSITION'},'nprocy');
       }

     if ( exists($test_defs{$config}{'IO_SERVER'}) ) {
      if ( $test_defs{$config}{'IO_SERVER'} eq "yes" ) {
        unless ( $test_defs{$config}{'Env_submit'}{'nproc_io'} ){
         $test_defs{$config}{'Env_submit'}{'nproc_io'}=&submission_host_defs($host,$test_defs{$config}{'DOMAIN'},$test_defs{$config}{'DECOMPOSITION'},'nproc_io');
        }
      }
     }
     for my $var ( sort keys %{ $test_defs{$config}{'Env_submit'} } ) {
       if ( $test_defs{$config}{'Env_submit'}{$var} eq 'submission_details_undefined'){
         @submit_not_defined="HOST=$host CONFIG=$config VAR=$var";
       }
   }

   # Alter nproc_festat
   $test_defs{$config}{'Env_submit'}{'nproc_festat'}=&submission_host_defs($host,$test_defs{$config}{'DOMAIN'},$test_defs{$config}{'DECOMPOSITION'},'nproc_festat');

     if ( @submit_not_defined > 0 ){
       print "Env_submit can not be altered because the following undefined values were found:\n";
       for my $undef_line ( @submit_not_defined  ){
         print "$undef_line\n";
       }
       exit 1;
     } else {
       my $submit_input=$HM_WD."/Env_submit";
       my $submit_output="$ENV{PWD}/Env_submit";

       open SI, "< $submit_input" or die "cannot open $submit_input \n";
       open SO, "> $submit_output" or die "cannot open $submit_output \n";

       print "\n\n";
       print " Input $submit_input \n";
       print " Output $submit_output \n\n";


       #
       # Read the input file and change requested variables
       #

       while ( <SI> ) {
         chomp ;
         for my $role ( sort keys %{ $test_defs{$config}{'Env_submit'} } ) {
           if ( $_ =~ /\$$role\s*=/ ) {
             my @tmp = split(' #',$_) ;
             $tmp[0]=~s/\s+//g;                     # Remove possible blanks in string
             my @subcheck = split('=',$tmp[0]);
             if ( "\$$role" eq "$subcheck[0]" ) {
                print SO "#OLD: $_\n";
                print " Change $tmp[0] to \$$role=$test_defs{$config}{'Env_submit'}{$role} \n";
                $tmp[0]="\$$role=$test_defs{$config}{'Env_submit'}{$role};";
                $_=$tmp[0];
             };
           };
         };
         print SO "$_\n";
       };
       close SI ;
       close SO
     }
   }
 } else {
   print "\n Using default Env_submit\n";
 }
 #
 # Update hm_CMODS and possibly HM_EXP in the target experiment
 #

 open EO, ">> Env_system" or die "cannot open Env_system";
 print EO "hm_CMODS=$HM_WD\n";
 if ( $ENV{HM_ARC} ) { print EO "HM_EXP=$ENV{HM_ARC}/$ENV{EXP}_$config\n" ; };
 close EO ;

 #
 # Print the suggested start command
 # First we unset several environment variables to make sure they are not inherited in the 
 # child experiment
 #

 my $starter = "unset EXP HM_CLA SMSMETER HM_LIB0 CDP Env_system HM_LIB1 f_JBBAL f_JBCV JBDIR CASE ; ";
 if ( -s "config-sh/Harmonie" ){
   $starter .= "config-sh/Harmonie start HM_REV=$HM_LIB ";
 }else{
   $starter .= "$HM_LIB/config-sh/Harmonie start HM_REV=$HM_LIB ";
 }
 $starter .= "DTG=$test_defs{$config}{'DTG'} DTGBEG=$test_defs{$config}{'DTG'} DTGEND=$test_defs{$config}{'DTGEND'} ";
 $starter .= "PLAYFILE=$test_defs{$config}{'PLAYFILE'} "; 
 $starter .= "AUTOEXIT=1 SCHEDULER=$ENV{SCHEDULER} CLEAN=true " ;
 # Set SMSTASKMAX if wanted
 if ( defined($test_defs{$config}{'USE_SMSTASKMAX'}) ){
   if ( $test_defs{$config}{'USE_SMSTASKMAX'} > 0 ) {
     $starter .= "SMSTASKMAX=$test_defs{$config}{'SMSTASKMAX'} ";
   }
 }

 if ( $ENV{CONT_ON_FAILURE} ) { $starter .= "AUTOABORT=1 mSMS_WEBPORT=2 "; } ;

 print"\nStarting new experiment with:\n  $starter\n";
 my $iret=system($starter);
 exit $iret/256;

#####################################################
######### SUBMISSION DETAILS (Env_submit) #################
sub submission_host_defs{
  my $sub_host   = shift @_ ;
  my $sub_domain = shift @_ ;
  my $sub_decomp = shift @_ ;
  my $sub_var    = shift @_ ;

  my $mod_size;
  my $mod_host;
  # Default size
  $mod_size="BIG";
  if ( $sub_domain eq "TEST_11"  || $sub_domain eq "TEST_8"      || 
       $sub_domain eq "TEST_11_4DVAR" || 
       $sub_domain eq "TEST_2.5" || $sub_domain eq "TEST_11_BIG" || 
       $sub_domain eq "IRELAND150" || $sub_domain eq "MUSC" ) {
    $mod_size="SMALL";
  }
  # Modify if host is similar to others
  $mod_host=$sub_host;

  # Set PEs depending on domain and if 1D or 2D decomposition
  my %submission_test_defs = (

    'default' => {
       # Set PEs depending on domain
       'SMALL' => {
         '1D' => {
           'nprocx' =>  '1',
           'nprocy' =>  '4',
           'nproc_io' =>  '2',
           'nproc_festat' =>  '1',
         },
         '2D' => {
           'nprocx' =>  '2',
           'nprocy' =>  '2',
           'nproc_io' =>  '2',
           'nproc_festat' =>  '1',
         },
       },
       'BIG' => {
         '1D' => {
           'nprocx' =>  '1',
           'nprocy' => '40',
         },
         '2D' => {
           'nprocx' =>  '5',
           'nprocy' =>  '8',
         },
       },
    },
    'realin' => {
       # Set PEs depending on domain
       'SMALL' => {
         '1D' => {
           'nprocx' =>  '1',
           'nprocy' =>  '2',
           'nproc_io' =>  '1',
         },
         '2D' => {
           'nprocx' =>  '1',
           'nprocy' =>  '2',
           'nproc_io' =>  '1',
         },
       },
       'BIG' => {
         '1D' => {
           'nprocx' =>  '1',
           'nprocy' =>  '2',
         },
         '2D' => {
           'nprocx' =>  '1',
           'nprocy' =>  '2',
         },
       },
    },
    'reaserve' => {
       # Set PEs depending on domain
       'SMALL' => {
         '1D' => {
           'nprocx' =>  '1',
           'nprocy' =>  '4',
           'nproc_io' =>  '2',
         },
         '2D' => {
           'nprocx' =>  '2',
           'nprocy' =>  '2',
           'nproc_io' =>  '2',
         },
       },
       'BIG' => {
         '1D' => {
           'nprocx' =>  '1',
           'nprocy' =>  '8',
           'nproc_io' =>  '2',
         },
         '2D' => {
           'nprocx' =>  '2',
           'nprocy' =>  '4',
           'nproc_io' =>  '2',
         },
       },
    },
    'godset' => {
       # Set PEs depending on domain
       'SMALL' => {
         '1D' => {
           'nprocx'   =>  '1',
           'nprocy'   =>  '4',
           'nproc_io' =>  '2',
         },
         '2D' => {
           'nprocx'   =>  '2',
           'nprocy'   =>  '2',
           'nproc_io' =>  '2',
         },
       },
       'BIG' => {
         '1D' => {
           'nprocx'   =>  '1',
           'nprocy'   =>  '64',
           'nproc_io' =>  '2',
         },
         '2D' => {
           'nprocx'   =>  '8',
           'nprocy'   =>  '8',
           'nproc_io' =>  '2',
         },
       },
    },
    'pc4384' => {
       # Set PEs depending on domain
       'SMALL' => {
         '1D' => {
           'nprocx'   =>  '1',
           'nprocy'   =>  '4',
           'nproc_io' =>  '2',
         },
         '2D' => {
           'nprocx'   =>  '2',
           'nprocy'   =>  '2',
           'nproc_io' =>  '2',
         },
       },
       'BIG' => {
         '1D' => {
           'nprocx'   =>  '1',
           'nprocy'   =>  '64',
           'nproc_io' =>  '2',
         },
         '2D' => {
           'nprocx'   =>  '8',
           'nprocy'   =>  '8',
           'nproc_io' =>  '2',
         },
       },
    },
    'pc4495' => {
       # Set PEs depending on domain
       'SMALL' => {
         '1D' => {
           'nprocx'   =>  '1',
           'nprocy'   =>  '4',
           'nproc_io' =>  '2',
         },
         '2D' => {
           'nprocx'   =>  '2',
           'nprocy'   =>  '2',
           'nproc_io' =>  '2',
         },
       },
       'BIG' => {
         '1D' => {
           'nprocx'   =>  '1',
           'nprocy'   =>  '64',
           'nproc_io' =>  '2',
         },
         '2D' => {
           'nprocx'   =>  '8',
           'nprocy'   =>  '8',
           'nproc_io' =>  '2',
         },
       },
    },
  );  

  #
  # List available configurations if the requested is not recognized
  #
  unless ( exists $submission_test_defs{$mod_host}{$mod_size}{$sub_decomp}{$sub_var} ) {
    $mod_host = 'default' ;
  };
  unless ( exists $submission_test_defs{$mod_host}{$mod_size}{$sub_decomp}{$sub_var} ) {
    return "submission_details_undefined";
  };

  return "$submission_test_defs{$mod_host}{$mod_size}{$sub_decomp}{$sub_var}";

}

#############################################################################################
#############################################################################################
#############################################################################################

sub update_harmonie_pm () {

  my $ref = shift ;

  my $config_file = 'harmonie.pm';
  my $config_input="$ref/msms/$config_file";
  my $config_output="$ENV{PWD}/msms/$config_file";
 
  open CI, "< $config_input" or die "cannot open $config_input \n";
  open CO, "> $config_output" or die "cannot open $config_output \n";

  print "\n";
  print " Input $config_input \n";
  print " Output $config_output \n\n";

  #
  # Read the input file and change requested variables
  #

  my @exclude_add = ();
  while ( <CI> ) {
   chomp ;
   for my $role ( @{ $test_defs{$config}{$config_file} } ) {
 
     next unless ( $_ =~ /^(.*)\'$role\'( ){0,}=>/ ) ;
     next if ( $_ =~ /^(\s+)#(.*)\'$role\'( ){0,}=>/ ) ;

     $_ =~ s/((\{|\[)(.*)(\}|\]))/$test_defs{$config}{$role}/;

     print " Change $role to $test_defs{$config}{$role}\n";
     push @exclude_add, $role unless ( grep /^$role$/, @exclude_add );
   }
   print CO "$_\n";

  };

  close CI ;
  close CO ;

  return @exclude_add ;

}

#############################################################################################
#############################################################################################
#############################################################################################

sub update_settings () {

  my $config_file = shift ;
  my $ref         = shift ;

  my $config_input="$ref/$config_file";
  my $config_output="$ENV{PWD}/$config_file";
 
  open CI, "< $config_input" or die "cannot open $config_input \n";
  open CO, "> $config_output" or die "cannot open $config_output \n";

  print "\n";
  print " Input $config_input \n";
  print " Output $config_output \n\n";

  #
  # Read the input file and change requested variables
  #

  my @exclude_add = ();
  while ( <CI> ) {
   chomp ;
   for my $role ( sort keys %{ $test_defs{$config} } ) {

     next if ( grep /^$role$/, (@exclude) );
     next unless ( $_ =~ /^(.*)\b$role=/ ) ;
     next if ( $_ =~ /^(\s+)#(.*)$role=/ ) ;

     my $tmp = $_ ;
     $tmp =~ s/^(.*)($role=(.*))/$2/ ;
     ($tmp) = split(' ',$tmp);

     my ($key,$val) = split('=',$tmp);

     my @count = $val =~ /"/g;
     next if ( scalar @count eq 1 ) ; 
     $val=~ s/\$/\\\$/g;

     print " Change $tmp to $role=$test_defs{$config}{$role}\n";
     $_=~ s/$key=$val/$role=\"$test_defs{$config}{$role}\"/;
     push @exclude_add, $role unless ( grep /^$role$/, @exclude_add );
   }
   print CO "$_\n";

  };

  # Print extra settings
  if ( $add_missing ) {
   print "\n";
   for my $role ( sort keys %{ $test_defs{$config} } ) {
    next if ( grep /^$role$/, (@exclude,@exclude_add) );
    print " Add new settings $role=$test_defs{$config}{$role} \n";
    print CO "export $role=$test_defs{$config}{$role}\n";
   } ;
  } ;


  close CI ;
  close CO ;

  return @exclude_add ;

}
