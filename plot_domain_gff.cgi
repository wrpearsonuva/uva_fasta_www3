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

$ENV{PATH} = ".:/bin:/usr/bin:/seqprg/bin";
BEGIN {
    do "./Fawww_begin.pl";
}

use vars qw( $OK_CHARS $HOST_NAME $HOST_DIR $CGI_DIR $BIN_DIR $SQL_DB_HOST
	     $TMP_DIR $GS_BIN $DEF_UNLINK $LAV_SVG $LAV_GS $lav_cmd
	     $PPM_BIN $LOG_FILE $lhost $PFAM_FAM_URL $IPRO_FAM_URL
	     $file $device $tmp_lav $size $z_param);

require "./fawww_defs.pl";

my $q = new CGI;

my @valid_args=qw( q_name l_name pgm q_cstart q_cstop l_cstart l_cstop q_astart q_astop l_astart l_astop regions doms );
my %valid_args = map { $_ => 1 } @valid_args;

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
  $file_name =~ s/[^$OK_CHARS]/_/go;
  my $file_offset = get_safe_number("",scalar($q->param("offset")));
  my $file_cnt = get_safe_number("",scalar($q->param("a_cnt")));

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
  my $tmp_arg = "";
  my $ROK_CHARS = $OK_CHARS.";\{\}\|~";
  for my $arg (@arg_names) {
      if (defined($valid_args{$arg}) && defined($q->param($arg)) && $q->param($arg)) {
	  $tmp_arg = scalar($q->param($arg));
	  $tmp_arg =~ s/[^$ROK_CHARS]/_/go;
	  $args{$arg} = $tmp_arg;
      }
      # else {
      # 	  print STDERR "***".__FILE__.":".__LINE__ ." q->param{$arg} without value: ::" . $q->param($arg) ."::\n";
      # }
  }
}

my $bed_fmt=0;
if ($q->param('bed_fmt')) {
    $bed_fmt=$q->param('bed_fmt');
    $bed_fmt =~ s/^\d+$//;
}

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

sub get_safe_number {
  my ($opt, $p_arg) = @_;
  
  unless (defined($p_arg)) {return "";}

  if ($p_arg =~ m/DEFAULT/i) {return "";}

  ($p_arg) = ($p_arg =~ m/([E\d\-\.]+)/i);
  unless (length($p_arg)>0) {return "";}

  if ($opt =~ m/%/) {
      return sprintf($opt,$p_arg);
  }
  elsif (length($opt)>0) {
      return "$opt $p_arg";
  }
  return $p_arg;
}
