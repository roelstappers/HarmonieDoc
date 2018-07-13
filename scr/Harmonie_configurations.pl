#!/usr/bin/perl -w

 # use strict;
 #
 # Configurations for HARMONIE
 #
 # Arguments : [ -c CONFIGURATION_NAME ] [ -d DOMAIN ] [ -l VERTICAL_LEVELS ] [ -h HOST-MODEL ] [ -v VERBOSE ]
 # 
 # Each configuration defines the departure from the default sms/config_exp.h
 # A new experiment will be created and launched 
 #

 # Scan the arguments
 my $config  = "undefined";
 my $domain  = "undefined";
 my $vertlev = "undefined";
 my $confdef;
 my $mode    = 1 ;

 my $n = 0 ;
 while ( <@ARGV> ) {

   if ( /-c/) { $config  = $ARGV[($n + 1)] ;} ;
   if ( /-d/) { $domain  = $ARGV[($n + 1)] ;} ;
   if ( /-l/) { $vertlev = $ARGV[($n + 1)] ;} ;
   if ( /-f/) { $confdef = $ARGV[($n + 1)] ;} ;
   $n++ ;
 } ;

 # The configuration definition module is sent as an argument because we don't here 
 # if it is found in the reference or local check out.
 if (!defined($confdef)){
   print "ERROR: No configuration definition file found!";
   exit;
 }else{
   if ( -s $confdef ){ 
     require("$confdef");
   }else{
     print "ERROR: The file $confdef does not exist!";
     exit; 
   }
 }

 # Get the default HARMONIE configurations
 my %config_defs=&Harmonie_configurations($config,$domain,$vertlev,$mode);

 #
 # Get current revision
 #

 open HM, "< config-sh/hm_rev" or die "cannot open config-sh/hm_rev \n";
 my $hm_rev=<HM>;
 close HM;
 chomp $hm_rev;


 #
 # Update harmonie.pm if requested
 #

 my @exclude=("description","config","harmonie.pm",
              "DTG","DTGEND","DECOMPOSITION", "SMSTASKMAX") ;
 
 if ( exists($config_defs{$config}{'harmonie.pm'} )) {
  @exclude = (@exclude,&update_harmonie_pm($hm_rev));
 }


 #
 # Update include.ass and config_exp.h
 #
 
 my $add_missing = 0;

 for my $config_file ('scr/include.ass','sms/config_exp.h') {

  @exclude = (@exclude,&update_settings($config_file,$hm_rev));
  $add_missing = 1;

 } ;


#############################################################################################
#############################################################################################
#############################################################################################

sub update_harmonie_pm () {

  my $ref  = shift ;

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
   for my $role ( @{ $config_defs{$config}{$config_file} } ) {
 
     next unless ( $_ =~ /^(.*)\'$role\'( ){0,}=>/ ) ;
     next if ( $_ =~ /^(\s+)#(.*)\'$role\'( ){0,}=>/ ) ;

     $_ =~ s/((\{|\[)(.*)(\}|\]))/$config_defs{$config}{$role}/;

     print " Change $role to $config_defs{$config}{$role}\n";
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
   for my $role ( sort keys %{ $config_defs{$config} } ) {

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

     print " Change $tmp to $role=$config_defs{$config}{$role}\n";
     $_=~ s/$key=$val/$role=\"$config_defs{$config}{$role}\"/;
     push @exclude_add, $role unless ( grep /^$role$/, @exclude_add );
   }
   print CO "$_\n";

  };

  # Print extra settings
  if ( $add_missing ) {
   print "\n";
   for my $role ( sort keys %{ $config_defs{$config} } ) {
    next if ( grep /^$role$/, (@exclude,@exclude_add) );
    print " Add new settings $role=$config_defs{$config}{$role} \n";
    print CO "export $role=$config_defs{$config}{$role}\n";
   } ;
  } ;


  close CI ;
  close CO ;

  return @exclude_add ;

}
