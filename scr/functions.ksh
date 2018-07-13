#!/bin/ksh

#-------------------------------------------------------------------------------
# Global functions
#-------------------------------------------------------------------------------

function CheckDir
{
        typeset f=$1; shift
        if [[ ! -d ${f} ]]; then
                echo "$1 does not exist!" ; exit
        fi
}

#-------------------------------------------------------------------------------

function InitDir
{
#	$1: from
#	$2: to
	[[ -d $2 ]] && rm -Rf $2
	if [[ -d $1 ]]; then
		cp -R $1 $2
	fi
}

#-------------------------------------------------------------------------------

function RecreateDir
{
#	$1: dir

	[[ -d $1 ]] && rm -Rf $1
	mkdir -p $1 
}

#-------------------------------------------------------------------------------

function CopyObs
{
#	$1: Remote Obsoul file
#	$2: Local Obsoul file

        cp $1 ${d_BATOR}/$2
}

#-------------------------------------------------------------------------------

function CopyEcObs
{
#       $1: Remote Obsoul file
#       $2: Local Obsoul file

        ecp -o ${d_BUFR}/$1 ${d_BATOR}/$2
}

#-------------------------------------------------------------------------------

function ArchDir {
    # Return name of archive directory given date information
    if [ $# -lt 5 -o $# -gt 6 ]; then
        echo "Usage: ArchDir rootdir YYYY MM DD HH [ensmbr]"
        exit 1
    fi
    adir=$1/$2/$3/$4/$5
    if [ $# -eq 6 ]; then
        ensmbr=$6
    else
        ensmbr=${ENSMBR--1}
    fi
    if [ $ensmbr -ge 0 ]; then
        eee=$( perl -e 'printf("%03d",shift)' $ensmbr )
	adir=$adir/mbr$eee
    fi
    echo $adir/
}
