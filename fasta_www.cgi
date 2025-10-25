#!/usr/bin/perl -w

use strict;

use lib qw(.);

use FASTA_WWW;

use CGI::Carp qw(fatalsToBrowser carpout warningsToBrowser);

$ENV{PATH} = ".:/bin:/usr/bin:/seqprg/bin";

use Fawww_begin;

Fawww_begin::begin_log();

# uncomment for debugging from command line
# use CGI;
# my $cgi_q = CGI::new();
# my $fasta = new FASTA_WWW QUERY=>$cgi_q;

my $fasta = new FASTA_WWW;

$fasta->run();

