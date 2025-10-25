#!/usr/bin/perl -Tw

## more flexible version of entrez.fcgi that calls entrez.fcgi for NCBI sequences, but calls Uniprot for sp|/tr|
## db=Protein&amp;cmd=Search&amp;term=P42860.2&amp;doptcmdl=DocSum"
#

use strict;

use Getopt::Long;
use Pod::Usage;
use URI::Escape;
use LWP::Simple;
use HTML::Entities;
use CGI::Carp qw(fatalsToBrowser carpout warningsToBrowser);

use CGI qw(header param start_html end_html redirect);

my $q = new CGI;;

my @arg_names = ();
my %args = ();
my @arg_list = ();

@arg_names = $q->param();
%args = map { $_ => $q->param($_) } @arg_names;

if (($args{db} =~ m/Protein/) && ($args{term} =~ m/^([A-Z]\w{5})\.?\d*$/)) {
  my $url = "http://www.uniprot.org/uniprot/";
  $url .= $args{term};
  print $q->redirect(-url=>$url);
}
else {
  my $url = "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?";
  @arg_list = map {"$_=$args{$_}"} @arg_names;

  $url .= join('&amp;',@arg_list);
  print $q->redirect(-url=>$url);
}
