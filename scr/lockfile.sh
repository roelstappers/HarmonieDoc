#!/bin/bash

# Lockfile to prevent simultaneous WebgraF updates
#
# Magnus Berg, SMHI, 2012
#

LOCKFILE=$1

  until (umask 222; echo $$ >$LOCKFILE ) 2>/dev/null
  do
    # Optional message - show lockfile owner and creation time:                                                                 
    #set x `ls -l $LOCKFILE`
    #echo "Waiting for user $4 (working since $7 $8 $9)..."
    sleep 1
  done

