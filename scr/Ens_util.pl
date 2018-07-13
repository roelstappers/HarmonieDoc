#!/usr/bin/env perl

require($ENV{HM_LIB}.'/msms/harmonie.pm');

# A simple utility script to handle the ENSemble related environment
# variables in Harmonie
# Ole Vignes, met.no, June 2011

use Getopt::Std;
use strict;

our($opt_v,$opt_m);

sub Usage {
   die "Usage: $0 [-v VAR -m MBR] <ENSVAR> [value]\n";
}

unless( getopts('m:v:') ) {
   &Usage;
}

my $var = shift || &Usage;
my $value = shift;   #empty allowed

if ($var eq 'ENSMSEL') {
  my $tmp = &expand_list($ENV{ENSMSEL});
  if ( length $tmp > 0 ) {
    print "$tmp";
  } else {
    print "-1";
  }
  exit 0;
}

my $ENSMSEL = $value || $ENV{ENSMSELX} || '-1';
my $emslen = length($ENSMSEL);
my $ENSSIZE = int( ($emslen + 1)/4 );

if ($var eq 'ENSSIZE') {
   print "$ENSSIZE";
   exit 0;
} elsif ($var eq 'ENSMFIRST') {
   print ( $ENSSIZE > 0 ? substr($ENSMSEL,0,3) : '-1' );
   exit 0;
} elsif ($var eq 'ENSMLAST') {
   print ( $ENSSIZE > 0 ? substr($ENSMSEL,$emslen-3,3) : '-1' );
   exit 0;
} elsif ($var eq 'ENSCTL') {
   if ( $value =~ /^\d+$/ ) {
      if ( exists $ENV{ENSMFIRST} and $value < $ENV{ENSMFIRST}
         or exists $ENV{ENSMLAST} and $value > $ENV{ENSMLAST} ) {
	 die "$0: ENSCTL=$value is invalid!\n";
      } else {
	 printf "%03d", $value;
	 exit 0;
      }
   } elsif ( $value ne '' ) {
      die "$0: ENSCTL=$value is invalid!\n";
   }
} elsif ($var eq 'LLMAX') {
   my $llmax = 0;
   for my $mbr ( split(':',$ENSMSEL) ) {
      my $list = &Env('LL_LIST',$mbr);
      for my $ll ( &expand_list($list,"%d") ) {
	 if ($ll > $llmax) { $llmax = $ll; }
      }
   }
   print $llmax;
   exit 0;
} elsif ($var eq 'ENVVAR') {
   if ($opt_v ne '' and $opt_m ne '') {
      my $result = &Env($opt_v,$opt_m);
      print $result;
   } else {
      die "$0: ENVVAR needs -v VAR ('$opt_v') -m MBR ('$opt_m')!\n";
   }
} else {
   die "$0: Unrecognized variable '$var'\n";
}
