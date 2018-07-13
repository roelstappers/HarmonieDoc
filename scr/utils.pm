sub get_bdcycle {

  if ( $ENV{BDCYCLE} ) {
   # Take what is given by user
   $bdcycle = $ENV{BDCYCLE}
  } else {
   if ( $ENV{BDSTRATEGY} eq 'RCR_operational') {
    $bdcycle = 12;
   }elsif ( $ENV{BDSTRATEGY} eq 'enda') {
    if ( $ENV{DTG} ge 2010010100 ) {
      $bdcycle = 12 ;
    } else {
      $bdcycle = 24 ;
    } ;
   } else {
    # Default case
    $bdcycle  = 06 ;
   } ;
  } ;

  return $bdcycle ;

} ;

###################################################################
sub get_bdoffset {

  if ( $ENV{BDOFFSET} ) {
   # Take what is given by user
   $bdoffset = $ENV{BDOFFSET}
  }elsif ( $strategy eq 'enda' ) {

    # Data used for this is only available at 06/18Z
    if ( $dtg ge 2010010100 ) {
      $bdoffset = 6 ;
    } else {
      $bdoffset = 12 ;
    } ;
  } else {
    # Default case
    $bdoffset = 0 ;
  } ;

  return $bdoffset ;

} ;
###################################################################
sub gen_list {

   my $value = shift ;
   my $format = shift || "%03d";
   # sort, remove duplicates, and convert to 3-digit colon separated list
   my %Mbrs = ();
   for my $item ( split(',',$value) ) {
      if ( $item =~ /^(\d+)\-(\d+)$/ ) {
         for my $mbr ( $1 .. $2 ) {
            $Mbrs{$mbr} = 1;
         }
      } elsif ( $item =~ /^(\d+)\-(\d+)\:(\d+)$/ ) {
         for (my $mbr=$1; $mbr<=$2; $mbr+=$3) {
            $Mbrs{$mbr} = 1;
         }
      } elsif ( $item =~ /^(\d+)$/ ) {
         $Mbrs{$1} = 1;
      } else {
         die "$0: '$value' is in error: bad syntax: '$item'\n";
      }
   }
   my @list = ();
   for my $item ( sort { $a <=> $b } keys %Mbrs ) {
      push @list, sprintf($format,$item);
   }
   if ( @list ) {
      return wantarray ? @list : join(':',@list);
   } else {
      return '';
   }
} ;
###################################################################

1;
