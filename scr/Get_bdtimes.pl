#!/usr/bin/perl -w 

#
# Scan a bdstrategy file and
# check if interpolated boundary file, $int_bdfile, or 
# original ECMWF file, $bdfile, is available.
# If not we add the date and forecast length to the stage/retrieve list
# Since the analysis should be requested with TYPE=an it is 
# treated in a separate MARS request.
#
# Ulf Andrae, SMHI, 2010,2013
#

# Input/output files
$ifile = $ARGV[0] or die "Please give an input  file\n";
$ofile = $ARGV[1] or die "Please give an output file\n";
$mcmd  = $ARGV[2] or die "Please give the MARS command\n";

open FILE, "< $ifile" or die "Could not open $ifile\n";

# Initialis working variables
%oper_hours = ();
%scda_hours = ();
%date_hash = () ;

$bdstrategy = "";

@ensbdmbr = ();
$ensctrl = -1;

@non_scda_strategies = ('enda','eps_ec','era','eps_ec_oper');
@non_eps_strategies = ('simulate_operational');

$do_scda     = 1;
$is_ensemble = 0;

$mars_fetch_surf_hour = $ENV{MARS_FETCH_SURF_HOUR} or $mars_fetch_surf_hour = 'ALL' ;

# Scan the bdstrategy file
while ( <FILE> ) {
 
 #
 # Only parse the boundary definition lines
 #
 if ( /BDSTRATEGY:/  ) {
    
    # Extract the strategy
    @TMP = split(' ');
    $TMP[1] =~ s/ //g;
    $bdstrategy = $TMP[1] ;

    if ( grep /$TMP[1]/,@non_scda_strategies) { $do_scda = 0 ; }
  
 } elsif ( /ENSBDMBR:/  ) {
    
    # Extract the ensemble boundary member
    # the control member is handled separately
    @TMP = split(' ');
    $TMP[1] =~ s/ //g;
    $TMP[1] = $TMP[1]*1;
    if ( $TMP[1] > 0 ) { 
      unless ( grep /\b$TMP[1]\b/,@ensbdmbr) { push @ensbdmbr, $TMP[1] ; }
      $is_ensemble = 1;
    } elsif ( $TMP[1] == 0 ) {
      $ensctrl = 0;
      $is_ensemble = 1;
    }

    if ( grep /$bdstrategy/,@non_eps_strategies) { 
      $is_ensemble = 0  ;
      $ensctrl     = -1 ;
    }
  
 } elsif ( /HOST_MODEL:/  ) {
    # Extract the host model
    @TMP = split(' ');
    $TMP[1] =~ s/ //g;
    $host_model = $TMP[1] ;

 } elsif ( /^[0-9]{3}\|/  ) {

    @TMP = split(' ');

    #
    # Extract file names and check for existence
    #

    $int_bdfile = $TMP[1];
    $bdfile     = $TMP[2];

#   Extract everything to make it more robust
    unless ( $ENV{MARS_GET_CLUSTER} ) {
      next if ( -s $int_bdfile );
      next if ( -s $bdfile );
    }

    #
    # Extract date/time information and add to stage list
    #

    $date = $TMP[-6];
    $kk   = sprintf("%.2i",$TMP[-8]);
    $hh   = sprintf("%.2i",$TMP[-4]);
    $ll   = sprintf("%.3i",$TMP[-2]);
    $dtg  = $date.$hh ;

    # Treat forcecast length = 00 differently if not ensemble
    $myhash = "date" ;
    if ( $mars_fetch_surf_hour =~ /$kk/ ) { $myhash = $myhash."_".$kk } else { $myhash = $myhash."_NN" } 
    if ( $ll == 0 ) { $myhash = $myhash."_00" } else { $myhash = $myhash."_NN" } 

    ${date_hash}{${myhash}} = $kk ;

    unless ( grep /$ll/,@{ ${$myhash}{$dtg} }) { push @{ ${$myhash}{$dtg} }, $ll; }

    # Separate 00/12 and 06/18 following ECMWFs STREAM convention

    if ( ( $hh == 06 || $hh == 18 ) && $host_model eq "ifs" && $do_scda )  {
       unless ( grep /$hh/,@{ $scda_hours{$dtg} }) { push @{ $scda_hours{$dtg} }, $hh; print "Added $hh to scda_hours \n" ;}
    } else {
       unless ( grep /$hh/,@{ $oper_hours{$dtg} }) { push @{ $oper_hours{$dtg} }, $hh; }
    }

 }

}

#
# Build the MARS request
#

for $myhash ( sort keys %{date_hash} ) {

 $number="";
 $ensmbr="";
 if ( $is_ensemble ) { 
    if (scalar(@ensbdmbr) > 0 ) { 
      $ensmbr = ' -m '. join('/',sort { $a <=> $b } @ensbdmbr);
    }
    $number = ".[number]"; 
 }


 for $dtg ( sort keys %{$myhash} ) {

  $ll = join("/", @{ $${myhash}{$dtg} });

  $date = int ($dtg/100) ;
  $basecall="MARS_get_bd -c $mcmd -d $date -l $ll -f $ofile -k $date_hash{$myhash}";

  $basefile="$ENV{WRK}/mars_prefetch_[levtype]_[date]_[time]+[step]" ;

  if ( exists ( $oper_hours{$dtg} ) ) {

     $hh = join("/", @{ $oper_hours{$dtg} } );
     if ( $ENV{MARS_GET_CLUSTER} ) {
       $clusterinfo='-m 1/TO/50';
     } else {
       $clusterinfo='';
     }
     $syscall = "$basecall -h $hh $ensmbr -s OPER $clusterinfo -t ${basefile}${number}" ;
     print "$syscall \n";
     system("$syscall");

     if ( $ensctrl == 0 ) { 
       if ( $is_ensemble ) { $number = ".0"; } ;
	   $hh = join("/", @{ $oper_hours{$dtg} } );
       $syscall = "$basecall -h $hh -m $ensctrl -s OPER -t ${basefile}${number}" ;
       print "$syscall \n";
       system("$syscall");
     }

  }

  if ( exists ( $scda_hours{$dtg} ) ) {
    $hh = join("/", @{ $scda_hours{$dtg} } );
    $syscall = "$basecall -h $hh -s SCDA -t ${basefile}" ;
    print "$syscall \n";
    system("$syscall");
  }

 }

}
