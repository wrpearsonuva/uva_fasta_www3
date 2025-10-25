#!/usr/bin/perl -w

use strict;

use lib qw(.);

use CHAPS;
use CGI::Carp qw(fatalsToBrowser carpout warningsToBrowser);

$ENV{PATH} = "/bin:/usr/bin";

use Fawww_begin;

Fawww_begin::begin_log();

my $chaps = new CHAPS;

$chaps->run();

