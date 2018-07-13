#!/usr/bin/perl -w 

#
# Get time information from mSMS $PLAYFILE.log files
#
# Ulf Andrae, SMHI, 2010,2012
#

use Time::Local;

unless (@ARGV) {
 die 
"\n Get_timing.pl
 Gather timing information from [hirlam|harmonie].log files
 Usage: Get_timig.pl [-d] [-e] file1.log [ file2.log ... fileN.log ]
        -e to exclude the job Archive_log
        -d for exact times of submitted/active/complete\n\n"; 

} ;

 # Init

 @FILES=();

 $debug     = 0 ;
 $exclude   = "";
 $grep_this = "";

 local ($path, $status, $rep);

 # Get arguments

 $skip_next = 0;
 
 while ( <@ARGV> ) {

     if ( $skip_next ) { $skip_next = 0 ; next ; } ;

     if ( /-d/) { $debug = 1 ; next ; } ;
     if ( /-e/) { $exclude = "Archive_log" ; next ; } ;
     if ( /-g/) { $grep_this = pop @ARGV ; $skip_next = 1 ; next ; } ;

    @FILES=(@FILES,$_);

 } 

 # Scan through the given files 

 foreach $FILE (@FILES) {

    # Get last modified time of the input file
    $file_mtime = (stat($FILE))[9];

       open FILE,"<$FILE"  or die "could not open $FILE\n";

       SCAN_FILE : while ( <FILE> ) {

           # Clean and skip if not a valid string
           chomp ;

           last SCAN_FILE if /COMPLETE/;

           next unless ( /LOG/ || /TIME/ ) ;

           if ( /TIME/ ) {
 
             # Get time and status from the TIME statements

             ($time,$rep)     = split(/\] /);
             ($status,$path)  = split(/:/,$rep);
             ($path,$rep)     = split(/ /,$path);
             ($rep,$time)     = split(/\[/,$time);

             # Clean path and skip empty ones
             @path = split('/',$path); shift(@path) ; shift(@path) ; $path=join('/',@path);
             $path =~ s/\/Execute$//g ;

             next if ( $path =~ /$exclude/ ) ;

             $status = "${status}_task";
             #print "ADD $status $path $time \n";
             ${$FILE}{$path}{$status} = $time ;

             next ;
           } ;

           # Get time and status from the LOG statements

           ($dtg, $rep)     = split(/\] /);
           ($status, $path) = split(/:/,$rep);

           next if ( $status eq "queued" ) ;

           $dtg = substr($dtg, 7,20);

           next unless $dtg =~/:/ ;

           ($time,$date) = split(/ /,$dtg) ;
           ($d,$m,$y)    = split(/\./,$date) ;
           ($h,$mi,$s)   = split(/\:/,$time) ;

           $time = timegm($s,$mi,$h,$d,$m-1,$y);

           # Clean path and skip empty ones
           @path = split('/',$path); shift(@path) ; shift(@path) ; $path=join('/',@path);
           $path =~ s/\/Execute$//g ;

           next if $path eq "" ; 
           next if ( $path =~ /$exclude/ ) ;

           # Clean last if we've found a new execution loop
           # Only jobs are queued or submitted not families 

           if ( $status eq 'submitted' ) {
              foreach $test (('submitted','active','active_task','complete','complete_task')) {
                 delete ${$FILE}{$path}{$test} if ( exists ${$FILE}{$path}{$test} ) ;
              } ;
              ${$FILE}{$path}{node_type} = "job";

              $status_dtg = $status."_DTG" ;
              ${$FILE}{$path}{$status_dtg}  = $dtg ;
              ${$FILE}{$path}{$status}      = $time ;
           } ;

           if ( $status eq 'active' || ( $status eq 'complete' && ! exists(${$FILE}{$path}{complete}) ) ) {

              if ( exists(${$FILE}{$path}{node_type}) ) {
                 if ( ${$FILE}{$path}{node_type} eq "job" ) {
                    $status_dtg = $status."_DTG" ;
                    ${$FILE}{$path}{$status_dtg}  = $dtg ;
                    ${$FILE}{$path}{$status}      = $time ;
                 } ;
              } ;

           } ;

        }; # SCAN_FILE

        close(FILE) ;

        ADD_TIMES : foreach $key ( sort keys %${FILE} ) {

         # Add time to families
         if ( exists(${$FILE}{$key}{node_type}) ) {
         if ( ${$FILE}{$key}{node_type} eq "job" ) { 

           unless ( exists( ${$FILE}{$key}{complete} ) ) {
              ${$FILE}{$key}{complete} = $file_mtime ;
              ${$FILE}{$key}{complete_task} = $file_mtime ;
              ${$FILE}{$key}{running} = 1;
           } ;

           unless ( exists( ${$FILE}{$key}{active} ) ) {
              ${$FILE}{$key}{active} = $file_mtime ;
              ${$FILE}{$key}{active_task} = $file_mtime ;
              ${$FILE}{$key}{running} = 1;
           } ;

           foreach $status (('submitted','active','complete')) {
                next unless ( exists ${$FILE}{$key}{$status} ) ;
                $running = 0 ;
                $running = 1 if ( exists( ${$FILE}{$key}{running} ) ) ;
                $path = $key ;
                $time = ${$FILE}{$key}{$status} ;
                &add_time ;
           } ;

         } ;
         } ;

        } ;

        CALC_TIMES : foreach $key ( sort keys %${FILE} ) {

         unless (exists (${$FILE}{$key}{node_type})) {
            #print "CALC SET EMPTY $key \n";
            ${$FILE}{$key}{node_type} = 'empty' ;
           (${$FILE}{$key}{'atime'},${$FILE}{$key}{'stime'} ) = (0,0);
           next CALC_TIMES ;
         } ;

         # Get family times
         if ( ${$FILE}{$key}{node_type} eq "family" ) { 
            ( ${$FILE}{$key}{'atime'},${$FILE}{$key}{'stime'},${$FILE}{$key}{'nmember'}) = &get_family_times ;
            #print "$key ${$FILE}{$key}{'atime'},${$FILE}{$key}{'stime'} \n";
            for $path ( sort keys %${key} ) {
              delete ${$key}{$path} ;
            } ;
            next CALC_TIMES ;
         } ;
     
         # Get job times
         if ( ${$FILE}{$key}{node_type} eq "job" ) { 

           unless ( exists( ${$FILE}{$key}{complete} ) ) {
              ${$FILE}{$key}{complete} = $file_mtime ;
              ${$FILE}{$key}{complete_task} = $file_mtime ;
              ${$FILE}{$key}{running} = 1;
              #print "Add running to $key \n";
           } ;

           my $diff_a = 0 ;
           my $diff_s = 0 ;

           $time_a=${$FILE}{$key}{active} ;
           $time_c=${$FILE}{$key}{complete};
           $time_s=${$FILE}{$key}{submitted};

           $diff_a = ( $time_c - $time_a ) ;
           $diff_s = ( $time_c - $time_s ) ;

           ( ${$FILE}{$key}{'atime'},${$FILE}{$key}{'stime'} ) = ($diff_a,$diff_s);

           # Set the task time
           if ( exists(${$FILE}{$key}{active_task}) ) {
             $time_at=${$FILE}{$key}{active_task} ;
           } else {
             print "Missing: active_task $key \n";
           };
           if ( exists(${$FILE}{$key}{complete_task}) ) {
             $time_ct=${$FILE}{$key}{complete_task} ;
           } else {
             print "Missing: complete_task $key \n";
           };

           ${$FILE}{$key}{'atime_t'} = ( $time_ct - $time_at ) ;

         } ;

    } ;

 } ;


 # Print the result
 $nfiles = scalar(@FILES) ;

 $file1=$FILES[0];

  
 if ( $nfiles eq 1 ) {
    print "Analyzing times from: $file1\n";
 } else {
   print "Comparing times from: \n";
   foreach $FILE (@FILES) { print "$FILE\n"; } ;
 } ;
 print "\n";

 print " Times are given as (task/job/job+queue) in seconds as time difference between:\n";
 print "  Task: complete and active semaphore file generation times \n";
 print "   Job: complete and active semaphore times when noticed by mSMS\n";
 print "   Job: complete and submitted semaphore times when noticed by mSMS\n";
 print "\n";
   
 LOOP : for $key ( sort keys %${file1} ) {

        next LOOP unless ( $key =~ /$grep_this/ ) ;
        #print "$key ${$file1}{$key}{node_type} \n";

        unless ( exists ${$file1}{$key}{node_type} ) {
            #print "Missing $key \n";
            ${$file1}{$key}{node_type} = 'empty' ;
           (${$file1}{$key}{'atime'},${$file1}{$key}{'stime'} ) = (0,0);
        } ;

        $txt  = "";
        $info = "";
        if ( ${$file1}{$key}{node_type} eq "job"    ) {
           $txt = "   Job $key:";
           ${$file1}{$key}{'complete_DTG'} = 'Still running' unless ( exists(${$file1}{$key}{'complete_DTG'}));
           if ( $nfiles == 1 && $debug == 1 ) { 
             local ($at,$ct) ;
             $at = gmtime(${$file1}{$key}{'active_task'}) ;
             $ct = gmtime(${$file1}{$key}{'complete_task'}) ;
             $info = "| $at - $ct / ";
             $info = $info."${$file1}{$key}{'submitted_DTG'}/${$file1}{$key}{'active_DTG'} - ${$file1}{$key}{'complete_DTG'} ";
           };
        } ;

        if ( ${$file1}{$key}{node_type} eq "family" ) { 
           $txt = "Family $key:";
           if ( ${$file1}{$key}{'nmember'} == 1 ) { next LOOP ; } ;
        } ;

        if ( ${$file1}{$key}{node_type} eq "empty"  ) { $txt = " Empty $key:"; } ;

        foreach $FILE (@FILES) {
           if ( exists ${$FILE}{$key}{'atime'}) {
              if ( exists ${$FILE}{$key}{'atime_t'}) {
                $txt = $txt."   ${$FILE}{$key}{'atime_t'}/${$FILE}{$key}{'atime'}/${$FILE}{$key}{'stime'} s";
              } else {
              $txt = $txt."  ${$FILE}{$key}{'atime'}/${$FILE}{$key}{'stime'} s";
              } ;
           } else {
              $txt = $txt."   ----- s";
           } ;
           if ( exists ${$FILE}{$key}{running} && ! ( $debug == 1 && $nfiles == 1 )) {
              $txt = $txt." Still running";
           } ;
        } ;

        print " $txt $info\n";
 };


############################
############################
############################
sub get_family_times() {

  %submitted= ();
  %active   = ();

  for $path ( sort keys %${key} ) {
      $submitted{$path} = ${$key}{$path}{'submitted'};
      $active{   $path} = ${$key}{$path}{'active'};
  } ;

  $test='submitted';
  ($stime,$nmember)= &sumup;

  $test='active';
  ($atime,$nmember) = &sumup;

  return($atime,$stime,$nmember) ;
}

#----------------------------------------------------------------------#
##  FUNCTION:  hashValueAscendingNum                                    #
##                                                                      #
##  PURPOSE:   Help sort a hash by the hash 'value', not the 'key'.     #
##             Values are returned in ascending numeric order (lowest   #
##             to highest).                                             #
##----------------------------------------------------------------------#
#
sub hashValueAscendingNum {
  ${$test}{$a} <=> ${$test}{$b};
}
#
#
#   #----------------------------------------------------------------------#
#   #  FUNCTION:  hashValueDescendingNum                                   #
#   #                                                                      #
#   #  PURPOSE:   Help sort a hash by the hash 'value', not the 'key'.     #
#   #             Values are returned in descending numeric order          #
#   #             (highest to lowest).                                     #
#   #----------------------------------------------------------------------#
#
sub hashValueDescendingNum {
  ${$test}{$b} <=> ${$test}{$a};
}
#
#
sub sumup {

  local $ltime = 0;
  local @ORDER = ();

  # Create a sorted list 
  foreach $path ( sort hashValueAscendingNum(keys(%${test}))) {
     @ORDER=(@ORDER,$path);
  } ;

  $p1 = $ORDER[0] ;
  $si = scalar(@ORDER) ;

  #unless ( exists(${$key}{$p1}{'complete'}) ) { return(-1,$si) ; } ;
  ${$key}{$p1}{'complete'} = $file_mtime unless ( exists(${$key}{$p1}{'complete'}) ) ;

  #print "$si @ORDER  \n";
  $ts = ${$key}{$p1}{$test} ;
  $tc = ${$key}{$p1}{'complete'} ;
  #print "$si  $p1 $ts - $tc \n";

  LOOP_I : for ($i = 1 ; $i < $si ; $i++) {

        $p2 = $ORDER[$i] ;

  #      unless ( exists(${$key}{$p2}{'complete'}) ) { return(-1,$si) ; } ;
        ${$key}{$p2}{'complete'} = $file_mtime unless ( exists(${$key}{$p2}{'complete'}) ) ;
        unless ( exists(${$key}{$p2}{'complete'}) ) { next LOOP_I } ;

        #print "Check  #${$key}{$p2}{$test}# #${$key}{$p2}{'complete'}#  \n";
        #print "Check ts  #$ts# \n";
        #print "Check tc  #$tc# \n";

        if ( $ts le ${$key}{$p2}{$test} &&
             $tc ge ${$key}{$p2}{'complete'}   ) {
             # Current covers the next
        #print "No action $ts - $tc \n";
             next LOOP_I ;
        } ;

        if ( $tc ge ${$key}{$p2}{$test} ) {
             # Next starts before current ends
             $tc = ${$key}{$p2}{'complete'} ;
        #print "Update $ts - $tc \n";
             next LOOP_I ;
        } else {
             # Next starts after current ends
             $ltime =$tc - $ts + $ltime ;
             $ts = ${$key}{$p2}{$test} ;
             $tc = ${$key}{$p2}{'complete'} ;
        #print "Acc $ltime, $ts - $tc \n";
             next LOOP_I ;
        } ;
  } ;

  $ltime = $tc - $ts + $ltime ;
        #print "Final $ltime, $ts - $tc \n";

  return ($ltime,$si) ;

}
############################
############################
############################
sub add_time {

 # Get family and add/update
 @path = split('/',$path); 
 pop(@path);
 @cp = ();
 CP :foreach $cp (@path) { 

    @cp=(@cp,$cp);
    $ccp=join('/',@cp);

    if ( exists (${$FILE}{$ccp}{node_type})) {
       if (  ${$FILE}{$ccp}{node_type} eq "job" ) { 
          next CP ;
       } ;
    } ;

    ${$FILE}{$ccp}{node_type} = "family";
    ${$FILE}{$ccp}{$status}   = $time;
    ${$FILE}{$ccp}{running}   = 1 if ( $running eq 1 ) ; 
    ${$FILE}{$ccp}{$path}     = 1;
    ${$ccp}{$path}{$status}   = $time ;

 } ;

 # Update the total time
 ${$FILE}{'Total'}{$status}   = $time;
 ${$FILE}{'Total'}{node_type} = "family";
 ${$FILE}{'Total'}{$path}     = 1;
 ${$FILE}{'Total'}{running}   = 1 if ( $running eq 1 ) ; 
 ${'Total'}{$path}{$status}   = $time ;

} ;
