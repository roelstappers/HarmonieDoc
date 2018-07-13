#!/usr/bin/perl -w

use strict;
#
# Defined HARMONIE domains
#
# For each domain the following properties should be set
#
# TSTEP    Time step
#          optional  TSTEP_LINEAR,TSTEP_QUADRATIC,TSTEP_CUBIC : overrules TSTEP
# NLON     Number of points (x)
# NLAT     Number of points (y)
# LONC     Longitude of domain centre (degrees)
# LATC     Latitude of domain center (degrees)
# LON0     Reference longitude of the projection (degrees)
# LAT0     Reference latitude of the projection (degrees)
# GSIZE    Grid size in meters (x,y)
#

my $default_ezone=11;
my $lnoextz=".FALSE.";

sub Harmonie_domains{
  my $domain=shift;

  my %domains = (
   'TRAINING_10' =>{
      'TSTEP'  => '240',                                 # Time step
      'NLON'   => '150',                                 # Number of points (x)
      'NLAT'   => '150',                                 # Number of points (y)
      'LONC'   => '14.8',                                # Longitude of domain centre (degrees)
      'LATC'   => '51.9',                                # Latitude of domain center (degrees)
      'LON0'   => '20.0',                                # Reference longitude of the projection (degrees)
      'LAT0'   => '50.2',                                # Reference latitude of the projection (degrees)
      'GSIZE'  => '10000.',                               # Grid size in meters (x,y)
   },
   'TRAINING_2.5' =>{
      'TSTEP'  => '60',                                 # Time step
      'NLON'   => '150',                                 # Number of points (x)
      'NLAT'   => '150',                                 # Number of points (y)
      'LONC'   => '14.8',                                # Longitude of domain centre (degrees)
      'LATC'   => '51.9',                                # Latitude of domain center (degrees)
      'LON0'   => '20.0',                                # Reference longitude of the projection (degrees)
      'LAT0'   => '50.2',                                # Reference latitude of the projection (degrees)
      'GSIZE'  => '2500.',                               # Grid size in meters (x,y)
   },
   'TRAINING_2.0' =>{
      'TSTEP'  => '45',                                 # Time step
      'NLON'   => '150',                                 # Number of points (x)
      'NLAT'   => '150',                                 # Number of points (y)
      'LONC'   => '14.8',                                # Longitude of domain centre (degrees)
      'LATC'   => '51.9',                                # Latitude of domain center (degrees)
      'LON0'   => '20.0',                                # Reference longitude of the projection (degrees)
      'LAT0'   => '50.2',                                # Reference latitude of the projection (degrees)
      'GSIZE'  => '2500.',                               # Grid size in meters (x,y)
   },
   'HarmEPS_1'=>{
      'TSTEP'  => '60',                                # Time step
      'NLON'   => '450',                               # Number of points (x)
      'NLAT'   => '540',                               # Number of points (y)
      'LONC'   => '8.0',                               # Longitude of domain centre (degrees)
      'LATC'   => '51.7',                              # Latitude of domain center (degrees)
      'LON0'   => '8.0',                               # Reference longitude of the projection (degrees)
      'LAT0'   => '51.7',                              # Reference latitude of the projection (degrees)
      'GSIZE'  => '2500.',                             # Grid size in meters (x,y)
   },
   'TURKEY_2.5'=>{
      'TSTEP'  => '60',
      'NLON'   => '1000',
      'NLAT'   => '512',
      'LONC'   => '35.0',
      'LATC'   => '39.0 ',
      'LON0'   => '35.0',
      'LAT0'   => '39.0',
      'GSIZE'  => '2500.',
   },
   'CANARIAS_2.5'=>{
      'TSTEP'  => '60',                                
      'NLON'   => '576',
      'NLAT'   => '480',
      'LONC'   => '-17.5',
      'LATC'   => '29.0',
      'LON0'   => '-17.5', 
      'LAT0'   => '29.0',
      'GSIZE'  => '2500.',
   },
   'HMS_ALD_8'=>{
      'TSTEP'  => '300',
      'NLON'   => '360',
      'NLAT'   => '320',
      'LONC'   => '16.9952715802594',
      'LATC'   => '46.1050864465158',
      'LON0'   => '17.0000000000000',
      'LAT0'   => '46.2447006400000',
      'GSIZE'  => '7963.36065555735',
   },
   'MUSC'=>{
      'TSTEP'  => '60',
      'NLON'   => '4', 
      'NLAT'   => '1',
      'LONC'   => '14.0',
      'LATC'   => '59.2',
      'LON0'   => '14.0',
      'LAT0'   => '59.2',
      'GSIZE'  => '2500.', 
      'EZONE'  => '0',
      'NMSMAX' => '1',
      'NSMAX' => '0',
   },
   'SWEDEN_2.5'=>{
      'TSTEP'  => '60',                                 
      'NLON'   => '450',                                
      'NLAT'   => '648',                                
      'LONC'   => '14.0',                               
      'LATC'   => '62.3',                               
      'LON0'   => '11.0',                               
      'LAT0'   => '65.0',                               
      'GSIZE'  => '2500.',                              
   },
   'TEST_11'=>{
      'TSTEP'  => '300',
      'NLON'   => '50',                                
      'NLAT'   => '50',                                
      'LONC'   => '14.0',                              
      'LATC'   => '59.2',                              
      'LON0'   => '-10.0',                             
      'LAT0'   => '59.2',                              
      'GSIZE'  => '11000.',                            
   },
   'TEST_11_4DVAR'=>{
      'TSTEP'  => '300',
      'NLON'   => '60',                                
      'NLAT'   => '60',                                
      'LONC'   => '14.0',                              
      'LATC'   => '59.2',                              
      'LON0'   => '-10.0',                             
      'LAT0'   => '59.2',                              
      'GSIZE'  => '11000.',                            
   },
   'TEST_1'=>{
      'TSTEP'  => '30',                                
      'NLON'   => '50',                                
      'NLAT'   => '50',                                
      'LONC'   => '14.0',                              
      'LATC'   => '59.2',                              
      'LON0'   => '-10.0',                             
      'LAT0'   => '59.2',                              
      'GSIZE'  => '1000.',                             
   },
   'NORWAY_SOUTH_500'=>{
      'TSTEP'  => '30',                                
      'NLON'   => '500',                               
      'NLAT'   => '500',                               
      'LONC'   => '8.2',                               
      'LATC'   => '60.1',                              
      'LON0'   => '-20.0',                             
      'LAT0'   => '60.1',                              
      'GSIZE'  => '500.',                              
   },
   'TEST_11_BIG'=>{
      'TSTEP'  => '300',                               
      'NLON'   => '100',                               
      'NLAT'   => '100',                               
      'LONC'   => '14.0',                              
      'LATC'   => '59.2',
      'LON0'   => '-10.0',
      'LAT0'   => '59.2',
      'GSIZE'  => '11000.',
   },
   'TEST_8'=>{
      'TSTEP'  => '200',
      'NLON'   => '50',
      'NLAT'   => '50',
      'LONC'   => '14.0',
      'LATC'   => '59.2',
      'LON0'   => '-10.0',
      'LAT0'   => '59.2',
      'GSIZE'  => '8000.',
   },
   'IRELAND55'=>{
      'TSTEP'  => '120',
      'NLON'   => '300',
      'NLAT'   => '300',
      'LONC'   => '-8.5',
      'LATC'   => '54.50',
      'GSIZE'  => '5500.',
      'LON0'   => '0.0',
      'LAT0'   => '53.5',
   },
   'IRELAND150'=>{
      'TSTEP'   => '360',
      'NLON'    => '50',
      'NLAT'    => '50',
      'LONC'    => '-8.5',
      'LATC'    => '53.50',
      'GSIZE'   => '15000.',
      'LON0'    => '0.0',
      'LAT0'    => '53.5',
   },
   'IRELAND25'=>{
      'TSTEP'  => '60',
      'NLON'   => '540',
      'NLAT'   => '500',
      'LONC'   => '-7.5',
      'LATC'   => '53.50',
      'GSIZE'  => '2500.',
      'LON0'   => '5.0',
      'LAT0'   => '53.5',
   },
   'NORWAY_POLAR'=>{
      'TSTEP'  => '300',
      'NLON'   => '540',
      'NLAT'   => '450',
      'LONC'   => '-5.0',
      'LATC'   => '70.0',
      'LON0'   => '0.0',
      'LAT0'   => '90.0',
      'GSIZE'  => '16000.0',
      'NMSMAX' => '269',
      'NSMAX'  => '224',
   },
   'RCR_POLAR'=>{
      'TSTEP'  => '360',
      'NLON'   => '648',
      'NLAT'   => '540',
      'LONC'   => '-10.0',
      'LATC'   => '59.5',
      'LON0'   => '0.0',
      'LAT0'   => '90.0',
      'GSIZE'  => '16000.0',
      'NMSMAX' => '323',
      'NSMAX'  => '269',
   },
   'AROME_2.5'=>{
      'TSTEP'  => '60',
      'NLON'   => '800',
      'NLAT'   => '800',
      'LONC'   => '8.0',
      'LATC'   => '58.0',
      'LON0'   => '8.0',
      'LAT0'   => '58.0',
      'GSIZE'  => '2500.',
      'NMSMAX' => '399',
      'NSMAX'  => '399',
   },
   'TEST_2.5'=>{
      'TSTEP'  => '60',
      'NLON'   => '50',
      'NLAT'   => '50',
      'LONC'   => '14.0',
      'LATC'   => '59.2',
      'LON0'   => '-10.0',
      'LAT0'   => '59.2',
      'GSIZE'  => '2500.',
   },
   'SCANDINAVIA'=>{
      'TSTEP'  => '300',
      'NLON'   => '256',
      'NLAT'   => '288',
      'LONC'   => '14.0',
      'LATC'   => '59.2',
      'LON0'   => '-10.0',
      'LAT0'   => '59.2',
      'GSIZE'  => '11000.',
   },
   'SCANDINAVIA_ROTM'=>{
      'TSTEP'  => '300',
      'NLON'   => '256',
      'NLAT'   => '288',
      'LONC'   => '14.0',
      'LATC'   => '59.2',
      'LON0'   => '-10.0',
      'LAT0'   => '0.0',
      'GSIZE'  => '11000.',
      'export LLMRT' => '.TRUE.',
   },
   'SCANDINAVIA_5.5'=>{
      'TSTEP'  => '120',
      'NLON'   => '540',
      'NLAT'   => '600',
      'LONC'   => '14.0',
      'LATC'   => '61.0',
      'LON0'   => '-10.0',
      'LAT0'   => '60.0',
      'GSIZE'  => '5500.',
   },
   'SCANDINAVIA_25'=>{
      'TSTEP'  => '60',
      'NLON'   => '720',
      'NLAT'   => '800',
      'LONC'   => '21.0',
      'LATC'   => '62.4',
      'LON0'   => '20.0',
      'LAT0'   => '62.4',
      'GSIZE'  => '2500.',
   },
   'SWEDEN_NORTH'=>{
      'TSTEP'  => '60',
      'NLON'   => '288',
      'NLAT'   => '270',
      'LONC'   => '19.0',
      'LATC'   => '66.9',
      'LON0'   => '-13.0',
      'LAT0'   => '67.0',
      'GSIZE'  => '2500.',
   },
   'SWEDEN_SOUTH'=>{
      'TSTEP'  => '60',
      'NLON'   => '270',
      'NLAT'   => '288',
      'LONC'   => '15.0',
      'LATC'   => '58.0',
      'LON0'   => '15.0',
      'LAT0'   => '58.0',
      'GSIZE'  => '2500.',
   },
   'SWEDEN_5.5'=>{
      'TSTEP'  => '120',
      'NLON'   => '300',
      'NLAT'   => '450',
      'LONC'   => '17.4',
      'LATC'   => '61.0',
      'LON0'   => '-10.0',
      'LAT0'   => '60.0',
      'GSIZE'  => '5500.',
   },
   'FINLAND_SOUTH'=>{
      'TSTEP'  => '60',
      'NLON'   => '300',
      'NLAT'   => '300',
      'LONC'   => '25.0',
      'LATC'   => '60.0',
      'LON0'   => '0.0',
      'LAT0'   => '60.0',
      'GSIZE'  => '2500.',
   },
   'FINLAND'=>{
      'TSTEP'  => '60',
      'NLON'   => '300',
      'NLAT'   => '600',
      'LONC'   => '25.5',
      'LATC'   => '64.0',
      'LON0'   => '13.0',
      'LAT0'   => '64.0',
      'GSIZE'  => '2500.',
   },
   'FRANCE_7.5'=>{
      'TSTEP'  => '180',
      'NLON'   => '400',
      'NLAT'   => '400',
      'LONC'   => '2.57831',
      'LATC'   => '46.46885',
      'LON0'   => '2.57831',
      'LAT0'   => '46.46885',
      'GSIZE'  => '7500.',
   },
   'FRANCE_2.5'=>{
      'TSTEP'  => '60',
      'NLON'   => '750',
      'NLAT'   => '720',
      'LONC'   => '2.0',
      'LATC'   => '45.8',
      'LON0'   => '2.0',
      'LAT0'   => '45.8',
      'GSIZE'  => '2500.',
   },
   'GLAMEPS_v0'=>{
      'TSTEP'  => '400',
      'NLON'   => '512',
      'NLAT'   => '432',
      'LONC'   => '-4.5',
      'LATC'   => '52.3',
      'LON0'   => '35.0',
      'LAT0'   => '45.0',
      'GSIZE'  => '11000.',
   },
   'GLAMEPSV2'=>{
      'TSTEP'  => '300',
      'NLON'   => '864',
      'NLAT'   => '720',
      'LONC'   => '-3.514364',
      'LATC'   => '55.229520',
      'LON0'   => '28.0',
      'LAT0'   => '42.8',
      'GSIZE'  => '8900.',
   },
   'NORWAY'=>{
      'TSTEP'  => '300',
      'NLON'   => '270',
      'NLAT'   => '400',
      'LONC'   => '14.0',
      'LATC'   => '66.2',
      'LON0'   => '-40.0',
      'LAT0'   => '66.2',
      'GSIZE'  => '11000.',
      'NSMAX'  => '199',
      'NMSMAX' => '134',
   },
   'NORWAY_2.5KM'=>{
      'TSTEP'  => '60',
       'NLON'  => '360',
       'NLAT'  => '800',
       'LONC'  => '14.2',
       'LATC'  => '65.2',
       'LON0'  => '-23',
       'LAT0'  => '64.35',
       'GSIZE' => '2500.',
   },
   'NORWAY_4KM'=>{
      'TSTEP'  => '90',
      'NLON'   => '300',
      'NLAT'   => '500',
      'LONC'   => '16.40',
      'LATC'   => '64.47',
      'LON0'   => '-23.',
      'LAT0'   => '64.35',
      'GSIZE'  => '4000.',
   },
   'NORWAY_5.5'=>{
      'TSTEP'  => '120',
      'NLON'   => '540',
      'NLAT'   => '810',
      'LONC'   => '13.0',
      'LATC'   => '66.0',
      'LON0'   => '-40.0',
      'LAT0'   => '68.0',
      'GSIZE'  => '5500.',
   },
   'DENMARK'=>{
      'TSTEP'  => '60',
      'NLON'   => '384',
      'NLAT'   => '400',
      'LONC'   => '9.9',
      'LATC'   => '56.3',
      'LON0'   => '0.0',
      'LAT0'   => '56.3',
      'GSIZE'  => '2500.',
   },
   'DKCOEXP'=>{
      'TSTEP'  => '75',
#      'TSTEP_LINEAR'  => '60',
#      'TSTEP_QUADRATIC'  => '90',
#      'TSTEP_CUBIC'  => '120',
      'NLON'   => '648',
      'NLAT'   => '648',
      'LONC'   => '9.9',
      'LATC'   => '56.3',
      'LON0'   => '0.0',
      'LAT0'   => '56.3',
      'GSIZE'  => '2500.',
  },
  'DKA'=>{
      'TSTEP'  => '60',
      'NLON'   => '800',
      'NLAT'   => '600',
      'LONC'   => '8.2',
      'LATC'   => '56.7',
      'LON0'   => '25.0',
      'LAT0'   => '56.7',
      'GSIZE'  => '2500.',
  },
   'NEA'=>{
      'TSTEP'  => '75',
      'NLON'   => '1200',
      'NLAT'   => '1080',
      'LONC'   => '7.0',
      'LATC'   => '60.0',
      'LON0'   => '25.0',
      'LAT0'   => '60.0',
      'GSIZE'  => '2500.',
  },
  'IGA'=>{
      'TSTEP'  => '75',
      'NLON'   => '1000',
      'NLAT'   => '800',
      'LONC'   => '-36',
      'LATC'   => '64',
      'LON0'   => '-55.0',
      'LAT0'   => '65.0',
      'GSIZE'  => '2500.',
      'EZONE'  => '11',
   },
   'GREENLAND'=>{
      'TSTEP'  => '150',
      'NLON'   => '576',
      'NLAT'   => '750',
      'LONC'   => '-40.0',
      'LATC'   => '70.0',
      'LON0'   => '-40.0',
      'LAT0'   => '70.0',
      'GSIZE'  => '5000.',
   },
   'NARSARSUAQ'=>{
      'TSTEP'  => '20',
      'NLON'   => '256',
      'NLAT'   => '256',
      'EZONE'  => '11',
      'LONC'   => '-44.3',
      'LATC'   => '60.2',
      'LON0'   => '-44.3',
      'LAT0'   => '60.2',
      'GSIZE'  => '2000.',
   },
   'GLA'=>{
      'TSTEP'  => '30',
      'NLON'   => '200',
      'NLAT'   => '400',
      'EZONE'  => '11',
      'LONC'   => '-47.8',
      'LATC'   => '62.1',
      'LON0'   => '-10.0',
      'LAT0'   => '61.0',
      'GSIZE'  => '2000.',
   },
   'GLB'=>{
      'TSTEP'  => '45',                                # Time step
      'NLON'   => '400',                               # Number of points (x)
      'NLAT'   => '800',                               # Number of points (y)
      'EZONE'  => '11',                                # Number of points overe xtension zone (x,y)
      'LONC'   => '-49',                             # Longitude of domain centre (degrees)
      'LATC'   => '65',                              # Latitude of domain center (degrees)
      'LON0'   => '-38.0',                             # Reference longitude of the projection (degrees)
      'LAT0'   => '73.0',                              # Reference latitude of the projection (degrees)
      'GSIZE'  => '2000.',                             # Grid size in meters (x,y)
   },
   'H2500'=>{
      'TSTEP'  => '60',
      'NLON'   => '1000',
      'NLAT'   => '750',
      'LONC'   => '8.0',
      'LATC'   => '58.0',
      'LON0'   => '8.0',
      'LAT0'   => '58.0',
      'GSIZE'  => '2500.',
   },
   'ICELAND0'=>{
      'TSTEP'  => '60',
      'NLON'   => '300',
      'NLAT'   => '240',
      'LONC'   => '-19.0',
      'LATC'   => '64.7',
      'LON0'   => '-19.0',
      'LAT0'   => '64.7',
      'GSIZE'  => '2500.',
   },
   'ICELAND'=>{
      'TSTEP'  => '45',
      'NLON'   => '500',
      'NLAT'   => '480',
      'LONC'   => '-19.0',
      'LATC'   => '64.7',
      'LON0'   => '-19.0',
      'LAT0'   => '64.7',
      'GSIZE'  => '2500.',
   },
   'IBERIA'=>{
      'TSTEP'  => '300',
      'NLON'   => '384',
      'NLAT'   => '400',
      'LONC'   => '-5.0',
      'LATC'   => '40.0',
      'LON0'   => '-5.0',
      'LAT0'   => '40.0',
      'GSIZE'  => '11000.',
   },
   'IBERIA_8'=>{
      'TSTEP'  => '300',
      'NLON'   => '486',
      'NLAT'   => '500',
      'LONC'   => '-5.0',
      'LATC'   => '40.0',
      'LON0'   => '-5.0',
      'LAT0'   => '40.0',
      'GSIZE'  => '8000.',
   },
   'IBERIA_2.5'=>{
      'TSTEP'  => '60',
      'NLON'   => '576',
      'NLAT'   => '480',
      'LONC'   => '-2.5',
      'LATC'   => '40.0',
      'LON0'   => '-2.5',
      'LAT0'   => '40.0',
      'GSIZE'  => '2500.',
   },
   'IBERIA_2.5_30_24'=>{
      'TSTEP'  => '60',
      'NLON'   => '576',
      'NLAT'   => '480',
      'LONC'   => '-2.5',
      'LATC'   => '40.0',
      'LON0'   => '-2.5',
      'LAT0'   => '40.0',
      'GSIZE'  => '2500.',
      'NNOEXTZX' => '30',
      'NNOEXTZY' => '24',
   },
   'IBERIAxxm_2.5'=>{
      'TSTEP'  => '60',
      'NLON'   => '800',
      'NLAT'   => '648',
      'LONC'   => '-4.5',
      'LATC'   => '40.0',
      'LON0'   => '-4.5',
      'LAT0'   => '40.0',
      'GSIZE'  => '2500.',
   },
   'IBERIAxl_2.5'=>{
      'TSTEP'  => '60',
      'NLON'   => '1152',
      'NLAT'   => '864',
      'LONC'   => '-5.0',
      'LATC'   => '40.0',
      'LON0'   => '-5.0',
      'LAT0'   => '40.0',
      'GSIZE'  => '2500.',
   },
   'LACE'=>{
      'TSTEP'  => '400',
      'NLON'   => '320',
      'NLAT'   => '288',
      'LONC'   => '17.00',
      'LATC'   => '46.2447006399999978',
      'LON0'   => '17.00',
      'LAT0'   => '46.2447006399999978',
      'GSIZE'  => '9005.31309924004927',
   },
   'MEDITERRANEAN'=>{
      'TSTEP'  => '60',      
      'NLON'   => '300',     
      'NLAT'   => '300',    
      'LONC'   => '0.0',   
      'LATC'   => '40.0', 
      'LON0'   => '0.0',  
      'LAT0'   => '40.0',  
      'GSIZE'  => '2500.', 
   },
   'NETHERLANDS'=>{
      'TSTEP'  => '60',
      'NLON'   => '800',
      'NLAT'   => '800',
      'LONC'   => '4.9',
      'LATC'   => '51.967',
      'LON0'   => '0.0',
      'LAT0'   => '52.5',
      'GSIZE'  => '2500.',
   },
   'METCOOP25B'=>{
      'TSTEP'  => '75',  
      'NLON'   => '750', 
      'NLAT'   => '960', 
      'LONC'   => '15.0',
      'LATC'   => '63.5', 
      'LON0'   => '15.0',  
      'LAT0'   => '63.0',   
      'GSIZE'  => '2500.',  
   },
   'METCOOP25C'=>{
      'TSTEP'  => '75',  
      'NLON'   => '900', 
      'NLAT'   => '960', 
      'LONC'   => '16.763011639',
      'LATC'   => '63.489212956',
      'LON0'   => '15.0',  
      'LAT0'   => '63.0',   
      'GSIZE'  => '2500.',  
   },
   'METCOOP25S'=>{
      'TSTEP'  => '90',  
      'NLON'   => '100', 
      'NLAT'   => '120', 
      'LONC'   => '18.5',
      'LATC'   => '60.0', 
      'LON0'   => '18.5',  
      'LAT0'   => '60.0',   
      'GSIZE'  => '2500.',  
   },
   'AROME_ARCTIC'=>{
      'TSTEP'  => '60',
      'NLON'   => '750',
      'NLAT'   => '960',
      'LONC'   => '23.0',
      'LATC'   => '75.4',
      'LON0'   => '-25.0',
      'LAT0'   => '77.5',
      'GSIZE'  => '2500.',
   },
   'AROME_ARCTIC_ACCESS'=>{
      'TSTEP'  => '60',
      'NLON'   => '750',
      'NLAT'   => '960',
      'LONC'   => '35.1',
      'LATC'   => '76.8',
      'LON0'   => '-25.0',
      'LAT0'   => '77.5',
      'GSIZE'  => '2500.',
   },
   'LITHUANIA'=>{
      'TSTEP'  => '60',
      'NLON'   => '800',
      'NLAT'   => '648',
      'LONC'   => '22.0',
      'LATC'   => '55.0',
      'LON0'   => '24.0',
      'LAT0'   => '55.0',
      'GSIZE'  => '2500.',
   },
   'TEST_OBS'=>{
      'TSTEP'  => '300',
      'NLON'   => '360',                                
      'NLAT'   => '270',                                
      'LONC'   => '-15.0',                              
      'LATC'   => '55.0',                              
      'LON0'   => '-15.0',                             
      'LAT0'   => '55.0',                              
      'GSIZE'  => '30000.',                            
   },
  );

  #
  # List available domains if the requested is not recognized
  #

  if ( ! exists $domains{$domain} ) {

    print "\nCould not find the definition of domain ".$domain." in Harmonie_domains.pm\n";
    print "Available domains are:\n\n";

    for my $key ( sort keys %domains ) {
       print "  $key\n";
    } ;
    exit 1 ;
  };

  # Check if all needed values are set and calclulate necessary ones
  foreach my $var ( ('TSTEP','NLON','NLAT','LONC','LATC','LON0','LAT0','GSIZE' )){
    unless ( $domains{$domain}{$var} ) { print "ERROR: $var is not set in Harmonie_domains.pm for domain $domain!\n"; exit 1;}
  };

  # EZONE if not given by user
  unless ( $domains{$domain}{'EZONE'} ) { $domains{$domain}{'EZONE'}=$default_ezone; }
  # NNOEXTZX if not given by user
  unless ( $domains{$domain}{'NNOEXTZX'} ) { $domains{$domain}{'NNOEXTZX'}=0; }
  # NNOEXTZY if not given by user
  unless ( $domains{$domain}{'NNOEXTZY'} ) { $domains{$domain}{'NNOEXTZY'}=0; }

  # Dimension of grid without extenzion zone
  my $NLON=$domains{$domain}{'NLON'};
  my $NLAT=$domains{$domain}{'NLAT'};
  my $EZONE=$domains{$domain}{'EZONE'};
  $domains{$domain}{'NDLUXG'}=$NLON - $EZONE ;
  $domains{$domain}{'NDGUXG'}=$NLAT - $EZONE ;

  # Sinus of LAT0
  my $pi = 3.14159265358979;
  my $LAT0=$domains{$domain}{'LAT0'};
  $domains{$domain}{'SINLAT0'}=sin($LAT0 * $pi/180. ) ;

  # GRID_TYPE settings
  my %grid_type = (
     LINEAR => {
      trunc => 2 ,
     },
     QUADRATIC => {
      trunc => 3 ,
     },
     CUBIC => {
      trunc => 4 ,
     },
     CUSTOM => {
      trunc => 2.4 ,
     }
  );

  my $tstep_type = 'TSTEP_'.$ENV{GRID_TYPE};
  if ( exists($domains{$domain}{$tstep_type})) {
    print " TSTEP changed from  $domains{$domain}{'TSTEP'} to $domains{$domain}{$tstep_type} using $tstep_type \n";
    $domains{$domain}{'TSTEP'} = $domains{$domain}{$tstep_type} ;
  } ;


  # Truncation of grid if not given by user
  unless ( $domains{$domain}{'NMSMAX'} ) { $domains{$domain}{'NMSMAX'}=floor(( $NLON -2 ) / $grid_type{$ENV{GRID_TYPE}}{trunc} ) ; } ;
  unless ( $domains{$domain}{'NSMAX'}  ) { $domains{$domain}{'NSMAX'} =floor(( $NLAT -2 ) / $grid_type{$ENV{GRID_TYPE}}{trunc} ) ; } ;

  # S
  
  # Assign the return hash
  my %dom=();
  for my $att ( sort keys %{ $domains{$domain} } ) {
    $dom{$att}=$domains{$domain}{$att};
  };

  return %dom;
}
1;
