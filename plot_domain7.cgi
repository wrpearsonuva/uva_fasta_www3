#!/usr/bin/perl -w

## plot_domain7.cgi -- extension of plot_domain6t.cgi that does more robust
## checks on input arguments

# plot_domain6t.pl - produce SVG plot for aligned domains
# version2 plots both n0 and n1 sequences, with 2 axes
#
# derived from plot_domain2t.cgi adding site info
#
# args:
#
#  q_name - query_acc
#  l_name - library_acc
#
#  pgm = program used 
#  mag = used to scale when not embedded
#  no_embed = default 0, for embedding in HTML page
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
#  max_xax -- used to manually set $max_xax
#  clip = 1 -- clip library sequence for consistent length
#
#  paper -- do not show alignment regions or active sites, put domains just above/below sequence line
#           get PFam model_start, model_end
#
# 9-May-2013 -- modify to accomodate reverse-complement coordinates
# 30-Dec-2013 -- put coordinates on separate line in full plot, fix off-by-one error for l_sites
#

use strict;
use Taint;

use lib qw(.);

use Getopt::Long;
use Pod::Usage;
use URI::Escape;
use HTML::Entities;

use CGI qw(header param start_html end_html);
use CGI::Carp qw(fatalsToBrowser carpout warningsToBrowser);

$ENV{PATH} = ".:/bin:/usr/bin:/seqprg/bin";

BEGIN {
    do "Fawww_begin.pl";
}

use vars qw( $OK_CHARS $HOST_NAME $HOST_DIR $CGI_DIR $BIN_DIR $SQL_DB_HOST
	     $TMP_DIR $GS_BIN $DEF_UNLINK $LAV_SVG $LAV_GS $lav_cmd
	     $PPM_BIN $LOG_FILE $lhost $PFAM_FAM_URL $IPRO_FAM_URL
	     $file $device $tmp_lav $size $z_param);

#use URI::Escape;

require "./fawww_defs.pl";

use vars qw($pminx $pmaxx $pminy $pmaxy $lvstr $max_x $max_y
	    $fxscal $fyscal $fxoff $fyoff $x_rev $y_rev
	    @block_colors %color_names $text_font $invert);

my @valid_args=qw( q_name l_name pgm q_cstart q_cstop l_cstart l_cstop q_astart q_astop l_astart l_astop regions doms );
my %valid_args = map { $_ => 1 } @valid_args;

#$text_font = "sans-serif";

$text_font = "Helvetica";

@block_colors = qw( slategrey lightgreen lightblue pink cyan tan gold plum darkgreen );

my %site_colors = ();
@site_colors{('<', '=', 'z', '>')} = qw(red black red green);

# $max_x, $max_y define the maximum plotting area
# the actual bounding box/view area will be larger if annotation comments are available

($max_x,$max_y)=(540,24);

my @xax_len = (200, 300, 500, 800, 1200, 2000, 3000, 5000, 8000, 12000, 20000, 30000, 50000);
my ($max_xax, $paper, $coords, $do_clip) = (-1, 0, 0 , 1);
my ($comb_xax, $l_clip_code) = (0,0);  # comb_xax captures the length of the two sequences minus the offset
my ($x0c_off, $x1c_off, $xdc_off) = (0,0,0);

my ($x0f3, $x1f3) = (1,1);	# set to 3 for fastx (x0f3) or tfastx (x1f3)

# tick array - values */
my @tarr = (50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000);
my $MAX_INTERVAL=20000;

my $q = new CGI;

my %dom_colors = ();
my $max_color = 0;

my @arg_names = ();
my %args = ();

## get global arguments, not in argument file
#
my $g_mag = 1;
if ($q->param("mag")) {
  $g_mag = get_safe_number("",scalar(scalar($q->param("mag"))));
}

my $invert=0;
if ($q->param("invert")){
  $invert = 1;
}


my $no_embed = 0;
if ($q->param("no_embed")) {
    $no_embed = 1 ;
    $coords = 1;
}

if ($q->param("max_xax")) {
  $max_xax = get_safe_number("",scalar($q->param("max_xax")));
}

if (($q->param("clip") && $q->param("clip") =~ m/n/i) || $q->param("noclip")
    || $q->param("no-clip")) {
  $do_clip = 0;
}
elsif ($q->param('clip')) {
  $do_clip = 1;
}

if ($q->param("paper")) {
  $paper = get_safe_number("",scalar($q->param("paper")));
  $coords = 1 if ($paper);
}

if ($q->param("coords")) {
  $coords = get_safe_number("",scalar($q->param("coords")));
}

## set font sizes
#
my ($g_fontsize, $g_label_fontsize, $g_ticksize, $g_name_fontsize) = (8, 9, 6, 14);

## adjust font sizes, tick-length for $g_mag
$g_fontsize *= $g_mag;
$g_label_fontsize *= $g_mag;
$g_ticksize *= $g_mag;

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

  if ($file_offset !~ m/^\d+$/) {
      die "file_offset: $file_offset non-numeric";
  }

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
    if (defined($key) && defined($valid_args{$key}) && defined($val) && $key && $val) {
      $args{$key} = uri_unescape($val);
    }
  }
}
else {
  @arg_names = $q->param();
##  %args = map { $_ => scalar($q->param($_)) if defined($valid_args{$_} && $q->param($_)) } @arg_names;
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

## check that coordinates are provided, and are integers
##

my @needed_args = qw( q_cstart q_cstop q_astart q_astop l_cstart l_cstop l_astart l_astop );

if (! check_coords(\%args, \@needed_args)) {

    print $q->header(-type => 'text/html',
		     -status => '400 Bad Request',
		     -charset => 'utf-8');
    print "Your request could not be processed\n";
    exit(0);
}

my @detaint_args = qw(q_name l_name );

detaint_strings(\%args, \@detaint_args, '[^\w\.\|\;]+');

if (! defined($args{'q_name'})) {
    $args{'q_name'} = 'Query';
}

if (! defined($args{'s_name'})) {
    $args{'s_name'} = 'Subj';
}

## adjust coordinate factors for [t]fast[xy]
#
if (defined($args{pgm})) {
    if ($args{pgm} =~ m/^f[xy]$/) { $x0f3 = 3;}
    elsif ($args{pgm} =~ m/^tf[xy]/) { $x1f3 = 3;}
}

####
# if invert set, then reverse all the arguments (q/l):
if ($invert) {
  my %new_args = ();
  for my $key ( keys(%args) ) {
    my $new_key = $key;
    if ($new_key =~ m/^l_/) {
      $new_key =~ s/^l_/q_/;
      $new_args{$new_key} = $args{$key}
    }
    elsif ($new_key =~ m/^q_/) {
      $new_key =~ s/^q_/l_/;
      $new_args{$new_key} = $args{$key}
    }
    elsif ($new_key =~ m/doms/) {
      my $new_doms = $args{doms};
      $new_doms =~ s/qDomain/xDomain/sg;
      $new_doms =~ s/lDomain/yDomain/sg;
      $new_doms =~ s/yDomain/qDomain/sg;
      $new_doms =~ s/xDomain/lDomain/sg;
      $new_args{doms}=$new_doms;
    }
    elsif ($new_key =~ m/regions/) {
      my $new_doms = $args{regions};
      $new_doms =~ s/\sRegion/xRegion/sg;
      $new_doms =~ s/\sqRegion/yRegion/sg;
      $new_doms =~ s/yRegion/ Region/sg;
      $new_doms =~ s/xRegion/ qRegion/sg;
      $new_args{regions}=$new_doms;
    }
    else {
      $new_args{$key} = $args{$key}
    }
  }
  # also make an l_descr
  $new_args{l_descr} = $args{q_name};
  %args = %new_args;
}

#unless ($ENV{DOCUMENT_ROOT}) {
#  %args = map { $_ => uri_unescape($args{$_}) } keys %args;
#}

## parse string arguements into [q_] region/site/domain arrays
#
my ($region_info_r, $site_info_r, $q_site_info_r, $q_dom_info_r, $l_dom_info_r);

if ($args{regions}) {
    ($region_info_r, $site_info_r, $q_site_info_r) = parse_regions(uri_unescape($args{regions}));
}
else {$region_info_r = [];}

if ($args{doms}) {
    ($q_dom_info_r, $l_dom_info_r) = parse_domains($args{doms});
    if ($no_embed && scalar(@$l_dom_info_r)) {
      get_model_info($args{l_name}, $l_dom_info_r);
    }
    if ($no_embed && scalar(@$q_dom_info_r)) {
      get_model_info($args{q_name}, $q_dom_info_r);
    }
} else {
    $q_dom_info_r = [];
    $l_dom_info_r = [];
}

################################################################
# openplt -- sets up coordinates, query/library domain info above and below main sequences
#
openplt(($args{q_cstop}-$args{q_cstart})+1,
	($args{l_cstop}-$args{l_cstart})+1,
	scalar(@{$q_dom_info_r}),
	scalar(@{$l_dom_info_r}));

if (!$paper && $region_info_r && scalar(@{$region_info_r})) {
    draw_regions($region_info_r, $args{l_cstart}, $args{l_cstop});
}

if (!$paper && $site_info_r && scalar(@{$site_info_r})) {
  draw_sites($site_info_r, $args{l_cstart}, $args{l_cstop});
  if ($q_site_info_r) {
    q_draw_sites($q_site_info_r, $args{q_cstart}, $args{q_cstop});
  }
}

if ($args{doms}) {
  my ($y0_offset, $y1_offset) = (48, -10);
  if ($paper) {
    $y0_offset -= 19;
    $y1_offset += 17;
  }

  if (scalar(@{$l_dom_info_r})) {
    draw_doms($l_dom_info_r, $x1c_off, $y1_offset, $args{l_cstart}, $args{l_cstop}, $x1f3, 1, $paper, $coords);
  }

  if (scalar(@{$q_dom_info_r})) {
    # get model_start, model_end
    draw_doms($q_dom_info_r, $x0c_off, $y0_offset, $args{q_cstart}, $args{q_cstop}, $x0f3, 0, $paper, $coords);
  }
}

draw_align2(\%args);

closeplt();

exit(0);

# have all the data (and length of sequence), scale it and color it

#define SX(x) (int)((double)(x)*fxscal+fxoff+6)
sub SX {
    my $xx = shift;
    return int($xx*$fxscal+$fxoff+18);
}

sub SY {
    my $yy = shift;
    return $max_y - int($yy*$fyscal+$fyoff);
}

my $y_delta = 0;

#void openplt(long n0, long n1, int sq0off, int sq1off, char *xtitle, char *ytitle)
sub openplt {
  my ($n0, $n1, $have_q_doms, $have_l_doms) = @_;

  $max_x += 50 if ($no_embed);

  my ($xbound, $ybound) = ($max_x + 24, 48);
  if ($max_xax > 10) {$xbound *= 1.3333;}
  $ybound += 30 if ($no_embed);

  my ($x0_rev, $x1_rev) = (0,0);

## more space required if domain diagrams above, below
#
  $ybound += 14 if $have_q_doms;
  $ybound += 14 if $have_l_doms;

  if ($n0 < 0) {$x0_rev=1; $n0 = 2 - $n0;}
  if ($n1 < 0) {$x1_rev=1; $n1 = 2 - $n1;}

  if ($g_mag > 1) {
    $max_x *= $g_mag;
    $max_y *= $g_mag;
    $xbound *= $g_mag;
    $ybound *= $g_mag;
  }

  # build a file name
  my $out_name = "domain_plot.svg";
  $out_name = canon_file_name($args{q_name}, $args{l_name});

  if (!$no_embed || $paper) {
    print $q->header('image/svg+xml') if ($ENV{DOCUMENT_ROOT});
    print("<?xml version=\"1.0\" standalone=\"no\"?>\n");
    print("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \n");
    print("\"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n\n");
  }
  else {
    print $q->header() if ($ENV{DOCUMENT_ROOT});
    my $qs_name = $args{q_name};
    $qs_name =~ s/^gi\|\d+\|//;
    print $q->start_html($qs_name . " :vs: " . $args{l_name});

    print "<h3>$qs_name vs $args{l_name}</h3>\n";

    print_regions($args{regions}, $args{l_descr}, $args{hscores}, $q_dom_info_r, $l_dom_info_r);
  }

  ## print(qq(<!-- l_name=$args{l_name} -->\n));
  print("<svg width=\"$xbound\" height=\"$ybound\" version=\"1.1\"\n");
  #  print("<svg version=\"1.1\"\n");
  print("xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">\n\n");

  # simple things first, if query is shorter and inside, or library is
  # shorter and inside, then just use the longer sequence.

  ($x0c_off, $x1c_off, $xdc_off) = (0,0,0);

  ($comb_xax, $xdc_off, $x0c_off, $x1c_off, $n1, $l_clip_code) = 
    calc_offsets($n0, $x0f3, $x0_rev, $n1, $x1f3, $x1_rev, \%args);

  $max_xax = check_max_xax($max_xax, $comb_xax, \@xax_len);

  $fxscal = ($max_x-1)/$max_xax;
  $fyscal = $g_mag;

  $fxscal *= 0.9;

  $fxoff = 24;
  $fxoff += 40 if ($no_embed);
  $fxoff *= $g_mag;

  $fyoff = -14 * $g_mag;
  $fyoff += -14 * $g_mag if ($no_embed);
  $fyoff -= 12 * $g_mag  if ($have_q_doms);

  my ($qc_start, $lc_start) = @args{qw(q_cstart l_cstart)};

  xaxis2($n0/$x0f3, $qc_start/$x0f3, $x0_rev,
	 $n1/$x1f3, $lc_start/$x1f3, $x1_rev,
	 $have_q_doms, $have_l_doms, $paper
	);

  # draw actual sequence lines
  newline(qq(stroke="black" stroke-width="1.5"));
  move(SX($x0c_off+1), SY(15));
  draw(SX($x0c_off+($n0/$x0f3)),SY(15));
  clsline($n0,0);

  newline(qq(stroke="black" stroke-width="1.5"));
  move(SX($x1c_off+1), SY(9));
  draw(SX($x1c_off+($n1/$x1f3)),SY(9));
  clsline($n1,0);

  # add hash marks for clipping
  if ($l_clip_code & 1) {
    newline(qq(stroke="black" stroke-width="1.5"));
    move(SX($x1c_off)+1, SY(12));
    draw(SX($x1c_off)-1, SY(7));
    move(SX($x1c_off)-3, SY(12));
    draw(SX($x1c_off)-5, SY(7));
    clsline($n1,0);
  }
  if ($l_clip_code & 2) {
    newline(qq(stroke="black" stroke-width="1.5"));
    my $sx1_end = SX($x1c_off+($n1/$x1f3));
    move($sx1_end+1, SY(12));
    draw($sx1_end-1, SY(7));
    move($sx1_end+5, SY(12));
    draw($sx1_end+3, SY(7));
    clsline($n1,0);
  }
}

sub closeplt {
  my ($mag) = @_;
  print "</svg>\n";

  if ($no_embed && !$paper) {
      print qq(<a href=") . $q->url() . "?" . $q->query_string() . q(&amp;paper=1">)."Compact SVG</a>\n";
      print $q->end_html();
  }
}

################
# calc_offsets: return ($comb_xax, $xdc_off, $x0c_off, $x1c_off)
# $comb_xax: length of the two sequences minus the offset, or the
#   length of the longer of the two sequences if the shorter is included
#
# $x0c_off: offset of seq0 into seq1
# $x1c_off: offset of seq1 into seq0
# $xdc_off: 0 or $x1c_off
#
# need to modify to allow for truncation left or right
#
################
# calc_offsets can reset q/l_cstart and q/l_cstop to effectively
# provide a clipping window on the sequence alignment. For example, if
# q_cstop - q_cstart + 1 / l_cstopl_cstart+1 > 1.5, then adjust things
# appropriately (and likewise the other way).  But what we really care
# about is the aligned overlap, so a more sophisticated strategy is
# required.  But once we have the strategy, q/l_cstart/_cstop should
# get the job done.  If q/l_cstart/_cstop are adjusted, n0/n1 must be
# adjusted as well.
#
# to begin, only clip library sequences, assume that query sequences
# will always have a near full length alignment.  And clip based on
# @xax_len (and offsets) -- if both fit in @xax_len() with offset, nothing
# to be done.  If $n1 bumps up by 2 @xax_len indexes, it needs to be
# clipped.  It also needs to be clipped if $n0 < 2/3 of $xax_len[].
#

sub calc_offsets {
  my ($n0, $x0f3, $x0_rev, $n1, $x1f3, $x1_rev, $args_r) = @_;

  # find xax_len_idx0,1 for both query/library

  my ($comb_xax, $x0c_off, $x1c_off, $xdc_off, $l_clip_code) = (0,0,0,0,0);

  # _start/stop_d is the difference in the start and stop coordinates
  # with respect to coordinate start

  my ($n0f, $n1f) = ($n0/$x0f3, $n1/$x1f3);

  my ($q_start_d, $q_stop_d, $l_start_d, $l_stop_d) = 
      (abs($args_r->{q_astart} - $args_r->{q_cstart})/$x0f3,
       abs($args_r->{q_astop} - $args_r->{q_cstop})/$x0f3,
       abs($args_r->{l_astart} - $args_r->{l_cstart})/$x1f3,
       abs($args_r->{l_astop} - $args_r->{l_cstop})/$x1f3);

  my ($n0_xax, $n1_xax, $nc_xax) = (check_max_xax(0, $n0f, \@xax_len), check_max_xax(0, $n1f, \@xax_len),0);

  my $x0_longer = 0;

  if (($n1f >= $n0f) && (($l_start_d >= $q_start_d) || ($l_stop_d >= $q_stop_d))) {
    # n1 is longer and n0 is contained -- possibility for clipping
    $comb_xax = $n1f; # $comb_xax : combined x-axis, in amino-acids if translated
    $x0c_off = $l_start_d - $q_start_d;

    if ($do_clip && $n1_xax > $n0_xax) {	# we need to clip
      # can we fit the alignment in $n0_xax
      if (abs($args_r->{l_astop} - $args_r->{l_astart})/$x1f3 + 1 < $n0_xax) {
	# it can fit -- trim the left to match query
	if ($q_start_d < $l_start_d) {
	  if ($x1_rev) {
	    $args_r->{l_cstart} = $args_r->{l_astart} + $q_start_d * $x1f3;  # use query offset from l_astart
	    $l_start_d = abs($args_r->{l_astart} - $args_r->{l_cstart})/$x1f3;
	  }
	  else {
	    $args_r->{l_cstart} = $args_r->{l_astart} - $q_start_d * $x1f3;  # use query offset from l_astart
	    $l_start_d = abs($args_r->{l_astart} - $args_r->{l_cstart})/$x1f3;
	  }
	  $l_clip_code += 1;
	}

	if ($q_stop_d < $l_stop_d) {
	  if ($x1_rev) {
	    $args_r->{l_cstop} = $args_r->{l_astop} - $q_stop_d * $x1f3;  # use query offset from l_astop
	    $l_stop_d = abs($args_r->{l_astop} - $args_r->{l_cstart})/$x1f3;
	  }
	  else {
	    $args_r->{l_cstop} = $args_r->{l_astop} + $q_stop_d * $x1f3;  # use query offset from l_astop
	    $l_stop_d = abs($args_r->{l_astop} - $args_r->{l_cstop})/$x1f3;
	  }
	  $l_clip_code += 2;
	}

	if ($x1_rev) {
	    $n1 = ($args_r->{l_cstart} - $args_r->{l_cstop}+1);
	}
	else {
	    $n1 = ($args_r->{l_cstop} - $args_r->{l_cstart}+1);
	}

	$n1f = $n1/$x1f3;
	$n1_xax = check_max_xax(0, $n1f, \@xax_len);
	$x0c_off = 0;
	$x1c_off = $q_start_d - $l_start_d;
	$comb_xax = $n0f;   # not necessarily
      }
    }
  } elsif (($n1f < $n0f) && ($l_start_d <= $q_start_d) && ($l_stop_d <= $q_stop_d)) {
    # n0 is longer and n1 is contained -- no clipping
    $comb_xax = $n0f;
    $xdc_off = $x1c_off = $q_start_d - $l_start_d;
    $x0_longer = 1;
  }
  # some kind of extension is necessary
  elsif ($l_start_d >= $q_start_d) {	# library sequence to left (and possibly right)
    $x0c_off = $l_start_d - $q_start_d;
    $comb_xax = $n0f + $x0c_off;
    $nc_xax = check_max_xax(0, $comb_xax, \@xax_len);

    if ($do_clip && $nc_xax > $n0_xax) {
      # we know that library extends left from elseif()
      $args_r->{l_cstart} = $args_r->{l_astart} - $q_start_d;  # use query offset from l_astart
      $l_start_d = abs($args_r->{l_astart} - $args_r->{l_cstart})/$x1f3;
      $l_clip_code += 1;

      # also check the right
      if ($q_stop_d < $l_stop_d) {
	$args_r->{l_cstop} = $args_r->{l_astop} + $q_stop_d;  # use query offset from l_astop
	$l_stop_d = abs($args_r->{l_astop} - $args_r->{l_cstop})/$x1f3;
	$l_clip_code += 2;
      }

      $n1 = ($args_r->{l_cstop} - $args_r->{l_cstart}+1);
      $n1f = $n1/$x1f3;
      $x0c_off = 0;
      $comb_xax = $n0f;
    }
  } else {
    $xdc_off = $x1c_off = $q_start_d - $l_start_d;
    $comb_xax = $n1f + $x1c_off;
    $nc_xax = check_max_xax(0, $comb_xax, \@xax_len);

    if ($do_clip && $nc_xax > $n0_xax) {
      # can we fit the alignment in $n0_xax
      if ((abs($args_r->{l_astop} - $args_r->{l_astart})+ 1)/$x1f3 < $n0_xax) {
	# it can fit -- trim the left to match query
	if ($q_start_d < $l_start_d) {
	  $args_r->{l_cstart} = $args_r->{l_astart} - $q_start_d;  # use query offset from l_astart
	  $l_start_d = abs($args_r->{l_astart} - $args_r->{l_cstart})/$x1f3;
	  $l_clip_code += 1;
	}
	if ($q_stop_d < $l_stop_d) {
	  # make certain we clip on the correct side
	  if ($x1_rev) { # critical to get right as $args_r->{l_cstop} is modified -- 
	                 # should be {l_cstart} in case of reverse
	    $args_r->{l_cstop} = $args_r->{l_astop} - $q_stop_d*$x1f3;  # use query offset from l_astop
	  }
	  else {
	    $args_r->{l_cstop} = $args_r->{l_astop} + $q_stop_d*$x1f3;  # use query offset from l_astop
	  }
	  $l_stop_d = abs($args_r->{l_astop} - $args_r->{l_cstop})/$x1f3;
	  $l_clip_code += 2;
	}
	if ($x1_rev) {
	    $n1 = ($args_r->{l_cstart} - $args_r->{l_cstop}+1);
	}
	else {
	    $n1 = ($args_r->{l_cstop} - $args_r->{l_cstart}+1);
	}
	$n1f = $n1/$x1f3;
	$x0c_off = 0;
	$comb_xax = $n0f;
      }
    }
  }

  # now correct for differences in alignment lengths

  my ($q_alen, $l_alen) = ((abs($args_r->{q_astop} - $args_r->{q_astart}) + 1)/$x0f3,
			   (abs($args_r->{l_astop} - $args_r->{l_astart}) + 1)/$x1f3);

  my ($a_diff) = int(abs($q_alen - $l_alen)/2);

  if (abs($l_stop_d - $q_stop_d) < $a_diff) { $comb_xax += $a_diff;}

  if ($q_alen >= $l_alen) {
    $x1c_off += $a_diff;
    $xdc_off += $a_diff;
  }
  else {
    $x0c_off += $a_diff;
  }

  return ($comb_xax, $xdc_off, $x0c_off, $x1c_off, $n1, $l_clip_code);
}

sub draw_trapz {
  my ($start0, $stop0, $start1, $stop1, $color, $text) = @_;

  $color = ($color % scalar(@block_colors));
  my $svg_color = $block_colors[$color];
  my $tx = $start1 + int(($stop1-$start1+1)/2);
  my $ty = 10 + 9;

  $ty *= $g_mag;

  $text = substr($text,0,10);

  newline(qq(stroke="black" stroke-width="1.5"));

  move(SX($start0+$x0c_off), SY(20));
  draw(SX($stop0+$x0c_off), SY(20));
  draw(SX($stop1+$x1c_off), SY(10));
  draw(SX($start0+$x1c_off), SY(10));
  move(SX($start0+$x0c_off), SY(20));

  print(qq(" fill="$svg_color" />\n));

  #  print (qq(<rect x="$x" y="$y" width="$w" height="$h" fill="$svg_color" stroke="white" stroke-width="1" />\n));
  #  print (qq(<text x="$tx" y="$ty" font-size="$g_label_fontsize" font-family="$text_font" fill="white" text-anchor="middle">$text</text>\n));
}

# draws a colored solid block, and labels it, to indicate domain
sub draw_block {
  my ($x, $y, $w, $h, $color, $opacity, $text, $y_delta, $m_start, $m_end) = @_;

  $color = ($color % scalar(@block_colors));
  my $svg_color = $block_colors[$color];
  my $tx = $x + int($w/2);

  $y_delta = 9 unless $y_delta;

  my $ty = $y + $y_delta*$g_mag ;

  if (!$paper && !$no_embed) {$text = substr($text,0,10);}

  print "<g>\n";
  print (qq(<rect x="$x" y="$y" width="$w" height="$h" fill="$svg_color" stroke="white" stroke-width="1" />\n));
  print (qq(<text x="$tx" y="$ty" font-size="$g_label_fontsize" font-family="$text_font" fill="black" text-anchor="middle">$text</text>\n));

  if ($m_start) {
    $tx = $x + 4;
    my $font_size = 10;
    print (qq(<text x="$tx" y="$ty" font-size="$font_size" font-family="$text_font" fill="black" text-anchor="start">$m_start</text>\n));
  }

  if ($m_end) {
    $tx = $x + $w - 4;
    my $font_size = 10;
    print (qq(<text x="$tx" y="$ty" font-size="$font_size" font-family="$text_font" fill="black" text-anchor="end">$m_end</text>\n));
  }
  print "</g>\n";


}

sub mark_site {
  my ($xpos, $ypos, $ylen, $s_type, $s_color, $up) = @_;

  my $sym_inc = 7 * $g_mag;
  my $font_size = 8 * $g_mag;
  if ($s_type eq '*') {
    if ($up) {$sym_inc -= 4 * $g_mag;}
    else { $sym_inc += 4 * $g_mag;}
    $font_size += 4 * $g_mag;
  }

  my ($y_start, $y_stop, $y_text) = ($ypos, $ypos + $ylen, $ypos + $ylen + $sym_inc);
  if ($up) {
    $sym_inc -= 5 * $g_mag;
    ($y_start, $y_stop, $y_text) = ($ypos, $ypos - $ylen, $ypos - $ylen - $sym_inc);
  }

  newline("stroke=\"black\" stroke-width=\"1.0\"");
  move($xpos, $y_start);
  draw($xpos, $y_stop);
  clsline();

  printf(qq(<text x="%d" y="%d" fill="$s_color" font-family="$text_font" font-size="$font_size" text-anchor="middle">%s</text>\n),
	 $xpos, $y_text, $s_type);
}

sub draw_regions {
  my ($annot_arr_r, $xc_start, $xc_stop) = @_;

  for my $annot ( @$annot_arr_r) {
    next if ($annot->{end1} < $xc_start);
    next if ($annot->{beg1} > $xc_stop);
    my $y_delta = 9;

    if ($annot->{virtual}) {
      draw_block(SX($annot->{beg1}+$xdc_off-$xc_start), SY(16), SX($annot->{end1}+$xdc_off)-SX($annot->{beg1}+$xdc_off),
		 9 * $g_mag, $annot->{color}, 0.5, "" , $y_delta);
    }
    else {
      draw_block(SX($annot->{beg1}+$xdc_off-$xc_start), SY(18), SX($annot->{end1}+$xdc_off)-SX($annot->{beg1}+$xdc_off),
		 12 * $g_mag, $annot->{color}, 1.0, $annot->{descr}, $y_delta);
    }
  }
}

sub draw_sites {
  my ($annot_arr_r, $xc_start, $xc_stop) = @_;

  for my $annot ( @$annot_arr_r) {
    next if ($annot->{lPos} < $xc_start);
    next if ($annot->{lPos} > $xc_stop);
    mark_site(SX($annot->{lPos}+$x1c_off-$xc_start), SY(3), 6 * $g_mag, $annot->{stype}, $site_colors{$annot->{simV}}, 0);
  }
}

sub q_draw_sites {
  my ($annot_arr_r, $xc_start, $xc_stop) = @_;

  for my $annot ( @$annot_arr_r) {
    next if ($annot->{qPos} < $xc_start);
    next if ($annot->{qPos} > $xc_stop);
    mark_site(SX($annot->{qPos}+$x0c_off - $xc_start), SY(21), 6 * $g_mag, $annot->{stype}, $site_colors{$annot->{simV}}, 1);
  }
}

# $bottom == 1 - lower sequence / 0 -- upper sequence
# $paper == 1 -- compact with model_start/model_end

sub draw_doms {
  my ($annot_arr_r, $xc_off, $y_off, $xc_start, $xc_stop, $xscale, $bottom, $paper, $coords) = @_;

  my ($y_delta, $y_shift) = (9,0);

  if ($bottom) {
      $y_shift = -1.5;
  } else {
      $y_shift = -2;
  }

  if ($paper) {
    if ($bottom) {
      $y_delta += 2;
      $y_shift = -1.5;
    } else {
      $y_delta -= 2;
      $y_shift = -2
    }
  }

  for my $annot ( @$annot_arr_r) {
    next if ($annot->{end} < $xc_start);
    last if ($annot->{beg} > $xc_stop);

    my $show_coords = $coords;
    if ($show_coords) {
      $show_coords = 0 unless $annot->{m_len};
    }
    if ($annot->{virtual}) {
      draw_block(SX(($annot->{beg}+$xc_off-$xc_start)/$xscale), SY($y_off+$y_shift),
    		 SX(($annot->{end}+$xc_off)/$xscale)-SX(($annot->{beg}+$xc_off)/$xscale),
    		 9*$g_mag, $annot->{color}, 1.0, "", $y_delta,
		 $show_coords ? $annot->{m_start} : "",
		 $show_coords ? $annot->{m_end}: "");
    }
    else {
      draw_block(SX(($annot->{beg}+$xc_off-$xc_start)/$xscale), SY($y_off),
		 SX(($annot->{end}+$xc_off)/$xscale)-SX(($annot->{beg}+$xc_off)/$xscale),
		 12*$g_mag, $annot->{color}, 1.0, $annot->{descr}, $y_delta,
		 $show_coords ? $annot->{m_start} : "",
		 #	       $annot->{m_end} ? "$annot->{m_end} / $annot->{m_len}" : "");
		 $show_coords ? $annot->{m_end}."/".$annot->{m_len}: "");
    }
  }
}

sub detaint_strings {
    my ($arg_r, $detaint_r, $good_str) = @_;

    if (!defined($good_str) || $good_str eq "") {
	$good_str = '[^\w\.]+'
    }

    for my $this_string (@$detaint_r) {
	$arg_r->{$this_string} =~ s/$good_str//g;
    }
}

sub check_coords {
    my ($arg_r, $needed_r) = @_;

    for my $this_arg (@$needed_r) {
	if (! defined($arg_r->{$this_arg}) || $arg_r->{$this_arg} !~ m/^[\d\.]+$/) {
	    return 0;
	}
    }
    return 1;
}

sub draw_align {
  my $arg_r = shift;

  my ($x, $y, $w, $h) = (SX($args{l_astart} + $xdc_off), SY(21), SX($args{l_astop}+$xdc_off) - SX($args{l_astart}+$xdc_off), 18*$g_mag);

  print (qq(<rect x="$x" y="$y" width="$w" height="$h" stroke="black" fill-opacity="0" stroke-width="1*$g_mag" />\n));
}

sub draw_align2 {
  my $arg_r = shift;

  my ($x0_rev, $x1_rev) = (0,0);

  my ($qx0, $qx1, $qy) = (SX(($args{q_astart} - $args{q_cstart}+1)/$x0f3 + $x0c_off),
			  SX(($args{q_astop} - $args{q_cstart} + 1)/$x0f3 + $x0c_off),
			  SY(21));

  if ($args{q_cstart} > $args{q_cstop}) {
    ($qx0, $qx1, $qy) = (SX(($args{q_cstart} - $args{q_astart})/$x0f3 + $x0c_off),
			 SX(($args{q_cstart} - $args{q_astop})/$x0f3 + $x0c_off),
			 SY(21));
  }

  my ($lx0, $lx1, $ly) = (SX(($args{l_astart} - $args{l_cstart} + 1)/$x1f3 + $x1c_off),
			  SX(($args{l_astop} - $args{l_cstart} + 1 )/$x1f3 + $x1c_off),
			  SY(21)+18*$g_mag);

  if ($args{l_cstart} > $args{l_cstop}) {
    ($lx0, $lx1, $ly) = (SX(($args{l_cstart} - $args{l_astart})/$x1f3 + $x1c_off),
			 SX(($args{l_cstart} - $args{l_astop})/$x1f3 + $x1c_off),
			 SY(21)+ 18*$g_mag);
  }

  ## print (qq(<rect x="$x" y="$y" width="$w" height="$h" stroke="black" fill-opacity="0" stroke-width="1" />\n));
  my ($qyb, $lyb) = (SY(15), SY(9));

#  print "<g>\n";
  print (qq(<polygon points="$qx0,$qyb $qx0,$qy $qx1,$qy $qx1,$qyb $lx1,$lyb $lx1,$ly $lx0,$ly $lx0, $lyb" stroke="black" fill-opacity="0" stroke-width="1" />\n));
# put ticks at the ends 
  # newline();
  # my $inc = 4 * $g_mag;
  
  # move($qx0, $qy-$inc);
  # draw($qx0, $qy+$inc);

  # move($qx1, $qy-$inc);
  # draw($qx1, $qy+$inc);

  # move($lx0, $ly-$inc);
  # draw($lx0, $ly+$inc);

  # move($lx1, $ly-$inc);
  # draw($lx1, $ly+$inc);
  # clsline();
  
  # print "</g>\n";
}

# void newline(char *options)
sub newline
  {
    my $options = shift;

    if ($options) {
      printf("<path %s d=\"",$options);
    } else {
      print("<path stroke=\"black\" d=\"");
    }
  }

# void clsline(long x, long y, int s)
sub clsline
{
    my ($x, $y, $s) = @_;

    print("\" fill=\"none\" />\n");
}

#void move(int x, int y)
sub move
{
    my ($x, $y) = @_;
    printf(" M %d %d",$x,$y);
}

# void draw(int x, int y)
sub draw
{
    my ($x, $y) = @_;
    printf(" L %d %d",$x,$y);
}

# void xaxis(long n, int offset, char *title)
# coordinates in amino acids - modify for final axes
#
sub xaxis2 {
  my ($n0, $offset0, $x0_rev, $n1, $offset1,$x1_rev, $have_q_doms, $have_l_doms) = @_;

  my ($yoff_top, $yoff_bottom) = (26, 1);
  if ($no_embed) {
    ($yoff_top, $yoff_bottom) = (40, -24);
    $yoff_top += 12 if ($have_q_doms)
  }

  if ($paper) {
    $yoff_top -= 20;
    $yoff_bottom += 18;
  }

  my ($v_offset0, $v_offset1) = ($offset0, $offset1);

  my ($i, $jm, $tick_length, $max_ticks, $tick_inc);
  my ($js, $jl0, $jl1);
  my ($sgn0, $sgn1) = (1,1);

  my $num_len;
  my $numstr;

  # reverse coordinates when required

  if ($x0_rev) {
    $sgn0 = -1;
    $v_offset0 = $offset0 - $n0;
  }

  if ($x1_rev) {
    $sgn1 = -1;
    $v_offset1 = $offset1 - $n1;
  }

  # for translated-DNA/protein searches, both $n0 and $n1 are in amino-acids
  my $n_max = $n1;
  $n_max = $n0 if ($n0 > $n1);
  my $offset = 0;

  $tick_length = 2 * $g_mag;

  # search for the correct increment for the tick array */
  # @tarr[] has the list of axis increments we might use
  # we want a tick increment that gives < 6 ticks
  for ($i=0; $i< @tarr; $i++) {
    # seek to divide into 10 or fewer divisions */
    if (($max_ticks = $n_max/$tarr[$i]) <= 6) {
      goto found;
    }
  }

  # these happen only if no tick increment was found
  # point $i to the last element
  $i = scalar(@tarr)-1;

  # $max_ticks is the number of increments for longest sequence

  $max_ticks = $n_max/$tarr[-1];

 found:
  $tick_inc = $tarr[$i];

  # jo is the offset for the coordinate system, e.g. if we are
  # plotting an alignment from 101 - 300 rather than 1 - 400 we may
  # show partial sequences in alignments, it should be kept, but is is
  # different from the axis shift ($x0c_off, $x1c_off)

  # ($x0c_off, $x1c_off) are the offsets determined by calc_offsets()
  my ($xx0c_off, $xx1c_off) = ($x0c_off, $x1c_off);

  # ($offset0, $offset1) are based on @args{('q_cstart', 'l_cstart')}

  # make two groupings: (1) captures ticks and numbers; (2) capture everything
  my $xx_max_ticks = int(($n0+$offset0)/$tick_inc);
  unless ($x0_rev) {
    $xx0c_off -= $offset0;
    # draw up-tick
    print "<g>\n";		# group coordinate axis
    for ($i=1; $i <= $xx_max_ticks; $i++) {
      last if ($i*$tick_inc > $n0 + $offset0);
      next if ($i*$tick_inc < $offset0);

      print "<g>";		# group individual tick, number
      newline("stroke=\"black\" stroke-width=\"1.5\"");
      move(SX($i*$tick_inc + $xx0c_off),SY($yoff_top));
      draw(SX($i*$tick_inc + $xx0c_off),SY($yoff_top)+$tick_length);
      clsline($n_max,$n_max,10000);
      $numstr = sprintf("%ld",$i*$tick_inc*$x0f3);
      printf(qq(<text x="%d" y="%d" font-family="$text_font" font-size="$g_label_fontsize" text-anchor="middle">%s</text>),
	     SX($i*$tick_inc+$xx0c_off),SY($yoff_top+2)+$tick_length-1*$g_mag,$numstr);
      print "</g>\n";		# end tick/number group
    }
    print "</g>\n";		# end coordinate axis group
  } else {
    $xx0c_off += $offset0;
    # if $x0_rev need to know $x0_max_ticks

    print "<g>\n";
    for ($i=$xx_max_ticks; $i>0; $i--) {
      next if ($i*$tick_inc > $n0);
      print "<g>";
      newline("stroke=\"black\" stroke-width=\"1.5\"");
      move(SX($xx0c_off - $i*$tick_inc),SY($yoff_top));
      draw(SX($xx0c_off - $i*$tick_inc),SY($yoff_top)+$tick_length);
      clsline($n_max,$n_max,10000);
      $numstr = sprintf("%ld",$i*$tick_inc*$x0f3);
      printf(qq(<text x="%d" y="%d" font-family="$text_font" font-size="$g_label_fontsize" text-anchor="middle">%s</text>\n),
	     SX($xx0c_off - $i*$tick_inc),SY($yoff_top+2)+$tick_length-1*$g_mag,$numstr);
      print "</g>\n";
    }
    print "</g>\n";
  }

  # put on the accession

  if ($no_embed) {
      my $s_name = "Subj";
      if (defined($args{q_name}) && $args{q_name}) {
	  $s_name = $args{q_name};
      }

      my ($db, $acc, $id) = ("","","");
      if ($s_name =~ m/^gi/) {
	  my @fields = split(/\|/,$s_name);
	  ($db, $acc, $id) = @fields[2..4];
      }
      elsif ($s_name =~ m/^(\w+)\|(\w+)\|(\w+)$/) {
	  ($db, $acc, $id) = ($1, $2, $3);
      }
      else {
	  $acc = $s_name;
      }
      if ($db !~ /pdb/) {
	  $s_name = $acc;
      } else {
	  $s_name = $acc . $id;
      }
      printf(qq(<text x="%d" y="%d" font-family="$text_font" font-size="$g_name_fontsize" text-anchor="end">%s</text>\n),
	     SX(-20), SY(20), $s_name);
  }

  $xx_max_ticks = int(($n1+$offset1)/$tick_inc);
  unless ($x1_rev) { 
    $xx1c_off -= $offset1;
    # draw down-tick
    print "<g>\n";
    for ($i=1; $i<=$xx_max_ticks; $i++) {
      last if ($i*$tick_inc > $n1 + $v_offset1);
      next if ($i*$tick_inc < $v_offset1);
      print "<g>";
      newline("stroke=\"black\" stroke-width=\"1.5\"");

      move(SX($i*$tick_inc + $xx1c_off),SY($yoff_bottom));
      draw(SX($i*$tick_inc + $xx1c_off),SY($yoff_bottom)+$tick_length);
      clsline($n_max,$n_max,10000);
      $numstr = sprintf("%ld",$i*$tick_inc*$x1f3);
      printf(qq(<text x="%d" y="%d" font-family="$text_font" font-size="$g_label_fontsize" text-anchor="middle">%s</text>),
	     SX($i*$tick_inc+$xx1c_off),SY($yoff_bottom)+$tick_length+8*$g_mag,$numstr);
      print "</g>\n";
    }
    print "</g>\n";
  } else {
#    $xx_max_ticks = int(($n1)/$tick_inc);
    $xx1c_off += $offset1;
    # draw down-tick
    print "<g>\n";
    for ($i=$xx_max_ticks; $i>0; $i--) {
      next if ($i*$tick_inc > $n1 + $v_offset1);
      next if ($i*$tick_inc < $v_offset1);
      print "<g>";
      newline("stroke=\"black\" stroke-width=\"1.5\"");
      move(SX($xx1c_off - $i*$tick_inc),SY($yoff_bottom));
      draw(SX($xx1c_off - $i*$tick_inc),SY($yoff_bottom)+$tick_length);
      clsline($n_max,$n_max,10000);
      $numstr = sprintf("%ld",$i*$tick_inc*$x1f3);
      printf(qq(<text x="%d" y="%d" font-family="$text_font" font-size='$g_label_fontsize' text-anchor="middle">%s</text>\n),
	     SX($xx1c_off - $i*$tick_inc),SY($yoff_bottom)+$tick_length+8*$g_mag,$numstr);
      print "</g>\n";
    }
    print "</g>\n";
  }

  # put on the accession l_name
  if ($no_embed) {
    my $s_name = $args{l_name};
    my ($db, $acc, $id) = ("","","");
    if ($s_name =~ m/^gi/) {
      my @fields = split(/\|/,$s_name);
      ($db, $acc, $id) = @fields[2..4];
    }
    elsif ($s_name =~ m/^(\w+)\|(\w+)\|(\w+)$/) {
      ($db, $acc, $id) = ($1, $2, $3);
    }
    else {
      $acc = $s_name;
    }
    if ($db !~ /pdb/) {
      $s_name = $acc;
    } else {
      $s_name = $acc. $id;
    }

    $s_name =~ s/\.\d+$//;
    printf(qq(<text x="%d" y="%d" font-family="$text_font" font-size="$g_name_fontsize" text-anchor="end">%s</text>\n),
	   SX(-20), SY(-2), $s_name);
  }
}

sub parse_regions {
  my $region_str = shift;

  my @no_list = ();

  return \@no_list unless $region_str;

  my @regions = split(/\n\s*/,$region_str);

  $regions[0] =~ s/^\s+//;

  my @region_info = ();
  my @site_info = ();
  my @q_site_info = ();

  for my $region ( @regions) {
    $region =~ s/^\s+//;

    # simple region
    if ($region =~ m/^Region/) {

      my @fields = split(/\s+:\s*/,$region);

      my %data = ();

      unless ($fields[-1] =~ m/~/ ) {
	  @data{qw(descr color)} = @fields[-2,-1];
      }
      else {
	  @data{qw(descr color)} = split(/~/,$fields[-1]);
      }

      if ($data{color}=~ m/v$/) {
	$data{color} =~ s/v$//;
	$data{virtual} = 1;
      }
      if ($data{descr} =~ m/^(.+)\{([^\}]+)\}\s*$/) {
	$data{descr} = $1;
	$data{dom_acc} = $1;
      }
      

      $dom_colors{$data{descr}}=$data{color} unless defined($dom_colors{$data{descr}});
      $max_color = $data{color} if ($data{color} > $max_color);

      my @scores = split(/;\s*/,$fields[1]);

      for my $score (@scores) {
	my ($key, $value) = split(/=/,$score);
	$data{$key} = $value;
      }

      # this line hides low-score NODOMs
      next if ($data{color}==0 && $data{Q} < 30.0);

      @data{qw(beg0 end0 beg1 end1)} = ($fields[0] =~ m/^Region:\s*(\d+)-(\d+):(\d+)-(\d+)$/);

      push @region_info, \%data;
    }
    elsif ($region =~ m/^\s*Site:/) {
      my @fields = split(/\s+:\s+/,$region);

      my %data = ();

      ($data{stype}) = ($fields[0]=~m/Site:(.)/);

      @data{qw(qPos qRes simV lPos lRes)}  = ($fields[1]=~m/(\d+)(\w)([=z<>])(\d+)(\w)/);
      push @site_info, \%data;

    }
    elsif ($region =~ m/^\s*qSite:/) {
      my @fields = split(/\s+:\s+/,$region);

      my %data = ();

      ($data{stype}) = ($fields[0]=~m/Site:(.)/);

      @data{qw(qPos qRes simV lPos lRes)}  = ($fields[1]=~m/(\d+)(\w)([=z<>])(\d+)(\w)/);
      push @q_site_info, \%data;

    }
    elsif ($region =~ m/^\s*Variant:/) {
      my @fields = split(/\s+:\s+/,$region);

      my %data = ();
      $data{stype} = 'V';

      @data{qw(qPos qRes simV lPos lRes)}  = ($fields[0]=~m/Variant:\s*(\d+)(\w)([=z<>])(\d+)(\w)/);
      push @site_info, \%data;
    }
  }

  return (\@region_info, \@site_info, \@q_site_info);
}

sub parse_domains {
  my $domain_str = shift;

  my @no_list = ();
  return \@no_list unless $domain_str;

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

    if ($data{descr} =~ m/^(.+)\{([^\}]+)\}\s*$/) {
	$data{descr} = $1;
	$data{dom_acc} = $1;
    }

    if ($data{color} =~ m/v$/) {
      $data{color} =~ s/v$//;
      $data{virtual} = 1;
    }

    $dom_colors{$data{descr}}=$data{color} unless defined($dom_colors{$data{descr}});
    $max_color = $data{color} if ($data{color} > $max_color);

    if ($fields[0] =~ m/^qDomain/) {push @q_domain_info, \%data;}
    elsif ($fields[0] =~ m/^lDomain/) {push @l_domain_info, \%data;}

  }

  return (\@q_domain_info, \@l_domain_info);
}

sub get_model_info {
  my ($q_name, $q_dom_info_r) = @_;

  return () unless ($q_dom_info_r->[0]->{descr} =~  m/^v?(PF|CL)/);

  # require Uniprot ACC
  if ($q_name =~ m/(sp|tr)\|([A-Z][A-Z0-9]{5})\.?\d*\|/) {
    $q_name = $2;
  } elsif ($q_name =~ m/[A-Z][A-Z0-9]{5}/i) {
    $q_name =~ s/\.\d+$//;
  }
  else {
    return ();
  }

  my $annot_info = `./check_pfamseq28.pl '$q_name'`;

  my @annots = split(/\n/s,$annot_info);
  chomp @annots;

  my @annot_names = split(/\t/,shift(@annots));

  # get the domain annotations
  my @annot_list = ();
  for my $annot (@annots) {
    my %this_annot = ();
    @this_annot{@annot_names} = split(/\t/,$annot);
    push @annot_list, \%this_annot;
  }

  # associate domain annotations with $q_dom_info_r
  # modify to annotate "virtual" domains
  # also accomdate joined domains
  my $left_virtual = 0;
  my ($m_idx, $m_max) = (0, scalar(@annot_list));
  my $q_info_len = scalar(@{$q_dom_info_r});
  for (my $q_idx=0; $q_idx < $q_info_len; $q_idx++ ) {
    my $q_dom=$q_dom_info_r->[$q_idx];
    my $ann_r = $annot_list[$m_idx];

    if ($q_dom->{descr} eq $ann_r->{'pfA_acc'} || ($ann_r->{'a_clan'} && $ann_r->{'a_clan'} eq $q_dom->{descr})) {
      $q_dom->{m_start} = $ann_r->{m_start};
      $q_dom->{m_end} = $ann_r->{m_end};
      $q_dom->{m_len} = $ann_r->{m_len};

      # we have a match, check previous and next
      if ($q_idx > 0) {	# look at prev if available
	my $pq_dom = $q_dom_info_r->[$q_idx-1];
	if ($pq_dom->{descr} eq 'v'.$q_dom->{descr}) {
	  # extend left
	  unless ($left_virtual) {
	    $pq_dom->{m_end} = $ann_r->{m_start}-1;
	    $pq_dom->{m_start} = max(1,$ann_r->{m_start}-$ann_r->{s_start}+1);
	    $pq_dom->{m_len} = $ann_r->{m_len};
	  }
#	  if ($m_idx > 0 && $ann_r;
	}
      }

      if ($q_idx < $q_info_len-1) {
	my $nq_dom = $q_dom_info_r->[$q_idx+1];
	if ($nq_dom->{descr} eq 'v'.$q_dom->{descr}) {
	  # extend right
	  $nq_dom->{m_start} = $ann_r->{m_end}+1;
	  $nq_dom->{m_end} = $ann_r->{m_end} + min($ann_r->{s_len}-$ann_r->{s_end},($ann_r->{m_len}-$ann_r->{m_end}));
	  $nq_dom->{m_len} = $ann_r->{m_len};
	  $left_virtual = $nq_dom;
	  $q_idx++;
	}
	else {
	  $left_virtual = 0;
	}
      }

      # check to see whether multiple @annot_list domains belong to the same $q_dom_info_r
      while ($m_idx < $m_max-1 && $ann_r->{pfA_acc} eq  $annot_list[$m_idx+1]->{pfA_acc}) {
	if ($annot_list[$m_idx+1]->{m_start} - $ann_r->{m_end} < 10) {
	  $q_dom->{m_end} = $annot_list[$m_idx+1]->{m_end};
	  $m_idx++;
	}
	else { last;}
      }
      $m_idx++;
    }
  }
}

sub max {
  my ($arg1, $arg2) = @_;

  return $arg1 if ($arg1 >= $arg2);
  return $arg2;
}

sub min {
  my ($arg1, $arg2) = @_;

  return $arg1 if ($arg1 <= $arg2);
  return $arg2;
}


sub canon_file_name {
  my ($q_name, $l_name) = @_;

  if (! $q_name || !$l_name) {
      if (! $q_name) { $q_name = 'Query';}
      if (! $l_name) { $l_name = 'Subj';}
  }

  if ($q_name =~ m/^(sp|tr)\|([A-Z][A-Z0-9]{5})\|/) {
    $q_name = $2;
  }
  if ($l_name =~ m/^(sp|tr)\|([A-Z][A-Z0-9]{5})\|/) {
    $l_name = $2;
  }

  return $q_name . "_" . $l_name;
}

sub print_regions {
  my ($region_str, $l_descr, $hscores, $q_dom_info_r, $l_dom_info_r) = @_;

  if ($region_str eq "") {
      return;
  }

  my @region_lines = split(/\n/s,$region_str);

  my $output = "<style>\n";
  for (my $i=0; $i < scalar(@block_colors); $i++) {
    $output .= qq(span.c_$i { background-color:$block_colors[$i];}\n);
  }
  $output .= "</style>\n";

  if ($l_descr) {
      $l_descr = HTML::Entities::decode_entities($l_descr);
  } else {
      $l_descr = "";
  }

  if ($hscores) {
      $hscores = HTML::Entities::decode_entities($hscores);
  } else {
      $hscores = "";
  }

  $output .= "<pre>\n";
  $l_descr =~ s/[^\w\-\.]//g;

  $output .= $l_descr . "\n";

  my ($q_pf_ix, $l_pf_ix) = (0,0);

  for my $r_line ( @region_lines) {
    $r_line =~ s/[^\w\.\-=~:; \{\}]//g;

    if ($r_line !~ m/\sq?Region:\s/) {
      $output .= "$r_line\n";
    } else {
      if ($r_line =~ m/^\sReg/) { $r_line =~ s/^ Reg/  Reg/;}
      unless ($r_line =~ m/~\d+v?$/) {
	$output .= "$r_line\n";
      } else { # have ^ Region: ..... :\d+$
	# if it's NODOM :0, then need to check for significance
	if ($r_line =~ m/Q=(\d+\.\d+) :\s+NODOM~0$/) {
	  if ($1 < 30.0) {
	    $output .= "$r_line\n";
	  } else {		# significant match, add color
	    $r_line =~ s/  NODOM :0/<span class="c_0">NODOM<\/span>/;
	    $output .= "$r_line\n";
	  }
	} else {		# have a domain, color it
	  my ($prefix, $domain_info,$color) = ($r_line =~ m/(.+ :  )(.*)~(\d+)v?$/);
	  my $domain_acc = "";
	  # $domain_info has domain name
	  $color = $color % 9;

	  if ($domain_info =~ m/^(.+)\{(.+)\}/) {
	    $domain_info = $1;
	    $domain_acc = $2;
	  }
	  $output .= "$prefix" . qq(<span class="c_$color">$domain_info</span>);

	  $domain_acc = $domain_info if ($domain_info =~ m/^(PF|CL)/);
	  $domain_acc = $domain_info if ($domain_info =~ m/^IPR/);

	  if ($domain_acc && $domain_acc =~ m/^PF/) {
	      $output .= qq(&nbsp;&nbsp;<a href="$PFAM_FAM_URL/$domain_acc" target='domain_info'>Pfam</a>);
	  }
	  elsif ($domain_acc && $domain_acc =~ m/IPR/) {
	      $output .= qq(&nbsp;&nbsp;<a href="$IPRO_FAM_URL/$domain_acc" target='domain_win'>InterPro</a>);
	  }

	  if ($domain_info =~ m/^PF/) {
	    # is it query or library
	    if ($r_line =~ m/qRegion/) {
	      my ($m_start, $m_end, $m_len) = find_pfam_dom($r_line, $q_dom_info_r);
	    }
	    elsif ($r_line =~ m/ Region/) {
	      my ($m_start, $m_end, $m_len) = find_pfam_dom($r_line, $l_dom_info_r);
	    }
	  }
	  $output .= "\n";
	}
      }
    }
  }

  $output .= $hscores;

  print "$output</pre><hr />\n";
}

sub find_pfam_dom {};

sub check_max_xax {
  my ($max_xax, $xlen, $xlist_r) = @_;

  return $max_xax if ($max_xax > 10);

  $max_xax = -1;

  for (my $i=0; $i < scalar(@xax_len); $i++) {
    if ($xlen <= $xlist_r->[$i]) {
      $max_xax = $xlist_r->[$i];
      last;
    }
    $max_xax = $xlist_r->[$#{$xlist_r}] if ($max_xax <= 0);
  }
  return $max_xax;
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
