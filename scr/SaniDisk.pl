#!/usr/bin/perl -w
#
# SaniDisk.pl: sanitize disk usage
#
# From CYCLEDIRs: delete directories $keep_cycle hours before DTG
# Remove empty CYCLEDIRS
# 
# From ARCHIVE: delete directories $keep_archive hours before DTG 
# Remove empty directories
# ARCHIVE assumed to be: $HM_DATA/archive/$YY/$MM/$DD/$HH/ 
#
# From BDDIR: delete directories $keep_bd hours before DTG 
# Remove empty directories
# BDDIR assumed to be $HM_DATA/${BDLIB}/archive/$YYYY/$MM/$DD/$HH
#
# From OBDIR: delete files $keep_ob hours before DTG
# Assuming flat structure with observation files obYYYYMMDDHH
#
# From EXTRARCH: delete files $keep_ext before DTG
# Assuming flat structure with files vfld$EXP$DTG.tar.gz and vobs$YMD.tar.gz 
#
# From LOGARCHIVE: delete files $keep_log before DTG
# Assuming flat structure with files HM_*$DTG.html
#
# NOTE:
# ONLY FOUND DIRECTORIES ARE DELETED AND IF THE ENVIRONMENT VARIABLE 
# NOSANIDISK IS SET NO SANIDISK IS PERFORMED
#
# Setting the $keep_* variable to a negative number deactivates the 
# checking for that variable. E.g. $keep_cycle=-1 never deletes cycle 
# directories.
#
# Three levels of cleaning are available and controlled by CLEANING_LEVEL
# The levels are: default,fast,slow. See further down for the meaning of the different levels
#

use strict;
use File::Path;
use File::Find;
use List::Util qw(max);

require($ENV{HM_LIB}.'/msms/harmonie.pm');

########## SETTINGS ################
my $keep_cycle=0; 
my $keep_archive=-1;
my $keep_extr=-1;
my $keep_bd=-1;
my $keep_ob=-1;
my $keep_log=-1;

####################################

my @cycledirs;
my @archdirs;
my @obfiles;
my @bddirs;
my @extrfiles;
my @extrfiles_obs;
my @logfiles;

# skip any further processing in case of NOSANIDISK
if ($ENV{NOSANIDISK}) {
  print "<br><b>found NOSANIDISK=$ENV{NOSANIDISK} -- leaving disk untouched</b><br>\n";
  exit 0;
}

# get the required environment variables
my $CYCLEDIR;
my $BDLIB;
my $HM_DATA;
my $OBDIR;
my $EXTRARCH;
my $ARCHIVE_ROOT;
my $CLEANING_LEVEL;

if ( exists $ENV{CYCLEDIR} ) { $CYCLEDIR=$ENV{CYCLEDIR} }else{ die("ERROR: CYCLEDIR is not set!") }
if ( exists $ENV{BDLIB} )    { $BDLIB=$ENV{BDLIB} }      else{ die("ERROR: BDLIB is not set!") }
if ( exists $ENV{HM_DATA} )  { $HM_DATA=$ENV{HM_DATA} }  else{ die("ERROR: HM_DATA is not set!") }
if ( exists $ENV{OBDIR} )    { $OBDIR=$ENV{OBDIR} }      else{ die("ERROR: OBDIR is not set!") }
if ( exists $ENV{EXTRARCH} ) { $EXTRARCH=$ENV{EXTRARCH} }else{ die("ERROR: EXTRARCH is not set!") }
if ( exists $ENV{ARCHIVE_ROOT} ) { $ARCHIVE_ROOT=$ENV{ARCHIVE_ROOT} }else{ die("ERROR: ARCHIVE_ROOT is not set!") }
if ( exists $ENV{CLEANING_LEVEL} ) { $CLEANING_LEVEL=$ENV{CLEANING_LEVEL} }else{ $CLEANING_LEVEL="default" ; } ;


if ( $CLEANING_LEVEL eq "default" ) {

 print "No disk cleaning applied \n";

} elsif ( $CLEANING_LEVEL eq "fast" ) {

 print "Fast disk cleaning applied \n";
 $keep_cycle= &Env('FCINT','max');
 $keep_archive=18;
 $keep_extr=24*2;
 $keep_bd=24;
 $keep_ob=24*2;
 $keep_log=24*7;

 # Make sure we do not remove boundaries required for SLAF
 $keep_bd += &Env('SLAFLAG','max');

} elsif ( $CLEANING_LEVEL eq "slow" ) {

 print "Slow disk cleaning applied \n";
 $keep_cycle= &Env('FCINT','max');
 $keep_archive=24*30;
 $keep_extr=24*30;
 $keep_bd=24*30;
 $keep_ob=24*30;
 $keep_log=24*30;

} else {

 die "Cleaning level not recognized:$CLEANING_LEVEL \n";

} ;

# current date/time:
(my $date,my $time)=CYCLEDIR2datetime($CYCLEDIR);

print "\nSaniDisk current date and time: $date $time\n\n";

##################################################################################
# CYCLEDIRS 
###################################################################################
if ( $keep_cycle >= 0){
  print "Checking cycledirs....\n";
  print "keep_cycle: $keep_cycle hours for $CYCLEDIR\n\n";

  # Change directory to HM_DATA
  if ( chdir($HM_DATA) ){

    # loop over files and directories in HM_DATA
    foreach (split /\s+/, `ls`) {

      # cycledirs
      if ( -d $_ && m([0-9]{8}_[0-2][0-9]) ) {
        (my $cycd, my $cyct) = CYCLEDIR2datetime($_);
        next if ( ! $cycd );

        # files from later cycles than DTG - $keep_cycle must not be touched 
        (my $d, my $t) = Newdatetime($cycd, $cyct, $keep_cycle * 3600 );
        if ( $d < $date || ( $d == $date && $t <= $time ) ) {
          push (@cycledirs,$HM_DATA."/".$_);
        }
      }
    }
  } else {
    print "Could not change directory to $HM_DATA\n";
  }
}
##################################################################################
# ARCHIVE AND BDDIR  PATH/YYYY/MM/DD/HH
###################################################################################
my $ARCHIVE="$ARCHIVE_ROOT/";
if ( $keep_archive>=0){
  print "Checking ARCHIVE....\n";
  print "keep_archive: $keep_archive hours for $ARCHIVE\n\n";
  @archdirs=rmRecursiveDirs($ARCHIVE,$keep_archive);
}
my $BDDIR="$HM_DATA/${BDLIB}/archive/";
if( $keep_bd >= 0) {
  print "Checking BDDIR....\n";
  print "keep_bd: $keep_bd hours for $BDDIR\n\n";
  @bddirs=rmRecursiveDirs($BDDIR,$keep_bd);
}

##################################################################################
# LOGFILES
###################################################################################
my $LOGARCHIVE="$ARCHIVE_ROOT/log";
if ( $keep_log>=0){
  print "Checking LOGFILES....\n";
  print "keep_log: $keep_log hours for $LOGARCHIVE\n\n";
  @logfiles=rmFilesDTGbrutal($LOGARCHIVE,$keep_log,"HM_",".html");
}

##################################################################################
# OBSERVATIONS
###################################################################################
if ($keep_ob >= 0){
  print "Checking observations....\n";
  print "keep_ob: $keep_ob hours for $OBDIR\n\n";
  @obfiles=rmFilesDTG($OBDIR,$keep_ob,"ob","");
}

##################################################################################
# FIELD EXTRACTS
###################################################################################
if ($keep_extr >= 0 ){
  print "Checking field extracts....\n";
  print "keep_extr: $keep_extr hours for $EXTRARCH\n\n";
  my $prefix = "vfld$ENV{EXP}" ;
  @extrfiles=rmFilesDTG($EXTRARCH,$keep_extr,$prefix,".tar.gz");
  @extrfiles_obs=rmFilesDay($EXTRARCH,$keep_extr,"vobs",".tar.gz");
}


######################################################################################
#
# REMOVE FILES AND DIRECTORIES
#
######################################################################################

print "\n\n=====================================\n";
print     "= REMOVAL OF FILES AND DIRECTORIES: =\n";
print     "=====================================\n";

if ( $keep_cycle >= 0 ){
  print "\nCYCLEDIRs to be removed:\n";
  if ( @cycledirs > 0 ){
    foreach( @cycledirs ) {
      print "rm -r  $_\n";
      rmtree($_) || print "rmtree $_ failed: $!\n" 
    }
  }else{
    print "None\n";
  }
}else{
  print "\nSanitising of cycle directories is de-activated\n\n"
}

if ($keep_archive >= 0) {
  print "\nArchiving directories to be removed:\n";
  if ( @archdirs > 0 ){
    foreach( @archdirs ) {
      print "rm -r  $_\n";
      rmtree($_) || print "rmtree $_ failed: $!\n" 
    }
  }else{
    print "None\n";
  }
}else{
  print "\nSanitising of archive directories is de-activated\n\n"
}

if ( $keep_bd >= 0 ){
  print "\nBoundary directories to be removed:\n";
  if ( @bddirs > 0 ) {
    foreach( @bddirs ) {
      print "rm -r  $_\n";
      rmtree($_) || print "rmtree $_ failed: $!\n"  
    }
  }else{
    print "None\n";
  }
}else{
  print "\nSanitising of boundary directories is de-activated\n\n"
}

if ( $keep_ob >= 0) {
  print "\nobservations to be removed:\n";
  if ( chdir($OBDIR)) {
   if ( @obfiles > 0 ){
    foreach ( @obfiles ) { 
      print "rm  $_\n";
      unlink($_) || print "rm $_ failed: $!\n"; 
    };
   }else{
    print "None\n";
   }
  }
}else{
  print "\nSanitising of observation files is de-activated\n\n"
}

if ($keep_extr >= 0 ){
  print "\nextract files to be removed:\n";
  if ( chdir($EXTRARCH)) {
   if ( @extrfiles > 0 ){
    foreach ( @extrfiles ) {
      print "rm  $_\n";
      unlink($_) || print "rm $_ failed: $!\n";
    };
   }else{
    print "No model extracts\n";
   }
   if ( @extrfiles_obs > 0 ){
    foreach ( @extrfiles_obs ) {
      print "rm  $_\n";
      unlink($_) || print "rm $_ failed: $!\n";
    };
   }else{
    print "No observations extracts\n";
   }
  }
}else{
  print "\nSanitising of extract files is de-activated\n\n"
}

if ($keep_log >= 0 ){
  print "\nlog files to be removed:\n";
  if ( chdir($LOGARCHIVE)) {
   if ( @logfiles > 0 ){
    foreach ( @logfiles ) {
      print "rm  $_\n";
      unlink($_) || print "rm $_ failed: $!\n";
    };
   }else{
    print "No logfiles\n";
   }
  }
}else{
  print "\nSanitising of log files is de-activated\n\n"
}



#########################################################################
#########################################################################
#########################################################################
sub rmFilesDTG{
  my $dir=shift(@_);
  my $keep=shift(@_);
  my $prefix=shift(@_);
  my $suffix=shift(@_);

  my @foundfiles;

  # Change directory to dir
  if ( chdir($dir)) {

    # loop over files in dir 
    foreach (split /\s+/, `ls`) {
      next if (-d $_);
      # files are obsolete if verifying before DTG - $keep
      if ( m(^($prefix)([0-9]{10})($suffix)) ) {
        (my $d, my $t) = Newdatetime(DTG2datetime($2), $keep * 3600 );
        if ( $d < $date || ( $d == $date && $t <= $time ) ) {
          push (@foundfiles,$_);
        }
      }
    }
  } else{
    print "Could not change directory to $dir\n\n";
  }
  return @foundfiles;
}
#########################################################################
#########################################################################
#########################################################################
sub rmFilesDTGbrutal{
  my $dir=shift(@_);
  my $keep=shift(@_);
  my $prefix=shift(@_);
  my $suffix=shift(@_);

  my @foundfiles;

  # Change directory to dir
  if ( chdir($dir)) {

    # loop over files in dir 
    foreach (split /\s+/, `ls`) {
      next if (-d $_);
      # files are obsolete if verifying before DTG - $keep
      if ( m(^($prefix)(.*)([0-9]{10})($suffix)) ) {
        (my $d, my $t) = Newdatetime(DTG2datetime($3), $keep * 3600 );
        if ( $d < $date || ( $d == $date && $t <= $time ) ) {
          push (@foundfiles,$_);
        }
      }
    }
  } else{
    print "Could not change directory to $dir\n\n";
  }
  return @foundfiles;
}
#########################################################################
#########################################################################
#########################################################################
sub rmFilesDay{
  my $dir=shift(@_);
  my $keep=shift(@_);
  my $prefix=shift(@_);
  my $suffix=shift(@_);

  my @foundfiles;

  # Change directory to dir
  if ( chdir($dir)) {

    # loop over files in dir
    foreach (split /\s+/, `ls`) {
      next if (-d $_);
      # files are obsolete if verifying before DTG - $keep
      if ( m(^($prefix)([0-9]{8})($suffix)) ) {
        (my $d, my $t) = Newdatetime(DTG2datetime($2."23"), $keep * 3600 );
        if ( $d < $date || ( $d == $date && $t <= $time ) ) {
          push (@foundfiles,$_);
        }
      }
    }
  } else{
    print "Could not change directory to $dir\n\n";
  }
  return @foundfiles;
}

############################################# rmRecursiveDirs ################################3
sub rmRecursiveDirs{
  my $dir=shift(@_);
  my $keep=shift(@_);

  my @founddirs;

  if ( chdir($dir)) {
    # loop recursively over directories

    YEAR:foreach my $year (split /\s+/, `ls`) {

      # look for year YYYY
      if ( -d $year && $year =~ /([0-9]{4})/ ) {

        # First check year
        (my $d, my $t) = Newdatetime(DTG2datetime($year."123123"), $keep * 3600 );
        if ( $d < $date || ( $d == $date && $t <= $time ) ) {
          push (@founddirs,$dir."/".$year);
          next YEAR;
        }
        chdir $year;
        MONTH:foreach my $month (split /\s+/, `ls`) {

          # look for month MM
          if ( -d $month && $month =~ /([0-9]{2})/ ) {

            # Check month
            (my $d, my $t) = Newdatetime(DTG2datetime($year.$month."3123"), $keep * 3600 );
            if ( $d < $date || ( $d == $date && $t <= $time ) ) {
              push (@founddirs,$dir."/".$year."/".$month);
              next MONTH;
            }
            chdir $month;
            DAY:foreach my $day (split /\s+/, `ls`) {

              # look for day DD
              if ( -d $day && $day =~ /([0-9]{2})/ ) {

                # Check day
                (my $d, my $t) = Newdatetime(DTG2datetime($year.$month.$day."23"), $keep * 3600 );
                if ( $d < $date || ( $d == $date && $t <= $time ) ) {
                  push (@founddirs,$dir."/".$year."/".$month."/".$day);
                  next DAY;
                }

                chdir $day;
                HOUR:foreach my $hour (split /\s+/, `ls`) {
                  # look for hour HH    
                  if ( -d $hour && $hour =~ /([0-9]{2})/ ) {

                    # older than DTG - $keep
                    (my $d, my $t) = Newdatetime(DTG2datetime($year.$month.$day.$hour), $keep * 3600 );
                    if ( $d < $date || ( $d == $date && $t <= $time ) ) {
                      push (@founddirs,$dir."/".$year."/".$month."/".$day."/".$hour);
                    }
                  }
                }
                chdir("..");
              }
            }
            chdir("..");
          }
        } 
        chdir("..");
      }
    }
  } else{
    print "Could not change directory to $dir\n\n";
  }
  return @founddirs
}

######################################################################################
# ------------------------------------------------------------------------------
sub CYCLEDIR2datetime{
# CYCLEDIR2datetime: convert CYCLEDIR to date and time (yyyymmdd and hhmmss)
# synopsis: ($Date,$Time) = CYCLEDIR2datetime($CYCLEDIR);
# author: Gerard Cats, 22 September 2000
   my $cyd=shift(@_);
   return ($1,sprintf("%2.2d0000",$2)) if ( $cyd =~ /^([0-9]{8})_([0-9]{2})r?/ );
   die "CYCLEDIR2datetime: FATAL ERROR in DTG structure of CYCLEDIR ($cyd)\n";
}
# ------------------------------------------------------------------------------
sub Newdatetime{
# Newdatetime: calculate new date and time from old plus increment
# synopsis: ($NewDate,$NewTime) = Newdatetime($olddate, $oldtime, $incr);
# dates in yyyymmdd, times in hhmmss, incr in seconds
# beware hhmmss=010000 is an octal number, use "010000" or 10000
# author: Gerard Cats, 4 September 2000
   my $oldd=shift(@_);
   my $oldt=shift(@_);
   my $incr=shift(@_);
   my( $newt, $s, $r, $m, $h);
# convert time to seconds
   $s=$oldt%100; $r=($oldt-$s)/100; $m=$r%100; $h=($r-$m)/100;
   $oldt = $h*3600 + $m*60 + $s;
# get new time,  and increment in whole number of days
   $newt = $oldt + $incr;
   $oldt = $newt % 86400;
   $incr=($newt-$oldt)/86400;
# convert time to hhmmss
   $s=$oldt%60; $r=($oldt-$s)/60; $m=$r%60; $h=($r-$m)/60;
   $oldt = $h*10000 + $m*100 + $s;
   return (Newdate( $oldd, $incr), sprintf("%6.6d",$oldt));
}
# ------------------------------------------------------------------------------
sub Newdate{
# newdate: calculate new date from old plus increment (in days, pos or neg)
# synopsis: $newdate=newdate($date,$dif);
# author: Gerard Cats, 2 September 2000
   my $old=shift(@_);
   my $inc=shift(@_);
   $old=idat2c($old)+$inc;
   return ic2dat($old);
}
# ------------------------------------------------------------------------------
sub ic2dat{
# ic2dat: return date from century day
# synopsis: $date=ic2dat($Cday);
# author: Gerard Cats, 2 June 2000
   my $Cday=shift(@_);
   my($y, $m, $d, $l, $n);

      $l = $Cday + 68569 + 2415020;
      $d = 4*$l;
      $n = ($d-$d%146097) / 146097;
      $d = 146097*$n + 3;
      $l = $l - ( $d-$d%4) / 4;
      $d = 4000*($l+1);
      $y = ( $d-$d%1461001 ) / 1461001;
      $d = 1461*$y;
      $l = $l - ($d-$d%4)/ 4 + 31;
      $d = 80*$l;
      $m = ($d-$d%2447) / 2447;
      $d = 2447*$m;
      $d = $l - ($d-$d%80)/ 80;
      $l = ($m-$m%11) / 11;
      $m = $m + 2 - 12 * $l;
      $y = 100 * ( $n- 49 ) + $y + $l;

   return 10000*$y+$m*100+$d;
}
# ------------------------------------------------------------------------------
sub idat2c{
# idat2c: return century day from date
# synopsis: $cday=idat2c($Date);
# author: Gerard Cats, 2 June 2000
   my $Date=shift(@_);
   my($y,$m,$d,$r);
   $y=($Date-$Date%10000)/10000;
   $r=$Date-$y*10000;
   $m=($r-$r%100)/100+1;
   $d=$r-$m*100;
   if($m<=3){ $y=$y-1; $m=$m+12; }
   $r=($y - $y%100)/100;
   return 365*$y-693923+($y-$y%4)/4 -$r+($r-$r%4)/4+int(30.6001*$m)+$d;
}
# ------------------------------------------------------------------------------
sub DTG2datetime{
# DTG2datetime: convert DTG to date and time (yyyymmdd and hhmmss)
# synopsis: ($Date,$Time) = DTG2datetime($DTG);
# author: Gerard Cats, 22 September 2000
   my $cyd=shift(@_);
   return ($1,sprintf("%2.2d0000",$2)) if ( $cyd =~ /(^[0-9]{8})([0-9]{2}$)/ );
   die "DTG2datetime: FATAL ERROR in DTG structure of CYCLEDIR ($cyd)\n";
}

