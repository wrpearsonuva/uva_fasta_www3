#!/usr/bin/perl -w

use strict;

use lib qw(.);

use FASTA_WWW;
use CGI::Carp qw(fatalsToBrowser carpout warningsToBrowser);

$ENV{PATH} = "/usr/bin";

sub BEGIN {
  my $DOC_ROOT=$ENV{DOCUMENT_ROOT};
#  my $DEF_ROOT = "/Library/WebServer/Documents";	# MAC OSX
# my $DEF_ROOT = "/home/wrp/public_html/fasta_www"; # xs00
# my $DEF_ROOT = "/export/home/www";		# sun3
#  my $DEF_ROOT = "/ecg/htdocs/";		# ecg
  my $DEF_ROOT = "/var/www/html";		# sun3
  $DOC_ROOT = $DEF_ROOT unless($DOC_ROOT);
  my $OK_CHARS='\"\+\-a-zA-Z0-9_.@ \/%:';
  $DOC_ROOT =~ s/[^$OK_CHARS]/_/go;
  ($DOC_ROOT) = $DOC_ROOT =~ m/^\s*(.*)/;  # de-taint and remove leading spaces
  my @TMP_ROOTL = split(/\//,$DOC_ROOT);
  my $TMP_ROOT = "/".join("/",@TMP_ROOTL[1 .. ($#TMP_ROOTL-1)])."/tmp";
#  $TMP_ROOT = "/Library/WebServer/Documents/tmp";
#  print STDERR "TMP_ROOT: $TMP_ROOT - DOCUMENT_ROOT: $DOC_ROOT\n";
#  open(LOG, ">> $TMP_ROOT/logs/errors.log") or die $!;
#  carpout(\*LOG);
}

# uncomment for debugging from command line
# use CGI;
# my $cgi_q = CGI::new();
# my $fasta = new FASTA_WWW QUERY=>$cgi_q;

my $fasta = new FASTA_WWW;

$fasta->run();

