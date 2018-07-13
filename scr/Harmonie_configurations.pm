#!/usr/bin/perl -w

use strict;
#
# Configurations for HARMONIE
#

sub Harmonie_configurations{
  my $config=shift;
  my $domain=shift;
  my $vertlev=shift;
  my $mode=shift;

  my %config_defs = (

    # AROME with 3D-VAR
    'AROME_3DVAR' => {
      'description' => 'Standard AROME settings with DA',
      'PHYSICS'     => 'arome',
      'DYNAMICS'    => 'nh',
      'SURFACE'     => 'surfex',
      'ANAATMO'     => '3DVAR',
      'ANASURF'     => 'CANARI_OI_MAIN',
      'DFI'         => 'none',
      'HOST_MODEL'  => 'ifs',
      'DOMAIN'      => 'DKCOEXP',
      'VLEV'        => '65',
      'BDINT'       => '3',
      'HH_LIST'      => '0-21:3',
      'BDSTRATEGY'  => 'simulate_operational',
      'ENSMSEL'     => '',
      'ENSINIPERT'  => '',
    },

    # AROME no 3D-VAR but default blending of upper air from boundaries
    'AROME' => {
      'description' => 'Standard AROME settings without upper air DA',
      'PHYSICS'     => 'arome',
      'SURFACE'     => 'surfex',
      'DYNAMICS'    => 'nh',
      'ANAATMO'     => 'blending',
      'ANASURF'     => 'CANARI_OI_MAIN',
      'DFI'         => 'none',
      'HOST_MODEL'  => 'ifs',
      'DOMAIN'      => 'DKCOEXP',
      'VLEV'        => '65',
      'BDINT'       => '3',
      'HH_LIST'      => '0-21:3',
      'BDSTRATEGY'  => 'simulate_operational',
      'ENSMSEL'     => '',
      'ENSINIPERT'  => '',
      'SURFEX_LSELECT'  => 'no',
    },

    # AROME with 4D-VAR
    'AROME_4DVAR' => {
      'description' => 'Standard AROME settings with DA',
      'DOMAIN'      => 'DKCOEXP',
      'VLEV'        => '65',
      'PHYSICS'     => 'arome',
      'DYNAMICS'    => 'nh',
      'SURFACE'     => 'surfex',
      'DFI'         => 'none',
      'LGRADSP'     => 'no',
      'LUNBC'       => 'no',
      'HARATU'      => 'no',
      'ANAATMO'     => '4DVAR',
      'ANASURF'     => 'CANARI_OI_MAIN',
      'ANASURF_MODE' => 'after',
      'HOST_MODEL'  => 'ifs',
      'SURFEX_INPUT_FORMAT'  => 'fa',
      'BDINT'       => '1',
      'HH_LIST'      => '0-21:3',
      'HWRITUPTIMES' => '"00-21:1,24-60:6"',
      'BDSTRATEGY'  => 'simulate_operational',
      'ENSMSEL'     => '',
      'ENSINIPERT'  => '',
      'SURFEX_LSELECT'  => '"no"',
    },

   # AROME Structure function derivation
   'AROME_JB' => {
     'description' => 'Derive structure functions for AROME 3DVAR',
      'ECFSLOC'     => 'ec',
      'PHYSICS'     => 'arome',
      'DYNAMICS'    => 'nh',
      'SURFACE'     => 'surfex',
      'ANAATMO'     => 'none',
      'ANASURF'     => 'none',
      'DFI'         => 'none',
      'HOST_MODEL'  => 'ifs',
      'DOMAIN'      => 'DKCOEXP',
      'VLEV'        => '65',
      'BDINT'       => '1',
      'FESTAT'      => 'yes',
      'HH_LIST'     => '00,12',
      'LL_LIST'     => '06',
      'BDSTRATEGY'  => 'enda',
      'ENSMSEL'     => '1,2,3,4',
      'ENSINIPERT'  => 'bnd',
      'OBSEXTR'     => 'none',
      'FLDEXTR'     => 'no',
      'OBSMONITOR'  => 'no',
      'harmonie.pm' => ['ENSBDMBR','ENSCTL','SLAFLAG'],
        'ENSBDMBR'    => '[1,2,3,4]',
        'ENSCTL'      => '["001","002","003","004"]',
        'SLAFLAG'     => '[0]',
    },

    # Default ALARO with blending
    'ALARO' => { 
      'description' => 'Standard ALARO settings without upper air DA',
      'PHYSICS'     => 'alaro',
      'ALARO_VERSION' => '0',
      'DYNAMICS'    => 'nh',
      'SURFACE'     => 'surfex',
      'ANAATMO'     => 'blending',
      'ANASURF'     => 'CANARI_OI_MAIN',
      'DFI'         => 'none',
      'HOST_MODEL'  => 'ifs',
      'DOMAIN'      => 'DKCOEXP',
      'VLEV'        => '65',
      'BDINT'       => '3',
      'HH_LIST'      => '0-21:3',
      'BDSTRATEGY'  => 'simulate_operational',
      'ENSMSEL'     => '',
      'ENSINIPERT'  => '',
      'SURFEX_LSELECT'  => 'no',
    },

    # AROME no 3D-VAR but default blending of upper air from boundaries
    'AROME_CLIMSIM' => {
      'description' => 'AROME climate simulation',
      'SIMULATION_TYPE' => 'climate',
      'PLAYFILE'    => 'climsim',
      'BDSTRATEGY'  => 'era',
      'PHYSICS'     => 'arome',
      'SURFACE'     => 'surfex',
      'DYNAMICS'    => 'nh',
      'ANAATMO'     => 'none',
      'ANASURF'     => 'none',
      'DFI'         => 'none',
      'HOST_MODEL'  => 'ifs',
      'DOMAIN'      => 'DKCOEXP',
      'BDINT'       => '6',
      'VLEV'        => '65',
      'BDSTRATEGY'  => 'era',
      'ENSMSEL'     => '',
      'ENSINIPERT'  => '',
    },


    # Standard ALARO 3DVAR
    'ALARO_3DVAR' => {
      'description' => 'Harmonie 3DVAR alaro',
      'PHYSICS'     => 'alaro',
      'ALARO_VERSION' => '0',
      'SURFACE'     => 'surfex',
      'DYNAMICS'    => 'nh',
      'ANAATMO'     => '3DVAR',
      'ANASURF'     => 'CANARI_OI_MAIN',
      'DFI'         => 'none',
      'HOST_MODEL'  => 'ifs',
      'DOMAIN'      => 'DKCOEXP',
      'VLEV'        => '65',
      'BDINT'       => '3',
      'HH_LIST'      => '0-21:3',
      'BDSTRATEGY'  => 'simulate_operational',
      'ENSMSEL'     => '',
      'ENSINIPERT'  => '',
    },
  ) ;

  #
  # List available configurations if the requested is not recognized
  #

  if ( ! exists $config_defs{$config} && $config ne "undefined" ) {

    print "\nCould not find configuration: $config \n";
    print "Available are:\n\n";

    for my $key ( sort keys %config_defs ) {
          print "  $key\n";
          if ( exists $config_defs{$key}{'description'} ) {
            print "   $config_defs{$key}{'description'}\n";
            delete $config_defs{$key}{'description'} ;
          };
          if ( $mode == 1 )  {
          for my $role ( sort keys %{ $config_defs{$key} } ) {
            print "     $role=$config_defs{$key}{$role}\n";
          } ;
          print "\n";
          } ;
    } ;
    if ( $mode == 2 )  {
      print "\nYou are using the Harmonie_testbed. Make sure that your testbed configuration has the hash config defined to a valid configuration.\n";
    }
    exit 1 ;
  };

  # Substitute command line arguments
  unless ( $domain eq "undefined" ) {
    $config_defs{$config}{'DOMAIN'}=$domain ;
  }
  unless ( $vertlev eq "undefined" ) {
    $config_defs{$config}{'VLEV'}=$vertlev ;
  }

  return %config_defs;
}
return 1;
