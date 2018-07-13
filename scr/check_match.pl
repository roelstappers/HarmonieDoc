#!/usr/bin/perl -w

require("$ENV{HM_LIB}/scr/utils.pm");

exit 1 unless ( grep /$ARGV[1]/,split(':',&gen_list($ARGV[0])));

