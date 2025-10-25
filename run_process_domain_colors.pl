#!/usr/bin/perl -w

use strict;

require "./fawww_defs.pl";
require "./fawww_subs.pl";
require "./process_domain_colors.pl";

my %run_href = ();
my %run_data = ();

my $pgm="psi2sw";

my $run_output = "";

$run_href{iter_box} = 0;
$run_href{submit_dest} = "fasta_www.cgi";
$run_href{out_fmt} = "blast";

while (my $line = <>) {
  $run_output .= $line;
}

print process_domain_colors(\%run_href, \%run_data, $pgm, $run_output);

