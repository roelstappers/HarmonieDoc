#!/usr/local/perl
# Clean_lpfs: clean large permanent file system
# method: the argument list contains a list of files
# to be removed (wild cards allowed, but escape them from shell)
# Any pattern '*' will reuslt in removal of the directory
# at ECMWF, lpfs is on ecfs
# This script can also be used to list the directory contents
# (by option -ls). The matching file names are listed, preceded by \t
# Options:
#	-ls: just list the files to be removed, but do not remove
#	--:  end the options list


# author: Gerard Cats, 27 November 2001

# get the required environment variables

foreach $var ( qw / COMPCENTRE  HM_EXP /) {
   $$var=$ENV{$var} || die "$var not in the environment; stopped";
}

unless ( $COMPCENTRE eq 'ECMWF' )  {
   die "no such directory: $HM_EXP; stopped at" unless -d "$HM_EXP";
   chdir "$HM_EXP";
}

# options:
   shift until $ARGV[0];
while ( $ARGV[0] =~ s/^-// ) {
   $_ = shift;
   last if /^-$/;
   $ls = 1 if /^ls$/;
}

foreach ( @ARGV ) {
   if ( $COMPCENTRE eq 'ECMWF' ) {
      if ( $ls ) {
LINE:    foreach $line ( split("\n",`ksh -c 'els $HM_EXP/$_'`) ) {
            next LINE if $line =~ /^-ECFS=\> $ECFSLOC:/;	# delete the directory name
            $line =~ s/^.{1,55}//;			# file name starts at col 55+1
            next LINE if $line =~ /^\.{0,2}$/;		# delete empty, . and ..
            print "\t$line\n";
         }
      } else {
         system ksh, '-c', "erm $HM_EXP/$_" || print STDERR "error removing $_: $!\n";
      }
   } else {
      if ( $ls ) {
         print("\t", join("\n\t",glob("$_")),"\t", "\n");
      } else {
         unlink(glob("$_")) || print STDERR "error removing $_: $!\n";
      }
   }
   $rmdir = 1 if $_ eq '*';
}
if ( $rmdir ) {
   if ( $ls ) {
      print "directory $HM_EXP itself also matches (if empty)\n";
   } else {
      if ( $COMPCENTRE eq 'ECMWF' ) {
         system ksh, '-c', "ermdir $HM_EXP" || print STDERR "error removing $HM_EXP: $!\n";
      } else {
         chdir "..";
         rmdir $HM_EXP || print STDERR "error removing $HM_EXP: $!\n";
      }
   }
}
# ----------------------------------------------------rcs stuff
# $Revision: 4893 $, checked in by $Author: xiaohua $ at $Date: 2007-01-31 12:36:42 +0000 (Wed, 31 Jan 2007) $
# $Log$
# Revision 1.1  2002/01/14 07:53:25  GerardCats
# (HIRLAM version 5.1.3)
# Cleanup large permanent file system (ecfs at ECMWF)
#
