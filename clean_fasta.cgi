#!/usr/bin/perl -Tw

#  down_file.cgi  - provides automatic download of Clustal MSA, PSI-BLAST PSSM (ASN.1), or
#  HMMR HMM
#

use strict;
use lib qw(. /n_ecg/perllib/lib/perl5/site_perl);

use CGI;
use CGI::Carp qw(fatalsToBrowser carpout warningsToBrowser);
use IO::Scalar;
use File::Temp qw/ tempfile /;


$ENV{PATH} = "/usr/bin";

BEGIN {
    do "Fawww_begin.pl";
}

use vars qw($DEF_UNLINK $BIN_DIR $BL_DB_DIR $BL_DB_NT_DIR $BL_BIN_DIR
	    $BL_DATA_DIR $TMP_DIR );

my $q = new CGI;

my $query_file = $q->param("query_file") || "";
my $query = $q->param("query") || "";
my $ucsc_clean = $q->param("meme_chr") || 0;

my $sequence = get_query($q, 'query', 'query_file');

unless ($sequence) {
    print $q->header();
    print $q->start_html("No FASTA file");
    print "<pre>\n";
    for my $p ( $q->param() ) {
	print "$p : ".$q->param($p)."\n";
    }
    print $q->end_html();
    exit 0;
}

print $q->header(-type => 'text/plain');

my @lines = split(/\n/,$sequence);

for my $line ( @lines ) {
  chomp($line);
  if ($line =~ m/^>/) {
    if ($ucsc_clean) {
      $line =~ s/^>\S+\s+range=(\S+)\s.*$/>$1/;
    }
    else {
      $line =~ s/\s/_/g;
    }
    print "$line\n";
  }
  else {print "$line\n";}
}
exit;

sub get_query {
  my ($q, $name, $file)  = @_;


  unless ($q->param($file) || $q->param($name)) {return "";}

#
# file_name trumps name, but needs type
#
  if ($q->param($file)) {
    my $qfh;
    $qfh = $q->upload($file);
    unless($qfh) {return "";}

    my $q_library = "";
    while (<$qfh>) {
      $q_library .= $_;
    }
    close($qfh);
    $q_library =~ s/\r\n/\n/gos;
    $q_library =~ s/\r/\n/go;
    return $q_library;
  }
  else {			# use param($name), not $param($file)
    my $query = $q->param($name);
    $query =~ s/\r//go;
    return $query . "\n";
  }
}

sub octet_header {
    my ($q, $filename) = @_;
    print $q->header(-type =>"application/octet-stream",
		     'Content-Disposition'=>"filename=$filename");
}

sub text_header {
    my ($q, $filename) = @_;
    print $q->header(-type =>"text/plain",
		     'Content-Disposition'=>"filename=$filename");
}

