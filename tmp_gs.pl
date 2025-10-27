#!/usr/bin/perl -Tw

$ENV{PATH} = "/usr/bin";

use strict;

use lib qw(.);

use LWP::Simple;
use CGI qw(header param);

BEGIN {
    do "Fawww_begin.pl";
}

use Fawww_begin;
Fawww_begin::begin_log();

use vars qw( $OK_CHARS $HOST_NAME $HOST_DIR $CGI_DIR $BIN_DIR
	     $TMP_DIR $GS_BIN $PPM_BIN $LOG_FILE $lhost
	     $file $device $tmp_ps $size);

require "./fawww_defs.pl";


$file = param("name");
$file =~ s/[;><&\*`\|\s]//g;

if ($file =~ /^([\w\.]+)$/) {
  $tmp_ps = $1;                     # $data now untainted
}

$size = param("size");
if ($size) { 
  $size =~ s/[^$OK_CHARS]/_/go;
  if ($size =~ /^(\d+x\d+)$/) {
    $size = "-g".$1;                     # $data now untainted
  }
  else { $size = "";}
}

$device = param("dev");
if ($device =~ /png/) { $device = "png256";}
elsif ($device =~ /pdf/) { $device = "pdfwrite";}
else { $device = "png256";}

if ($device eq "png256") {print header(-type=>'image/png');}
elsif ($device eq "pdfwrite") {print header(-type=>'application/pdf');}

$|  = 1;

if ($tmp_ps) {$tmp_ps = "$TMP_DIR/$tmp_ps";}
else {$tmp_ps = ""; exit(1);}

# print STDERR "tmp_ps: $tmp_ps\n";

if ($tmp_ps) {
  system($GS_BIN,split(' ',"-q $size -dNOPAUSE -sDEVICE=$device -sOutputFile=- $tmp_ps -c quit"));
}

if (param("del") && (param("del") eq "yes")) {unlink "$tmp_ps";}
