# Settings for hourly based and minute (time-step) based output 
if [ "$TFLAG" = min ] ; then
  LLINC=".FALSE."
else
  LLINC=".TRUE."
fi

# Frequency of AROME radiation call in time steps (15 min)
ZNRADFR=$(( 900 / TSTEP ))

# Domain dependent settings for transition zones in AROME spectral nudging
# horizontally it is approximately 50 and 100 km in wavelength
# vertically a height correspnding to around 50 and 100 hpa

gs=$( echo "$GSIZE" | cut -f 1 -d . )
ZNEK0=$( expr \( "$NLON" \* "$gs" \) / 100000  || echo "" )
ZNEK1=$( expr \( "$NLON" \* "$gs" \) / 50000 || echo "" )

if [ "$VLEV" = MF_60 ]; then
  ZNEN1=6
  ZNEN2=9
else
  ZNEN1=3
  ZNEN2=6
fi

# vorticity dealiasing
if [ "${LGRADSP-no}" = yes ]; then
  lgradsp=.TRUE.
else
  lgradsp=.FALSE.
fi

# upper boundary condition
if [ "${LUNBC-no}" = yes ]; then
  lunbc=.TRUE.
else
  lunbc=.FALSE.
fi

if [ "$LSPBDC"  = yes ]; then
  NNOEXTZX=0
  NNOEXTZY=0
  lspbdc=.TRUE.
else
  lspbdc=.FALSE.
fi


export LHARATU=.FALSE.
if [ "$HARATU"  = yes ]; then
  LHARATU=.TRUE.
fi
