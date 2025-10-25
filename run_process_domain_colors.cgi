#!/usr/bin/perl -w

use strict;
use CGI qw(header param end_html);

my $TMP_DIR = "";

require "./fawww_defs.pl";
require "./fawww_subs.pl";
require "./process_domain_colors.pl";

my %run_href = ();
my %run_data = ();

my $pgm="psi2sw";

my $q = new CGI;
my @arg_names = $q->param();

%run_data = map { $_ => scalar($q->param($_)) } @arg_names;

my $run_output = "";

$run_href{iter_box} = 0;
$run_href{submit_dest} = "fasta_www.cgi";
$run_href{out_fmt} = "blast";

if ($run_data{'file'}) {
  my $file_name = $run_data{'file'};
  if ($TMP_DIR) {
    $file_name = "$TMP_DIR/$file_name";
  }
  open(my $fd, $file_name) || die "cannot open $file_name";
  while (my $line = <$fd>) {
    $run_output .= $line;
  }
  close($file_name);
}
else {
  while (my $line = <>) {
    $run_output .= $line;
  }
}

exit(1) unless ($run_output);

print process_domain_colors(\%run_href, \%run_data, $pgm, $run_output);

