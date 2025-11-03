#!/usr/bin/perl -w

use strict;

use lib qw(.);

BEGIN {
    do "Fawww_begin.pl";
}

use FASTA_WS;

use CGI::Carp qw(fatalsToBrowser carpout warningsToBrowser);

$ENV{PATH} = "/usr/bin";

# uncomment for debugging from command line
# use CGI;
# my $cgi_q = CGI::new();
# my $fasta = new FASTA_WWW QUERY=>$cgi_q;

my $fasta = new FASTA_WS;

$fasta->run();

