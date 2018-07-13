#!/usr/bin/env perl

require "$ENV{HM_LIB}/msms/harmonie.pm";

## LL given on command line overrides everything else
if ( exists $ENV{LL_CLA} ) {
   print $ENV{LL_CLA};
   exit 0;
}

## Return 0 outside the Cycle loops
my $hh = shift;
if ( $hh eq '' ) {
   print "0";
   exit 0;
}

## Was ensmbr given?
my $mbr = shift;
if ( $mbr eq '' ) { $mbr=-1; }

## Are we within a warmup period?
if ( exists $ENV{WARMUP_PERIOD} ) {
  my $warmup = $ENV{WARMUP_PERIOD} * 24;
  my $dtgwarm = qx(mandtg $ENV{DTGBEG} + $warmup); chomp $dtgwarm;
  if ( $ENV{DTG} < $dtgwarm ) {
    my $fcint = &Env('FCINT',$mbr);
    print "$fcint";
    exit 0;
  }
}

## Deduce LL from HH, HH_LIST and LL_LIST
my @cycles = &expand_list(&Env('HH_LIST',$mbr),"%d");
my @fclen = split(',',&Env('LL_LIST',$mbr));
@fclen = (0) unless( scalar(@fclen) );
my $nfcl = scalar(@fclen);
for (my $i=0; $i<=$#cycles; $i++) {
   if ($hh == $cycles[$i]) {
      print $fclen[$i % $nfcl];
      exit 0;
   }
}
print "0";
