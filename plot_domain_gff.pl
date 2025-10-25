#!/usr/bin/perl -w
#
# plot_domain_gff.cgi provides genomic gff coordinates for alignments
# to exons.  It does not provide any graphics, simply output in gff format for the alignment
#
# derived from plot_domain6t.cgi
#
# args:
#
#  q_name - query_acc
#  l_name - library_acc
#
#  pgm = program used 
#
#  q_cstart - query coord start (typically 1)
#  q_cstop - n0 - query length
#
#  l_cstart - lib coord start (typically 1)
#  l_cstop - n1 - lib length
#
#  q_astart - query align start  (need q_astart, q_astop, l_astart, l_astop)
#  q_astop - query align stop
#
#  l_astart= lib align start 
#  l_astop= lib align stop 
#
#  regions -- same as annotations on alignment
#  doms -- domains on (library) sequence
#

use strict;
use Getopt::Long;
use Pod::Usage;
use URI::Escape;
use URI::Encode qw(uri_encode uri_decode);
use HTML::Entities;
use CGI::Carp qw(fatalsToBrowser carpout warningsToBrowser);

use CGI qw(header param start_html end_html);

my $OK_CHARS='\"\+\-a-zA-Z0-9_.@ \/%:';
my $DEF_ROOT = "/home/www";	# ex01/ex02
my $DOC_ROOT=$ENV{DOCUMENT_ROOT};
$DOC_ROOT = $DEF_ROOT unless($DOC_ROOT);
$DOC_ROOT =~ s/[^$OK_CHARS]/_/go;
($DOC_ROOT) = $DOC_ROOT =~ m/^\s*(.*)/;  # de-taint and remove leading spaces
my @TMP_ROOTL = split(/\//,$DOC_ROOT);
my $TMP_ROOT = "/".join("/",@TMP_ROOTL[1 .. ($#TMP_ROOTL-1)])."/tmp";
my $TMP_DIR="$TMP_ROOT/files";	# location for temp files
$ENV{TMP_DIR} = $TMP_DIR;

my $q = new CGI;

my @arg_names = ();
my %args = ();

################################################################
# get alignment arguments (coordinates, scores, domains)
# from file (if long) or command line
#
# place in %args{}
#
if ($q->param("file")) { # read "real" args from file, but still get embed from command line
  my $file_name = $q->param("file");
  my $file_offset = $q->param("offset");
  my $file_cnt = $q->param("a_cnt");

  open(my $ann_fd, "<", "$TMP_DIR/$file_name") || die "cannot open $TMP_DIR/$file_name";
  seek($ann_fd, $file_offset, 0);
  my $ann_line = <$ann_fd>;
  close($ann_fd);
  chomp($ann_line);
  my ($arg_cnt, $arg_line) = ($ann_line =~ m/^(\d+):::(.+)$/);

  die "arg_cnt ($arg_cnt) does not match file_cnt ($file_cnt)" if ($arg_cnt != $file_cnt);

  my @args = split(/&amp;/,$arg_line);
  for my $arg (@args) {
    my ($key, $val) = ($arg =~ m/^(\w+)=(.+)$/);
    $args{$key} = uri_decode(uri_unescape($val));
  }
}
else {
  @arg_names = $q->param();
  %args = map { $_ => scalar($q->param($_)) } @arg_names;
}

my $bed_fmt=0;
if ($q->param('bed_fmt')) { $bed_fmt=$q->param('bed_fmt');}

## parse string arguements into [q_] region/site/domain arrays
#
my ($q_region_info_r, $region_info_r, $q_dom_info_r, $l_dom_info_r);

if ($args{regions}) {
    ($q_region_info_r, $region_info_r) = parse_regions(uri_decode($args{regions}));
}
else {$region_info_r = [];}

if ($args{doms}) {
    ($q_dom_info_r, $l_dom_info_r) = parse_domains($args{doms});
} else {
    $q_dom_info_r = [];
    $l_dom_info_r = [];
}

open_gff(($args{q_cstop}-$args{q_cstart})+1,
	($args{l_cstop}-$args{l_cstart})+1,
	scalar(@{$q_dom_info_r}),
	scalar(@{$l_dom_info_r}));

if (scalar(@$q_region_info_r)) {
  print_regions_gff($args{q_name},$q_region_info_r, $bed_fmt);
}

if (scalar(@$region_info_r)) {
  print_regions_gff($args{l_name},$region_info_r, $bed_fmt);
}

close_gff();

exit(0);

#void opengff(long n0, long n1, int sq0off, int sq1off, char *xtitle, char *ytitle)
sub open_gff {
  my ($n0, $n1, $have_q_doms, $have_l_doms) = @_;

  # build a file name
  my $out_name = "domain_plot.svg";
  $out_name = canon_file_name($args{q_name}, $args{l_name});

  print $q->header() if ($ENV{DOCUMENT_ROOT});
  my $qs_name = $args{q_name};
  print $q->start_html($qs_name . " :vs: " . $args{l_name});
  print "<h3>$args{q_name} vs $args{l_name}</h3>\n";
}

sub close_gff {}

# have all the data (and length of sequence), scale it and color it

sub parse_regions {
  my $region_str = shift;

  my @regions = split(/\n\s*/,$region_str);
  $regions[0] =~ s/^\s+//;

  my @q_region_info = ();
  my @region_info = ();

  for my $region ( @regions) {
    $region =~ s/^\s+//;

    my @fields = split(/\s+:\s*/,$region);

    my %data = ();

    unless ($fields[-1] =~ m/~/ ) {
      @data{qw(descr color)} =
	@fields[-2,-1];
    } else {
      @data{qw(descr color)} =
	split(/~/,$fields[-1]);
    }

    if ($data{color}=~ m/v$/) {
      $data{color} =~ s/v$//;
      $data{virtual} = 1;
    }

    $data{descr} =~ s/^C=//;

    if ($data{descr} =~ m/^(.+)\{([^}]+)\}\s*$/) {
      $data{descr} =
	$1; $data{dom_acc} = $2;
    }

    if (defined($data{dom_acc})) {
      @data{qw(chr g_start g_end)} =
	($data{dom_acc} =~ m/([\w\.]+):(\d+)\-(\d+)/);
    }

    $data{scores} = $fields[1];

    my @scores = split(/;\s*/,$fields[1]);

    for my $score (@scores) {
      my ($key, $value) = split(/=/,$score);
      $data{$key} = $value;
    }

    @data{qw(beg0 end0 beg1 end1)} = ($fields[0] =~
				      m/Region:\s*(\d+)-(\d+):(\d+)-(\d+)$/);

    if ($fields[0] =~ m/qRegion/) {
      @data{qw(p_start p_end)} = @data{qw(beg0 end0)};
      push @q_region_info, \%data;
    }
    else {
      @data{qw(p_start p_end)} = @data{qw(beg1 end1)};
      push @region_info, \%data;
    }
  }

  return (\@q_region_info, \@region_info);
}

sub parse_domains {
  my $domain_str = shift;

  my @domains = split(/\n\s*/,$domain_str);

  my @q_domain_info = ();
  my @l_domain_info = ();

  for my $domain ( @domains) {
    $domain =~ s/^\s+//;
    next unless ($domain =~ m/^[ql]Domain/);

    my @fields = split(/\t/,$domain);

    next if ($fields[-1] =~ m/NODOM/);

    my %data = ();

    @data{qw(beg end)}  = ($fields[1]) =~ m/(\-?\d+)\-(\-?\d+)/;
    unless ($fields[-1] =~ m/~/) {
	@data{qw(descr color)} = split(/ :/,$fields[-1]);
    }
    else {
	@data{qw(descr color)} = split(/~/,$fields[-1]);
    }

    if ($data{descr} =~ m/^(.+)\{([^}]+)\}\s*$/) {
	$data{descr} = $1;
	$data{dom_acc} = $2;
    }

    if ($data{color} =~ m/v$/) {
      $data{color} =~ s/v$//;
      $data{virtual} = 1;
    }

    if ($fields[0] =~ m/^qDomain/) {
      push @q_domain_info, \%data;
    }
    elsif ($fields[0] =~ m/^lDomain/) {
      push @l_domain_info, \%data;
    }

  }

  return (\@q_domain_info, \@l_domain_info);
}


# 
sub canon_file_name {
  my ($q_name, $l_name) = @_;

  if ($q_name =~ m/^(sp|tr|ref)\|([A-Z][A-Z0-9]{5}|[NX]P_\d{5})\|/) {
    $q_name = $2;
  }
  if ($l_name =~ m/^(sp|tr|ref)\|([A-Z][A-Z0-9]{5}|[NX]P_\d{5})\|/) {
    $l_name = $2;
  }

  return $q_name . "_" . $l_name;
}

# $region_r is a list of region_info data hashes:
# %data{} keys are:  beg end (protein coordinates), scores (and each of the scores as keys)
#                    descr, chr, g_start, g_end (DNA coordinates), color

sub print_regions_gff {
  my ($acc, $region_r, $bed_fmt) = @_;

  print "<pre>## $acc exons:\n";

  for my $r ( @{$region_r}) {
    my $strand = '+';
    if ($r->{g_start} > $r->{g_end}) {
      $strand = '-';
    }

    unless ($bed_fmt) {
	my $prot_info = sprintf("%s:%d-%d;%s;%s",$acc, $r->{p_start}, $r->{p_end}, $r->{descr}, $r->{scores});
	$prot_info =~ s/\s//g;
	print join("\t",($r->{chr},'FASTA', 'exon', $r->{g_start}-1, $r->{g_end}, $r->{Q}, $strand, '.', $prot_info)),"\n";
    }
    else {
	my $prot_info = sprintf("%s:%d-%d;%s",$acc, $r->{p_start}, $r->{p_end}, $r->{descr});
	$prot_info =~ s/\s//g;
	print join("\t",($r->{chr}, $r->{g_start}-1, $r->{g_end}, $prot_info, $r->{Q}*5.0, $strand)),"\n";
    }
  }

  print "</pre>\n<hr />\n";
}
