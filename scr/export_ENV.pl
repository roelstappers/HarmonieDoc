#!/usr/bin/perl

# Dump environment (in shell syntax), but exclude some variables
# Ole Vignes, 19.12.2011

use Getopt::Std;
use strict;

our($opt_p,$opt_s);

sub Usage {
   die "Usage: $0 [-p <perl_env_file>] [-s <shell_env_file>]\n";
}

my @exclude = ( 'LOGNAME','USER','TMPDIR','SCRATCHDIR','TRUESCRATCHDIR',
	     'HISTFILE','TRUE_TMPDIR','DISPLAY','X11COOKIE','PS1','PWD',
         'BASH_FUNC__ecfs_cmd_internal',
         'BASH_FUNC_module','BASH_FUNC_ecd','BASH_FUNC_eumask', 
	     'SHELL','SHLVL','HOST','HOSTNAME','HOSTPROMPT' );

unless ( getopts('p:s:') ) {
   &Usage;
}

if ($opt_p) {
   open(PL,">$opt_p") or die "Could not write: '$opt_p'\n";
}
if ($opt_s) {
   open(SH,">$opt_s") or die "Could not write: '$opt_s'\n";
}

for my $var ( sort keys %ENV ) {
   next if ( grep /^$var$/, @exclude );
   next if ( $var =~ /\(\)$/ );   # exclude functions
   print PL "\$ENV{$var}='$ENV{$var}';\n" if ($opt_p);
   print SH "export $var=\"".$ENV{$var}."\"\n" if ($opt_s);
}

close(SH) if ($opt_s);
close(PL) if ($opt_p);
