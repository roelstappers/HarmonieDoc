# CollectLogs.pl
# A (previous) family name is in environment variable FROM
# (may contain "../" and "./", but these are useless and will be stripped).
# Collect all log files from that previous family, depth is irrelevant.
# Write them to $CYCLEDIR/HM_$FROM_$DTG.html if $CYCLEDIR is a directory,
# else to HM_$FROM.html or to HM_${FROM}_${WHEN}.html if $WHEN is set.
# The files $CYCLEDIR/HM_$FROM_$DTG.html are copied to $ARCHIVE
# author: Gerard Cats, 29 June 2000. 
# Modified and simplified for Harmonie by Trygve Aspelien (met.no) in September 2010,
# and by Ole Vignes in December 2012.

use File::Find;
use Time::Local;

push @INC,split(":",$ENV{PATH});

# get the required environment variables
foreach $var ( qw/ DTG EXP FROM CYCLEDIR JOBOUTDIR HM_DATA ARCHIVE_ROOT /) {
   die "$var not in the environment; stopped" unless (exists $ENV{$var});
   $$var=$ENV{$var};
}
if ( exists $ENV{WHEN} ) {
   $when = '_' . $ENV{WHEN};
} else {
   $when = '';
}

# Define log archive
$archive="$ARCHIVE_ROOT/log";
system("mkdir -p $archive") unless (-d $archive);


# a delay to allow files to be completed
sleep 5;

# find all files that qualify

$from = $FROM;
$from =~ s|\.||g;
$from =~ s|\/||g;

foreach $dir ( "$JOBOUTDIR/$EXP" ) {
  find(\&find_FROM,$dir);   # fills @path
}

## DEBUG:
foreach $dir ( @path ) {
  print "Looking in path: '$dir'\n";
}

unless ( @path ) {
   print "No valid paths to search for log files, exit!\n";
   exit 0;
}

find(\&wanted,@path);

# Open the document: $doc, with a header.
# If DTG is legal, use this as a time stamp, else
# time stamp with $when. Rename old files with creation
# time times tamp

if ( $DTG =~ /^\d{10}$/ ) {
  $doc = "$archive/HM_${from}_$DTG.html";
  if ( -s $doc ) { 
    local $fs = (stat($doc))[9];
    local ($sec,$min,$hour,$mday,$mon,$year) = (gmtime($fs))[0..5];
    $tstamp=sprintf("%04d%02d%02d-%02d%02d%02d", $year+1900, $mon+1, $mday, $hour,$min,$sec);
    $docold = "$archive/HM_${from}_${DTG}_${tstamp}.html";

    rename $doc,$docold ;
  } ;
} else {
  $doc = "$archive/HM_${from}${when}.html";
}

open(DOC,">$doc") || die "$0: cannot open $doc: $!; stopped";
print DOC html_head("loggings from $from at $DTG");
&DOC_intro;

# make a sorted list of all files found
@files=keys(%mtime);
@sorted=sort({$mtime{$a}-$mtime{$b}} @files);

# Print a list of the sorted files
print DOC "<UL>\n";
foreach $file (@sorted) {
   print DOC "<LI>", html_hrefA($file), "\n";
}
print DOC "</UL>\n";

# create a list of failures (nb overridden if a later succes was reported!)
%failures=();
$nfailed=0;

FILE:
foreach $file (@sorted) {

   # read the file, remember failure as shown by `ERROR:SMSABORT_HM'
   $thisfailed=0;
   print DOC "<HR>";
   open(LOG,"<$file") || ( print DOC "cannot open $file\n" && next FILE );
   $task=$file; $task =~ s/\.[0-9]+$//;
   print DOC html_HDR(3,$file);
   print DOC "<PRE>\n";
   while (<LOG>) {
      print DOC;
      $thisfailed=1 if ( /^ERROR:SMSABORT_HM$/ );
   }
   print DOC "</PRE>\n";
   close(LOG);

   # update the list of failed tasks; remove file if successful
   if ( $thisfailed  ) {
      $nfailed++ if ( ! defined( $failures{$task} ) );
      $failures{$task} = $file;
   } else {
      $nfailed-- if ( $nfailed && defined( $failures{$task} ) );
      delete $failures{$task};
   }
}

# trailers, and close file

if ( $nfailed ) {
   print DOC html_HDR(1,"failed");
   print DOC "(a failure is not listed if a later attempt was successful)\n";
   print DOC "<UL>\n";
   while (($task,$file) = each %failures ) {
      print DOC "<LI>", html_hrefA($file), "\n" if ( $file );
      print STDERR "$task failed\n";
   }
   print DOC "</UL>\n";
} else {
  print DOC "\nFamily $from was complete!\n";
  unlink @sorted; # remove all files
}
print DOC &html_tail;
close(DOC);

$nfailed = 0 if $ENV{noABTonABT};
if ( $nfailed ) {
   print "##########################################################################\n";
   print "# NOTE: CollectLogs aborts because one or more tasks failed, not because #\n";
   print "# there was a problem in CollectLogs itself. If you resubmit your failed #\n";
   print "# task(s) through mXCdp, you should also requeue or resubmit CollectLogs #\n";
   print "# to continue and to have the new logs properly collected and archived.  #\n";
   print "##########################################################################\n";
}
exit $nfailed;
# ------------------------------------------------------------------------------
sub find_FROM {
# find_FROM: find directory $from below some starting directory. Fills @path.
# author: Ole Vignes, 11 Dec 2012
  if ( -d $_ and $_ eq $from ) {
    push @path, $File::Find::name;
  }
}
# ------------------------------------------------------------------------------
sub wanted{
# wanted: to be used to find files: fill %mtime: $mtime{$file}=<modification time>
# synopsis: &wanted
# author: Gerard Cats, 30 June 2000
  $mtime{$File::Find::name}=(stat(_))[9] if ( -f $_ && /\.[0-9]+$/ );
}
# ------------------------------------------------------------------------------

sub DOC_intro{
# DOC_intro: write the introduction section to file DOC
# synopsis: &DOC_intro
# author: Gerard Cats, 30 June 2000
   print DOC "<H1>log files of HARMONIE cycle $DTG</H1>\n";
   print DOC "Files are ordered according to last modification time. Reference to\n";
   print DOC html_hrefA("failed");
   print DOC "jobs (if any) is at the end of this document.\n";
}
# ------------------------------------------------------------------------------
sub html_hrefA{
# html_hrefA: make a link to within the same document
# synopsis: $line=html_hrefA($name)
# author: Gerard Cats, 30 June 2000
  my $name=shift(@_);
  local $ref=$name;
  $ref =~ s(/)(%2F)g;
  return '<A HREF="#',$ref,'">',$name,"</A>\n";
}
# ------------------------------------------------------------------------------
sub html_HDR{
# html_HDR: insert a header, with a target
# synopsis: $lines=html_HDR($level,$name)
# author: Gerard Cats, 30 June 2000
  my $lev=shift(@_);
  my $name=shift(@_);
  local $ref=$name;
  $ref =~ s(/)(%2F)g;
  return "<H$lev>", '<A NAME="',$ref,'">',$name,"</A></H$lev>\n";
}
# ------------------------------------------------------------------------------
sub html_head{
# html_head: write the html headers
# synopsis: $lines=html_head($title);
# author: Gerard Cats, 30 June 2000
  my $title=shift(@_);
  return "<HTML><HEAD><TITLE>$title</TITLE></HEAD>\n".
   '<BODY TEXT="#000000" BGCOLOR="#E0E0FF" LINK="#0000A0" VLINK="#A00000" ALINK="#808000">'."\n".
   '<FONT SIZE=+2><A HREF="https://hirlam.org"><I>Hirlam.org</I></A></FONT>'."\n";
}
# ------------------------------------------------------------------------------
sub html_tail{
# html_tail: write the html headers
# synopsis: $line=&html_tail;
# author: Gerard Cats, 30 June 2000
  return "</BODY></HTML>\n";
}
