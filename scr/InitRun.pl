#!/usr/bin/perl
# $Id: InitRun.pl 5001 2007-03-13 15:58:01Z towil $

# Usage: $0 Env_system
# create hostDescriptions.h and create directories on other hosts
# fill those directories with the files defining the experiment
# this script is supposed to be executed from its parent, InitRun.sms

# Gerard cats, July 2004

$env_system = shift;
die "Usage: $0 Env_system\n" unless -x $env_system;

# get the required environment variables

foreach $var ( qw/ EXP HM_WD HOST0 HM_REV HOST_INSTALL 
                   HARMONIE_CONFIG
                   RSYNC_EXCLUDE MAKEUP/ ) {
   die "$var not in the environment\n" unless defined $ENV{ $var };
   $$var= $ENV{ $var };
}
# get the optional environment variables

$BUILD_ROOTPACK = $ENV{ BUILD_ROOTPACK } || "no";
$RCP = $ENV{ RCP } || "rcp";
$RSH = $ENV{ RSH } || "rsh";
$RSYNC = $ENV{ RSYNC } || "rsync";

# Process info from HM_CLA (the user-supplied variable settings
# on the Harmonie command line, should override everything else)

foreach ( split /\s+/, $ENV{ HM_CLA } ) {
   my ($var, $val ) = split /=/;
   $hm_cla .= "$_\nexport $var\n" if $var =~ m~^\w+$~;
}

# extract info from Env_system and create host descriptions file
# --------------------------------------------------------------

# loop over hosts

$n = 0;
while ( $ENV{ "HOST$n" } ) {
   $host = $ENV{ "HOST$n" };

# extract relevant information from Env_system

# the method to this is to execute Env_system for this host, and
# then echo the requested variables, separated by \; (which is unlikely to
# occur in any of the variables)

   ( $hm_data[ $n ], $hm_lib[ $n ], $mkdir[ $n ] ) =
      split "\;",
      `FAKEHOST=yes SMSHOST=$host; . $env_system  >&2; echo \$HM_DATA\\;\$HM_LIB\\;\$MKDIR\\;`;

# this host
# ---------
   if ( $n == 0 ) {

# open hostDescriptions.h
      open HD, ">$hm_lib[ $n ]/sms/hostDescriptions.h" or die "cannot open hostDescriptions.h:$!\n";

# remote hosts
# ------------
   } else {

# make directories
      system "$RSH $host '$mkdir[ $n ] $hm_data[ $n ]'";
      system "$RSH $host '$mkdir[ $n ] $hm_lib[ $n ]'";
   }

# hostDescriptions
# ----------------
   print HD "# $n\t$host\n";
   print HD "HM_DATA$n=$hm_data[ $n ]\texport HM_DATA$n\n";
   print HD "HM_LIB$n=$hm_lib[ $n ]\texport HM_LIB$n\n";

   $n ++;
}

# add info from HM_CLA
print HD "# Harmonie Command Line Arguments HM_CLA\n";
print HD $hm_cla;

close HD;

# Create the sandboxes on all hosts where the system needs to be installed
# ------------------------------------------------------------------------

# Treat HOST0 separately

chdir $hm_lib[0];
if ( ! -e "$HM_WD/experiment_is_locked" ) {

  if ( $MAKEUP eq 'yes' ) { $EXCLUDE_SRC = "" ; } else { $EXCLUDE_SRC="--exclude=/src" ; } ;
  System("$RSYNC -vau $RSYNC_EXCLUDE $EXCLUDE_SRC $HM_REV/ .");

  # Extract src if we are going to build a rootpack
  System("$RSYNC -vau $RSYNC_EXCLUDE $HM_REV/src ./rep_src") if ( $BUILD_ROOTPACK eq 'yes' && $MAKEUP eq 'no') ;

} ;

# Always rsync the private code
System("$RSYNC -va  $RSYNC_EXCLUDE $HM_WD/ .") unless ( $HM_WD eq $HM_REV );

# Loop over remote hosts

for ( $n=1; exists $ENV{"HOST$n"}; $n++ ) {

   $host = $ENV{"HOST$n"};
   if ( $HOST_INSTALL =~ m~(^|:)$n(:|$)~ ) {	# : separated list
   # On hosts different from HOST0, overwrite with files in HM_LIB on HOST0; these
   # already include the system-wide and user mods
      System("$RSYNC -vau --exclude=$HARMONIE_CONFIG $RSYNC_EXCLUDE $hm_lib[0]/ $host:$hm_lib[$n]");
   }

}

#-------------------------------------------------------------------------------
sub System{
# System: invoke a system and treat errors
# usage: $status = System( command )
# Gerard Cats,  8 March 2005
# Modified: Ole Vignes, 9 March 2012
   print "+ " . join(' ',@_) . "\n";
   my $s = system( @_ );
   if ( $s ) {
      my ($exit, $sign, $core) = ( $? >> 8, $? & 127, $? & 128 );
      die "system(", join(' ',@_), ")failed: exit code=$exit, signal $sign\n"
   }
   return $s;
}
