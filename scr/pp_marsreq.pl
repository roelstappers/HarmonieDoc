#!/usr/bin/perl -w 

# 
# Parse a mars request/stage file and remove duplicated requests
#
# Ulf Andrae, SMHI, 2017
#

use Storable qw(dclone);


my @mars_commands=('RETRIEVE,','STAGE,') ;

my $i=0 ;
my %ret = () ;
my $mc = "";
my @skipme = () ;
my $mars_command ;

#
# Scan the input file and build the dictionary
# Every new request is a copy of the previous one
# plus the new definitions, just like MARS ...
#

SCAN_FILE : while (<STDIN>) {

 chomp ;
 $line = $_ ;
  
 if ( grep /$line/, @mars_commands ) {

   $mars_command = $line ;

   $i++ ;
 
   $ii = $i - 1 ;
   if ( exists ( $ret{$ii}) ) {
     $ret{$i} = dclone($ret{$ii}) ;
   } ;
   $ret{mc} = $line ;

   next SCAN_FILE ;
 }

 ($key,$txt) = split('=',$line ) ;
 $txt =~ s/,//;
 $txt =~ s/( ){1,}$//;
 $txt =~ s/^( ){1,}//;
 $key =~ s/ //g;
 $ret{$i}{$key} = $txt ;

} ;

#
# Match different requests and delete duplicates
#

JL : for ( $j = 1 ; $j <= $i ; $j++ ) {

 #unless ( exists( $ret{$j} ) ) { next JL ; } 
 next JL if ( grep /$j/,@skipme ) ;

 for ( $k = $j+1 ; $k <= $i ; $k++ ) {

   $jj = 0 ;
   $kk = 0 ;
   for my $val ( sort keys %{ $ret{$j} } ) {
     $jj++ ;
     unless ( exists ( $ret{$j}{$val})) { &printme($j) ; die "Missing $val for $j \n"; }
     unless ( exists ( $ret{$k}{$val})) { &printme($j) ; die "Missing $val for $k \n"; }
     if ( $ret{$j}{$val} eq $ret{$k}{$val} ) { 
       #print "Match for $val\n";
       #print "$j:  $ret{$j}{$val}\n";
       #print "$k:  $ret{$k}{$val}\n";
       $kk++ ;
      } 
   } 

   if ( $ret{mc} =~ /STAGE/ and $ret{$j}{DATABASE} =~ /fdb/ ) {
     push(@skipme,$j) unless ( grep /$j/,@skipme ) ;
   }
   if ( $jj == $kk ) { 
     #print "Delete record $j:\n" ;&printme($j) ; 
     #print "Keep record $k:\n" ;&printme($k) ; 
     #delete($ret{$j}) ; 
     push(@skipme,$j) unless ( grep /$j/,@skipme ) ;
     next JL ; 
   } ;


 }
}

$nk = keys %ret ;
$nk-- ;

print "We have $nk request to handle \n";
#
# Print the final request
#
@types    = () ;
@levtypes = () ;
@numbers  = () ;
@dates    = () ;
@times    = () ;

for ( $j = 1 ; $j <= $nk ; $j++ ) {

      next if ( grep /$j/,@skipme ) ;

      #print "Handle record $j\n"; 
      #&printme($j) ;

      # Extract TYPE/LEVTYPE/STEP/DATE/TIME to be able 
      # to separate the requests

      $stream =$ret{$j}{STREAM} ;
      $type =$ret{$j}{TYPE} ;
      $levtype =$ret{$j}{LEVTYPE} ;
    
      if ( $ret{$j}{STEP} eq '000' ) {
       $step = $ret{$j}{STEP} ;
      } else {
       $step = 'ALL' ;
      }

      if ( $ret{$j}{DATE} =~ /\// ) {
       $date = 'ALL' ;
      } else {
       $date = $ret{$j}{DATE} ;
       push(@dates,$date) unless ( grep /$date/,@dates ) ;
      }

      if ( $ret{$j}{TIME} =~ /\// ) {
       $time = 'ALL' ;
      } else {
       $time = $ret{$j}{TIME} ;
       push(@times,$time) unless grep /$time/,@times   ;
      }

      # Store ensemble members
      if ( $type eq 'PF' ) {
        @numbers = split( '/', $ret{$j}{NUMBER} ) ;
      }

      if ( $mars_command =~ /STAGE/ ) {
       $tmp = "${stream}_${type}_${levtype}_${step}";
      } else {
       $tmp = "${stream}_${type}_${levtype}_${step}_${date}_${time}";
      }

      push (@types,$tmp) unless grep /$tmp/,@types  ;
      if ( exists(${$tmp}{1}) ) {
       ${$tmp}{n} += 1 ;
      } else {
       ${$tmp}{n} = 1 ;
      }

      $n = ${$tmp}{n} ;
      #print "TAG:$tmp $n\n";
      for my $val ( sort keys %{ $ret{$j} } ) {
        ${$tmp}{$n}{$val} = $ret{$j}{$val};
        #print "    $val:${$tmp}{$n}{$val}\n";
      }

} 

$dates    = scalar(@dates) ;
$levtypes = scalar(@dates) ;
$numbers  = scalar(@numbers) ;
$times    = scalar(@times) ;


$maxreq   = $ENV{EC_total_tasks} or $maxreq = 18;
print "Max requests:$maxreq\n";
print "Request types:@types \n\n";

@an_000_req  = grep/AN_[A-Z]{2,}_000/,@types ; print "an_000_req:@an_000_req \n";
@fc_sfc_all_req  = grep/FC_SFC_ALL/,@types ; print "fc_sfc_all_req:@fc_sfc_all_req \n";
@fc_ml_all_req  = grep/FC_ML_ALL/,@types ; print "fc_ml_all_req:@fc_ml_all_req \n";
@cf_all_req  = grep/CF_[A-Z]{2,}|PF_SFC/,@types ; print "cf_all_req:@cf_all_req \n";
@pf_all_req  = grep/PF_[A-Z]{2,}_ALL/,@types ; print "pf_all_req:@pf_all_req \n";

$k=0;
&print_single(@an_000_req) if ( scalar(@an_000_req) > 0 ) ;
&print_single(@fc_sfc_all_req) if ( scalar(@fc_sfc_all_req) > 0 ) ;
&print_single(@cf_all_req) if ( scalar(@cf_all_req) > 0 ) ;
&print_split_member(@pf_all_req) if ( scalar(@pf_all_req) > 0 ) ;
&print_split_step(@fc_ml_all_req) if ( scalar(@fc_ml_all_req) > 0 ) ; 


#
#------------------------------------------------------------------------------------------------------
#

sub print_split_step{

 @tmp = @_ ;
 $max_req_avail = $maxreq - $k ;
 $n = scalar(@tmp) ;

 $max_step_req = int($max_req_avail/$n) ;
 #print"max_req_avail:$max_req_avail,max_step_req,$max_step_req\n";

 for $tmp (@tmp) {

  if ( $mars_command =~ /STAGE/ ) {
   $ntask = 0 ;
   $rest  = 0 ;
   $maxsteps = 1;
  } else {
   @steps = split( '/', ${$tmp}{1}{STEP} ) ;
   $maxsteps = scalar(@steps) ;
   #print"maxsteps:$maxsteps,max_step_req,$max_step_req\n";
   if ( $maxsteps > $max_step_req ) {
    $ntask = int($maxsteps / $max_step_req ) ;
    $rest  = $maxsteps % $max_step_req ;
    #print"ntask:$ntask rest:$rest\n";
   } else {
    $ntask = 1 ;
    $rest  = 0 ;
   }
  }

  $i=0 ;
  while ($i < $maxsteps ) {

   if ( $ntask > 0 ) {

    $step=shift(@steps);
    $i += 1;

    $j=1 ;
    while ( $j < $ntask ) {
     $step="$step/".shift(@steps);
     $i += 1;
     $j += 1;
    }
    if ( $rest > 0 ) {
     $step="$step/".shift(@steps);
     $i += 1;
     $rest -= 1 ;
    }
   } else {
    $step="";
    $i += 1;
   }

   $k += 1;

   print "Write $tmp to mars.$k,$step\n";

   open REQ, ">mars.$k";

   for ( $j = 1 ; $j <= ${$tmp}{n} ; $j++ ) {
     ${$tmp}{$j}{STEP}="$step" if ( $ntask > 0 ) ;
     print REQ "$ret{mc}\n";
     for $val ( sort keys %{ ${$tmp}{$j} } ) {
       if ( $val eq "TYPE" ) {
        print REQ "  $val = ${$tmp}{$j}{$val}\n";
       } else {
        print  REQ"  $val = ${$tmp}{$j}{$val},\n";
       }
     }
   }

   close REQ ;

  }

 } 

}


#

#------------------------------------------------------------------------------------------------------
#
#
#------------------------------------------------------------------------------------------------------
#

sub print_split_member{

 $tmp = pop @_ ;

 $maxmember = $numbers;
 $max_ens_req = $maxreq - $k ;
 $rest  = $maxmember % $max_ens_req ;
 $ntask = int($maxmember / $max_ens_req ) ;

 $i=0 ;
 while ($i < $maxmember ) {

  if ( $ntask > 0 ) {

   $number=shift(@numbers);
   $i += 1;

   $j=1 ;
   while ( $j < $ntask ) {
    $number="$number/".shift(@numbers);
    $i += 1;
    $j += 1;
   }
   if ( $rest > 0 ) {
    $number="$number/".shift(@numbers);
    $i += 1;
    $rest -= 1 ;
   }
  } else {
   $number=shift(@numbers);
   $i += 1;
   $rest -= 1 ;
  }

  $k += 1;

  print "Write $tmp to mars.$k ,$number \n";

  open REQ, ">mars.$k";

  for ( $j = 1 ; $j <= ${$tmp}{n} ; $j++ ) {
    ${$tmp}{$j}{NUMBER}="$number";
    print REQ "$ret{mc}\n";
    for $val ( sort keys %{ ${$tmp}{$j} } ) {
      if ( $val eq "TYPE" ) {
       print REQ "  $val = ${$tmp}{$j}{$val}\n";
      } else {
       print  REQ"  $val = ${$tmp}{$j}{$val},\n";
      }
    }
  }

  close REQ ;

 }

}

#
#------------------------------------------------------------------------------------------------------
#

sub print_single {

 @TMP=@_ ;

 if ( scalar(@TMP) > 0 ) {

  $k += 1 ;

  open REQ, ">mars.$k";

  for $tmp (@TMP) {

   print "Write $tmp to mars.$k \n";
 
   for ( $j = 1 ; $j <= ${$tmp}{n} ; $j++ ) {
   print REQ "$ret{mc}\n";
   for $val ( sort keys %{ ${$tmp}{$j} } ) {
    if ( $val eq "TYPE" ) {
     print REQ "  $val = ${$tmp}{$j}{$val}\n";
    } else {
     print  REQ"  $val = ${$tmp}{$j}{$val},\n";
    }
   }
  }

  }

  close REQ ;

 }
}

#
#------------------------------------------------------------------------------------------------------
#

sub printme {

 my $l = pop @_ ;
   for my $val ( sort keys %{ $ret{$l} } ) {
     print " $val = $ret{$l}{$val} \n";
   } 
   print"\n";

}

