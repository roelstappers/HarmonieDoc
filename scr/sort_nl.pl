#!/usr/bin/perl

##$nle = '&END';
$nle = '/';
$innl = 0;
while ( <> ) {
   if (not $innl and /^\s*\&(\w+)\s*$/) {
      $nlnam = $1;
      $body = $_;
      $innl = 1;
   } elsif ( $innl and /^\s*$nle\s*$/ ) {
      $NL{$nlnam} .= $body . $_;
      $innl = 0;
   } elsif ($innl) {
      $body .= $_;
   }
}
for ( sort keys %NL ) {
   @_ = split("\n",$NL{$_});
   $nam = shift(@_);
   $end = pop(@_);
   $nl = ( $#_ >= 0 ? "\n" : "" );
   print "$nam\n" . join("\n",sort(@_)) . "$nl$end\n";
}
