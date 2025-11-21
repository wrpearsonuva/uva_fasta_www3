#!/usr/bin/perl -Tw

# takes an lav file and produces either SVG, png, or pdf output.

$ENV{PATH} = "/usr/bin";

use strict;

use lib qw(.);

use LWP::Simple;
use CGI qw(header param);

BEGIN {
    do "Fawww_begin.pl";
}

use vars qw( $OK_CHARS $HOST_NAME $HOST_DIR $CGI_DIR $BIN_DIR 
	     $TMP_DIR $GS_BIN $DEF_UNLINK $LAV_SVG $LAV_GS $lav_cmd
	     $PPM_BIN $LOG_FILE $lhost $SQL_DB_HOST
	     $file $device $tmp_lav $size $z_param);

require "./fawww_defs.pl";

my @ann_scripts = ("", 
		   "", 
		   qq('\!./annot/ann_feats2ipr.pl --host $SQL_DB_HOST --lav'),
		   qq('\!./annot/ann_feats_up_sql.pl --host $SQL_DB_HOST --lav'),
		   qq('\!./annot/ann_feats2ipr.pl --host $SQL_DB_HOST --lav'),
		   qq('\!./annot/ann_pfam_sql.pl --host $SQL_DB_HOST --lav'),
##		   qq('\!./annot/ann_pfam_www2.pl --lav --pfacc'),
		   qq('\!./annot/ann_pfam_sql.pl --host $SQL_DB_HOST --lav --pfacc'),
##		   qq('\!./annot/ann_pfam_www2.pl --lav --pfacc'),
		   qq('\!./annot/ann_pdb_cath.pl --host $SQL_DB_HOST --lav'),
		   qq('\!./annot/ann_pdb_cath.pl --host $SQL_DB_HOST --class --lav'),
);

my $dopts = "";

$file = param("name") || "";
$file =~ s/[;><&\*`\|\s]//g;

if (param("xA")) {
  my ($script_index) =  ( param("xA") =~ m/^(\d)$/ );

  if ($script_index > 1 && $script_index < scalar(@ann_scripts)) {
    $dopts .=   " --xA " . $ann_scripts[$script_index];
  }
}

if (param("yA")) {
  my ($script_index) =  ( param("yA") =~ m/^(\d)$/ );
  if ($script_index > 1 && $script_index < scalar(@ann_scripts)) {
    $dopts .=   " --yA " . $ann_scripts[$script_index];
  }
}

$LAV_SVG = "./lav2plt.cgi --dev svg -Z 1" . $dopts;
$LAV_GS = "./lav2plt.cgi --dev ps -Z 1" . $dopts;

if ($file =~ /^([\w\.]+)$/) {
  $tmp_lav = $1;                     # $data now untainted
}

$size = param("size") || "";
if ($size) { 
  $size =~ s/[^$OK_CHARS]/_/go;
  if ($size =~ /^(\d+x\d+)$/) {
    $size = "-g".$1;                     # $data now untainted
  }
  else { $size = "";}
}

if (param("Z")) {
    $z_param = get_safe_number("-Z", scalar(param("Z")));
}
else {$z_param = "";}

$device = param("dev");
if ($device =~ m/pdf/) {
    $device = "pdfwrite";
    unless ($ENV{HTTP_USER_AGENT} =~ m/AppleWebKit/) {
	print header(-type=>'application/pdf', -attachment=>'plalign.pdf');
    }
    else {
	print header(-type=>'application/pdf');
    }
}
elsif ($device =~ m/svg/i) {
    $device = "svg";
    print header(-type=>'image/svg+xml');	# no download file name
}
else {
    $device = "png256";
    print header(-type=>'image/png'); # no download file
}

$|  = 1;

# print STDERR "tmp_lav: $tmp_lav\n";

if ($tmp_lav) {
  $tmp_lav = "$TMP_DIR/$tmp_lav";
  if ($device eq 'svg') {
    $lav_cmd = "$LAV_SVG $z_param < $tmp_lav" ;
  }
  else {
    $lav_cmd = "$LAV_GS $z_param < $tmp_lav | $GS_BIN -q $size -dNOPAUSE -sDEVICE=$device -sOutputFile=- -";
  }

  system("$lav_cmd");

  if (param("del") && (param("del") eq "yes")) {unlink "$tmp_lav";}
  exit(0);
}
else {
  die(" tmp_lav.cgi - no file to process");
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
