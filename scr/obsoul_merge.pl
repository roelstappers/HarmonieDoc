#!/usr/bin/perl -w

#------------------------------------------------------------------------------------+
#OBSOUL merge  script							             |
#------------------------------------------------------------------------------------+
#Script joins small obsoul files together and creates a big obsoul file		     |
#										     |
#Switches of script							             |
# -files filename       - file filename contains a file list which will be join      |
#                         together     						     |
# -obsoul newobsoulfile - created obsoul filw from small obsouls with path     	     |
#										     |
# szabola 2008.10								     |
#------------------------------------------------------------------------------------+

#modules
use POSIX;

#-------------------------------------------+
# Read script parameters                    |
#-------------------------------------------+
#checking parameters
$argnum=0;
for $arg (@ARGV)
  {
    #file which contain files which we want to join
    if ($arg eq '-files')
     {
       $LISTFILE=$ARGV[$argnum+1];
       chomp($LISTFILE);
       if (substr($LISTFILE,0,1) eq '-')
         {
            $error=1;
         }
       $error=4   if length($LISTFILE) eq 0;
       # check existence of LISTFILE
       die "\n LISTFILE $LISTFILE does not exist \n\n" if (! -e $LISTFILE);
     }
    #obsoul file which created from small obsouls 
    if ($arg eq '-obsoul')
     {
       $OBSOUL_FILE = $ARGV[$argnum+1];
       chomp($OBSOUL_FILE);
       if (substr($OBSOUL_FILE,0,1) eq '-')
         {
            $error=1;
         }
       $error=4   if length($OBSOUL_FILE) eq 0;
     }

    $argnum++;
  }

if ($argnum eq 0 )
  {
     print "Usage: ./obsoul_merge.pl -obsoul OBSOUL -files LISTFILE\n\tOBSOUL - obsoul file to be created from small obsoul files with path. List of small obsoul files must be in LISTFILE.\n\tLISTFILE - a file which contains a list of files to be joined\n";
     exit;
  }

#if given script switches are wrong
if (defined($error))
  {
     #if wrong usage of script switches
     if ($error eq 1)
       {
         $errormsg = "Error! Switches:\n";
         $errormsg.= "\t-obsoul     - file to create\n";
         $errormsg.= "\t-files    - a file which contain name of files to merge \n";
       }
     if ($error eq 4)
       {
         $errormsg = "Error! New OBSOUL file is missing (-obsoul switch)!\n";
       }
     print $errormsg; 
     
     exit;
  }

#-------------------------------------------+
# Opening FILELIST file and read its content|
#-------------------------------------------+
open (LF,"<$LISTFILE") or die "\nCan't open LISTFILE $LISTFILE\n\n";
  @obslist=<LF>;
close (LF);
#-------------------------------------------+
# Selecting by given parameters		    |
#-------------------------------------------+
#These rows are not essential
print "====================================================\nMerge OBSOUL files  ";
print "\n----------------------------------------------------\n";
print "  -----> OBSOUL file will be $OBSOUL_FILE\n";

$starttime = time;

#cycle for small obs files
$filenum=0;
for $currentfile (@obslist)
  {
     #Open current file
     open (CURRFILE,"<$currentfile") or die "\n Can't open file $currentfile for merge\n\n";
     #Open big obsoul
     if ($filenum eq 0)
       {
         open (OBSOUL,">$OBSOUL_FILE") or die "\n Can't open output file $OBSOUL_FILE\n\n";
       }
     else
       {
	 open (OBSOUL,">>$OBSOUL_FILE") or die "\n Can't open output file $OBSOUL_FILE for append\n\n"; 
       }
     $rownum=0;   
     while( $line = <CURRFILE> )
       {
          if ($filenum eq 0 and $rownum eq 0)
            {
		print {OBSOUL} $line;
            } 
          if ($rownum gt 0)
            {
	        print {OBSOUL} $line;	
            }
          $rownum++;
       }
  
     $filenum++;
 
     close(CURRFILE);
     close(OBSOUL);
  }

#these rows are not essential
print "  -----> OBSOUL file is ready...\n";

$endtime = time;

print "----------------------------------------------------\n";
print "  Running time : ".($endtime-$starttime)." secs\n";

#script end with big OK
exit;
