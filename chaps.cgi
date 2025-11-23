#!/usr/bin/perl -w

use strict;

use lib qw(.);

use CHAPS;
use CGI::Carp qw(fatalsToBrowser carpout warningsToBrowser);

$ENV{PATH} = "/bin:/usr/bin";

BEGIN {
    do "Fawww_begin.pl";
}

my $chaps = new CHAPS;

$chaps->run();

