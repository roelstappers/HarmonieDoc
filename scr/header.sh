###set -e$SH_FLAGS
###[ "${SMSTRYNO-2}" -gt 1 ] && { set -vx; env; }
ls -l $0 |\
awk '{print "script:",$NF," - last modified:",$(NF-3),$(NF-2),$(NF-1)}' 1>&2

trap "Trapbody ; exit 1" 0
trap "echo Killed by a signal ; exit 2" 1 2 3 15

Workdir () {
   $MKDIR $1 || { echo "$0: '$1' could not be created"; exit 1; }
   cd $1 || exit 1
}

Trapbody () {
   _this_=`basename $0`$2
   if [ $RUNNING_MODE = "operational" -a $FORGIVE_ME -eq 1 ] ; then
    echo $( date +"%Y-%m-%d %T" ) DTG=${DTG}: >> $HM_DATA/severe_warnings.txt
    echo "$_this_ failed " >> $HM_DATA/severe_warnings.txt
    exit 0
   else
    echo $0 failed
    ls -l
    if [ "$1" ]; then
      cd $WRK
      rm -rf Failed_${SMSPARENT}_$_this_
      mv $1 Failed_${SMSPARENT}_$_this_
      echo "$0: moved working directory to `pwd`/Failed_$_this_"
    fi
    exit 1
   fi
}

function conv {
  if [ "$#" -ne "3" -a "$#" -ne "4" ]; then
    echo "USAGE: $0 CONV_MODE FA-file LFI-file [FA-file to create from]"
    exit 1
  fi
  CONV_MODE=$1
  FA=$2
  LFI=$3

  DR_HOOK_NOT_MPI=${DR_HOOK_NOT_MPI:-1}
  export DR_HOOK_NOT_MPI=$DR_HOOK_NOT_MPI
  MPPEXEC_CONV=${MPPEXEC_CONV-$MPPEXEC}

  case $CONV_MODE in
    "sfxlfi2fa")
      if [ "$#" -ne "4" ]; then
        echo "sfxlfi2fa must have a pattern FA-file"
        exit 1
      else
        [ -f $FA ] && rm $FA
        FA_PARENT=$4
        # Create empty FA file first
        $MPPEXEC_CONV $BINDIR/lfitools faempty $FA_PARENT $FA
      fi
    ;;
    "sfxfa2lfi")
      [ -f $LFI ] && rm $LFI
    ;;
    *)
      echo "$CONV_MODE not implemented!"
      exit 1
    ;;
  esac

  $MPPEXEC_CONV $BINDIR/SFXTOOLS $CONV_MODE --sfx-fa--file $FA --sfx-lfi-file $LFI

  # Diagnostics
  #$BINDIR/lfitools lfidiff --lfi-file-1 $FA --lfi-file-2 $LFI
}

function Create_param_bin {

 #
 # Check, convert if needed, and link the input data for ecoclimap covers parameters
 #

 ECOFILES="ecoclimapI_covers_param ecoclimapII_af_covers_param ecoclimapII_eu_covers_param"
 ECODIR=${1-$CLIMDIR}
 
 $MKDIR $ECODIR
 LOCKFILE=$HM_DATA/lock.create_param
 lockfile.sh $LOCKFILE

 FOUND=1
 for F in $ECOFILES ; do
  [[ -s $ECODIR/$F.bin ]] || FOUND=0
 done
 
 if [ $FOUND -eq 0 ] ; then
  for F in $ECOFILES ; do
    FILE=$ECOCLIMAP_DATA_PATH/$F.dat
    [[ -s $FILE ]] || { echo "Could not find $FILE" ; rm -f $LOCKFILE ; exit 1 ; }
    cp $FILE .
  done
  $MPPGL $BINDIR/CONVERT_ECOCLIMAP_PARAM || exit
  mv ecoclimap*.bin $ECODIR/. || exit
 fi
 rm -f $LOCKFILE
}
