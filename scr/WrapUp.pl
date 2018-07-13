#!/usr/bin/perl -w 

# Clean JOBOUTDIR for EXP

# 0. Preliminaries

use Cwd;
$cwd = cwd;

foreach $var ( qw/ EXP JOBOUTDIR / ) {
   $$var=$ENV{$var} or die "$var not in the environment\n";
}

# 1. JOBOUTDIR

# 1.1 remove empty directories

-d $JOBOUTDIR or die "Directory JOBOUTDIR ('$JOBOUTDIR') does not exist: $!\n";
chdir $JOBOUTDIR or die "Cannot chdir to JOBOUTDIR ('$JOBOUTDIR'): $!\n";
-d $EXP or die "Directory EXP ('$EXP') does not exist in $JOBOUTDIR: $!\n";
Descend( $EXP, "rmdir rmfile" );

chdir $cwd;

#-----------------------------------------------------------------------
sub Descend{
# Descend: descend a directory, and take action on the lowest directory found, recursively; also remove files from ExperimentWrapUp
# Usage: Descend($dir, @actions) where $dir must be an existing directory in cwd
# Gerard Cats, 26 January 2005

   local $dir = shift;
   local @actions = @_;
   local *DIR;
   chdir $dir or die "Cannot chdir to " . cwd . "/$dir: $!\n";
   opendir( DIR, "." ) or die "could not open $dir/.: $!\n";
   while ( $_ = readdir DIR ) {
       next if /^\.{1,2}$/;	# skip . and ..
       
       if ( grep /rmfile/, @actions ) {
	  next if /Wrapup/;     # don''t remove files belonging to this job
          unlink if -f;
       }
       next unless -d;		# only treat directories
       Descend( $_, @actions );
   }
   closedir DIR;
   chdir "..";
   return if ($dir eq $EXP);   # don't remove the toplevel EXP directory
   if ( grep /rmdir/, @actions ) {
      rmdir $dir or print cwd, "/$dir not removed: $!\n";
   }
}
