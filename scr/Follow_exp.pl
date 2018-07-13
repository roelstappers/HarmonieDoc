#!/usr/bin/perl -w 

# Read experiment name and mSMS checkfile to follow. 
# Scan the file and use abort/complete flag to trigger
# same action on the listener

$bedtime = 10 ;

$EXP=$ARGV[0];
$CONFIG=$ARGV[1] ;
$CKPFILE=$ARGV[2] ;
if ( $ENV{CONT_ON_FAILURE} ) { $CONT_ON_FAILURE=$ENV{CONT_ON_FAILURE} ; } 
                        else { $CONT_ON_FAILURE=0 ; } ;

# Get HM_DATA
$HM_DATA = $ENV{HM_DATA} or die "HM_DATA is not in the environment\n";

open FOL, ">>$HM_DATA/follow.log";

local ($path, $status, $rep);

SWEEP: 
  while (1) {

        if ( ! open(CKPFILE,"<$CKPFILE") ) {
           print STDERR "couldn't open $CKPFILE; wait a while\n";
           sleep $bedtime;
           next SWEEP;
        }

        open CKPFILE_COPY, ">$HM_DATA/follow.check_copy";

        while ( <CKPFILE> ) {

           print CKPFILE_COPY "$_";

           next if /^\s*eval\s+/;
           next if /:/;

           ($path, $status, $rep) = split(/\s+/);
           next if ( $path eq "/" ) ;

           $VAR_V{$path} = $status;
           print CKPFILE_COPY "$path $status \n";

           # Set existing families to the same status
           @path = split('/',$path);
           pop(@path);
           @cp = ();
           CP :foreach $cp (@path) {
              @cp=(@cp,$cp);
              $ccp=join('/',@cp);
              if ( exists $VAR_V{$ccp} && $status ne "1" ) { 
                 $VAR_V{$ccp} = $status; 
              } ;
           } ;

        };

        close(CKPFILE) ;
        close(CKPFILE_COPY) ;

        $error = "";
        for $path ( sort keys %VAR_V ) {
           if ( $VAR_V{$path} =~ /6/ && ! ($path =~ /:HH/) && ! ($path =~/:YMD/) && ! ($path =~/:progress/) ) {
             $error = "ABORTED IN $CONFIG $path \n";
             $error = $error . "ERROR WAS: $VAR_V{$path}\n";

             # Fail gracefully if that is requested
             # Wait for a while to let mSMS complete and cleanup
             if ( $CONT_ON_FAILURE eq 1 ) {
                print FOL scalar(localtime())." $error";
                sleep $bedtime;
                exit 0 ;
             } ;

           } ;
           if ( $path eq "/$EXP" && $VAR_V{$path} =~ /1/ ) {
             print FOL scalar(localtime())." COMPLETED $CONFIG in $path \n";
             exit 0 ;
           } ;
        } ;

        if ( $error ) {
          print FOL scalar(localtime())." $error";
          die $error ;
        } ;
        sleep $bedtime;

};
