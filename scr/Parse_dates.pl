#!/usr/bin/perl -w 

$string = $ARGV[0] or die "\n";
$dtg    = $ARGV[1] or die "\n";

%keywords=(
  '@YYYY@' => substr($dtg,0,4),
  '@MM@'   => substr($dtg,4,2),
  '@DD@'   => substr($dtg,6,2),
  '@HH@'   => substr($dtg,8,2),
);

for $key ( keys %keywords ) { $string = &change_key($key,$keywords{$key},$string   ); } ;

print "$string\n" ;

######################################################

sub change_key(){

 my ($old,$new,$tmp) = @_ ;

 $lo = length($old)-2;
 $ln = length($new);

 while ( $ln lt $lo ) { 
    $new = "0".$new;
    $ln = length($new);
 } ;

 $tmp =~ s/$old/$new/g ;

 return $tmp ;

}
