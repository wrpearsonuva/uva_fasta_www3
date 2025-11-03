#!/usr/bin/perl -Tw

#  down_file.cgi  - provides automatic download of Clustal MSA, PSI-BLAST PSSM (ASN.1), or
#  HMMR HMM
#

use strict;

use lib qw(.);

BEGIN {
    do "Fawww_begin.pl";
}

use CGI;
use CGI::Carp qw(fatalsToBrowser carpout warningsToBrowser);
use IO::Scalar;
use File::Temp qw/ tempfile /;

require "./fawww_defs.pl";

$ENV{PATH} = "/usr/bin";


use vars qw($DEF_UNLINK $BIN_DIR $BL_DB_DIR $BL_DB_NT_DIR $BL_BIN_DIR
	    $BL_DATA_DIR $TMP_DIR );

my $q = new CGI;
my $rm = $q->param("rm");

my %run_table = 
    ("clustal" => \&down_clustal,
     "pssm" => \&down_pssm,
     "hmm" => \&down_hmm,
     );

unless ($rm && exists $run_table{$rm}) {
    print $q->header();
    print $q->start_html("Run-mode undefined");
    print "<pre>\n";
    for my $p ( $q->param() ) {
	print "$p : ".$q->param($p)."\n";
    }
    print $q->end_html();
    exit 0;
}

$run_table{$rm}($q);
exit;

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

sub down_clustal {
    my $q = shift;
    unless ($q->param('msa_query')) {
	return "";
    }

    my $output = $q->param('msa_query');
    $output =~ s/\r\n/\n/gos;
    text_header($q,"clustal.aln");
    print $output;
}

sub down_pssm {
    my $q = shift;

    my ($queryfh, $queryfile) = tempfile("CH_XXXXXX", DIR=>$TMP_DIR,SUFFIX=>".msa", UNLINK => $DEF_UNLINK);
    my $oldfh = select $queryfh; $|++;

    my ($alignfh, $alignfile) = tempfile("CH_XXXXXX", DIR=>$TMP_DIR,SUFFIX=>".baln", UNLINK => $DEF_UNLINK);

    my ($pssmfh, $pssmfile) = tempfile("CH_XXXXXX", DIR=>$TMP_DIR,SUFFIX=>".asn1", UNLINK => $DEF_UNLINK);

    chmod 0755, $queryfile, $alignfile, $pssmfile;

    select $alignfh; $|++;	# turn on autoflush for $alignfh
    select $oldfh;

    my $is = $q->param("msa_query");

    my $pssm_fmt = '2';
    if ($q->param("pssm_fmt") && $q->param("pssm_fmt") eq 'text') { $pssm_fmt = 1;}

    $is =~ s/\r\n/\n/gs;

# allow read of param("msa_query") (which is now a clustalw alignment)
    my $isfh = new IO::Scalar \$is;
    my $sawblank = 1; my $idprinted = 0;
    my ($id, $seq);
    while (<$isfh>) {
	next if (m/^CLUSTAL/);
	next if (m/^MUSCLE/);
	print $alignfh $_ unless $sawblank && m/^\s*$/o;	# skip blanks unless non-blank
	if ($sawblank && !m/^\s*$/o) {
	    chomp;
	    ($id, $seq) = m/^\s*(\S+)\s*(.*)/;
	    $seq =~ s/\W//g;
	    print $queryfh ">$id\n" unless $idprinted++;
	    print $queryfh "$seq\n";
	    $sawblank--;
	} elsif (!$sawblank && m/^\s*$/o) {
	    $sawblank++;
        }
    }

    $ENV{BLASTDB} = $BL_DB_DIR;
    $ENV{BLASTMAT} = $BL_DATA_DIR;
    $ENV{BLASTFILTER} = $BL_DATA_DIR;

    system("$BL_BIN_DIR/blastpgp",split(' ',"-i $queryfile -B $alignfile -J T -u $pssm_fmt -C $pssmfile -o /dev/null -d $BL_DB_DIR/pir1"));

    my $buf;
    open (POS,"$pssmfile") || die "Cannot open $pssmfile\n";

    my ($prefix) = ($id =~ m/^.*[^\|]*\|(.+)$/);
    $id =~ s/\|/_/g;
    $prefix = $id unless $prefix;
    if ($pssm_fmt == 1) {octet_header($q,$prefix."_pssm.asn1_txt");}
    else {octet_header($q,$prefix."_pssm.asn1");}
    while (read(POS,$buf, 2048)) { print $buf; }
    close(POS);
}

sub down_hmm {
    my $q = shift;

    unless ($q->param('hmm')) {
	return "";
    }

    my $name = $q->param('exp_name') || "msa";
    my $output = $q->param('hmm');
    $output =~ s/\r\n/\n/gos;
    text_header($q,"$name.hmm");
    print $output;
}

sub fasta_error {

    my $msg = shift;

    return "<p><hr><p><h2> $msg </h2><p><hr><p></body></html>\n";
}
