
## use in BEGIN {do Fawww_begin.pl;}

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser carpout warningsToBrowser);

  my $DOC_ROOT=$ENV{DOCUMENT_ROOT};
  my $DEF_ROOT = "/var/www"; # ex01/ex02
  $DOC_ROOT = $DEF_ROOT unless($DOC_ROOT);
  my $OK_CHARS='\"\+\-a-zA-Z0-9_.@ \/%:';
  $DOC_ROOT =~ s/[^$OK_CHARS]/_/go;
  ($DOC_ROOT) = $DOC_ROOT =~ m/^\s*(.*)/;  # de-taint and remove leading spaces
  my @TMP_ROOTL = split(/\//,$DOC_ROOT);
  my $TMP_ROOT = "/".join("/",@TMP_ROOTL[1 .. ($#TMP_ROOTL-1)])."/tmp/www";

  if (defined($ENV{FASTA_TMP_ROOT})) {
    $TMP_ROOT=$ENV{FASTA_TMP_ROOT}
  }

  ## print STDERR "TMP_ROOT0: $TMP_ROOT - DOCUMENT_ROOT: $DOC_ROOT\n";
  ## $TMP_ROOT = "/var/tmp/www";
  ## print STDERR "TMP_ROOT: $TMP_ROOT - DOCUMENT_ROOT: $DOC_ROOT\n";

  open(LOG, ">> $TMP_ROOT/logs/errors.log") or die "$TMP_ROOT $!";
  carpout(\*LOG);
