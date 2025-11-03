#!/usr/bin/perl -w

use strict;

use lib qw(.);

BEGIN {
    do "Fawww_begin.pl";
}

use FASTA_WWW;

$ENV{PATH} = ".:/bin:/usr/bin:/seqprg/bin";

# uncomment for debugging from command line
# use CGI;
# my $cgi_q = CGI::new();
# my $fasta = new FASTA_WWW QUERY=>$cgi_q;

my $fasta = new FASTA_WWW;

$fasta->run();

