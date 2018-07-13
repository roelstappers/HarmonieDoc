#!/bin/bash

. header.sh
. functions.ksh

if [ "$#" -ne "2" ]; then
  echo "Usage: $0 Vertical-levels-type climate-file"
  exit 1
else
  vlev=$1
  climfile=$2
fi

#
# Reference statistics for interpolation
# If you change this remeber to change
# the input parameters below as well
#
cd $WRK
WDIR=`hostname`$$
Workdir $WDIR

# Store the interpolated pointers
f_JBCV_INTERPOL=$f_JBCV
f_JBBAL_INTERPOL=$f_JBBAL

unset f_JBCV f_JBBAL

DOMAIN=DKCOEXP
# 
. include.ass

Access_lpfs -from $JBDIR/${f_JBCV}.gz  $PWD/. || exit 1 
Access_lpfs -from $JBDIR/${f_JBBAL}.gz $PWD/. || exit 1 

case $vlev in 
  "65")
    NDLON_IN=384 
    NDLAT_IN=400
    NEZONE_IN=11
    ELONC_IN=9.9
    ELATC_IN=56.3
    PPDELTAX_IN=2500.0
    ELON1_IN=2.10948821200439918
    ELAT1_IN=52.3159187796870739
    ELON2_IN=19.3505486354902878
    ELAT2_IN=59.6881451127888738
    ELON0_IN=0.000000000000000000
    ELAT0_IN=56.2999999999999972
    stabal_bal=${f_JBBAL}.gz
    stabal_cv=${f_JBCV}.gz
  ;;
  *)
    echo "No reference domain exists for the vertical levels: $vlev"
    echo "Please add one or create your own structure functions"
    exit 1
  ;;
esac
if [ ! -f $climfile ]; then
  echo "Climate file: $climfile is not found!"
  exit 1
fi

[ -f 4jb.inp ] && rm 4jb.inp
$BINDIR/domain_prop_grib_api -f -4JB $climfile  > 4jb.txt
NDLON=`grep NDLON 4jb.txt | cut -d"=" -f2  | sed 's/ //g'`
NDLAT=`grep NDGL  4jb.txt | cut -d"=" -f2  | sed 's/ //g'`
NDLUX=`grep NDLUX 4jb.txt | cut -d"=" -f2  | sed 's/ //g'`
EDELX=`grep EDELX 4jb.txt | cut -d"=" -f2  | sed 's/ //g'`
ELONC=`grep ELONC 4jb.txt | cut -d"=" -f2  | sed 's/ //g'`
ELATC=`grep ELATC 4jb.txt | cut -d"=" -f2  | sed 's/ //g'`
ELON0=`grep ELON0 4jb.txt | cut -d"=" -f2  | sed 's/ //g'`
ELAT0=`grep ELAT0 4jb.txt | cut -d"=" -f2  | sed 's/ //g'`
ELAT1=`grep ELAT1 4jb.txt | cut -d"=" -f2  | sed 's/ //g'`
ELON1=`grep ELON1 4jb.txt | cut -d"=" -f2  | sed 's/ //g'`
ELAT2=`grep ELAT2 4jb.txt | cut -d"=" -f2  | sed 's/ //g'`
ELON2=`grep ELON2 4jb.txt | cut -d"=" -f2  | sed 's/ //g'`
NEZONE=$(( $NDLON - $NDLUX ))

cat > nl << *EOINFILE
 &namjbconv
   nlon_in    = $NDLON_IN, 
   nlat_in    = $NDLAT_IN,
   nezone_in  = $NEZONE_IN,
   lonc_in    = $ELONC_IN,
   latc_in    = $ELATC_IN,
   gsize_in   = $EDELX_IN,
   lon1_in    = $ELON1_IN,
   lat1_in    = $ELAT1_IN,
   lon2_in    = $ELON2_IN,
   lat2_in    = $ELAT2_IN,
   lon0_in    = $ELON0_IN,
   lat0_in    = $ELAT0_IN,
   nlon_out   = $NDLON, 
   nlat_out   = $NDLAT,
   nezone_out = $NEZONE,
   lonc_out   = $ELONC,
   latc_out   = $ELATC,
   gsize_out  = $EDELX,
   lon1_out   = $ELON1,
   lat1_out   = $ELAT1,
   lon2_out   = $ELON2,
   lat2_out   = $ELAT2,
   lon0_out   = $ELON0,
   lat0_out   = $ELAT0,
 /
*EOINFILE

if [ -f $stabal_bal -a -f $stabal_cv ]; then
  cp -f $stabal_bal stabal96.bal.gz
  cp -f $stabal_cv stabal96.cv.gz
  [ -f stabal96.bal ] && rm stabal96.bal
  [ -f stabal96.cv ] && rm stabal96.cv
  gunzip stabal96.bal.gz
  gunzip stabal96.cv.gz 
else
  echo "ERROR: $stabal_bal and/or $stabal_cv do(es) not exist!"
  exit 1
fi

echo "jbconv called with this namelist:"
cat nl

$BINDIR/jbconv < nl || exit 1

if [ -f stabal96_out.cv -a -f stabal96_out.bal ]; then
  mv stabal96_out.cv ${HM_LIB}/const/jb_data/$f_JBCV_INTERPOL
  mv stabal96_out.bal ${HM_LIB}/const/jb_data/$f_JBBAL_INTERPOL
else
  echo "ERROR: Output structure functions not produced!"
  exit 1
fi

rm -f stabal96.cv
rm -f stabal96.bal
rm -f nl

# Normal exit
cd ..
rm -fr $WDIR
trap - 0

