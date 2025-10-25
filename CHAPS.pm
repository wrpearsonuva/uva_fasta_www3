
# $Id: CHAPS.pm 35 2009-10-28 18:29:25Z wrp $
# $Revision$

package CHAPS; use base 'CGI::Application';

use CGI::Carp;
use LWP::Simple;
use File::Temp ();
use IPC::Run qw(timeout);
use IO::Scalar;
use Text::ParseWords;
use Data::Dumper;

use vars qw( $DEF_UNLINK $OK_CHARS $HOST_NAME $HOST_DIR $CGI_DIR $RUN_URL
	     $BIN_DIR $DEBUG $TMP_DIR $BL_BIN_DIR $BL_DATA_DIR
             $BL_DB_DIR $BL_DUMMY_DB $BL_DB_NT_DIR %form_list %run_subs );

require "./fawww_defs.pl";
require "./fawww_subs.pl";
require "./chaps_pgms.pl";

use strict;

sub setup {
  my $self = shift;

  $self->start_mode("start");
  $self->mode_param("rm");

  $self->run_modes(
		   start => \&do_form,
		   gen_pssm => \&do_form,
		   gen_hmm => \&do_form,
		   cal_hmm => \&do_form,
		   load_hmm => \&do_form,
		   load_msa => \&do_form,
		   gen_msa => \&do_form,
		   );

}

sub teardown {
    my $self = shift;
    # empty, for now.
}

sub do_form {
  my ($self) = shift @_;

  my $form_name = $self->get_current_runmode();

# check that we know the run mode as a display form
#

  unless ($form_name) {
    return fasta_error("Undefined RUN_MODE\n");
  }

  my $form_href = $form_list{$form_name};

  unless ($form_name) {
    return fasta_error("Form parameters undefined for $form_name\n");
  }

# get the template
#
  my $tmpl = $self->load_tmpl($form_href->{tmpl});

# load various other TMPL_VAR's for form
#
  load_vars($form_href->{outputs}, $tmpl);

# the next functions change the form depending on input arguments
#
  my $q = $self->query();

  $DEBUG = $DEBUG || ($q->param('DEBUG') && ($q->param('DEBUG') == 1));

  load_inputs($form_href,$tmpl,$q);

  my ($r_host, $c_host) = get_hosts($self);
  Do_log($r_host, "CHAPS: $form_name");

  $run_subs{$form_name}($q, $tmpl) if (exists $run_subs{$form_name});

  if ($DEBUG) {
      return $self->dump_html() . "\n" . $tmpl->output();
  }
  else {return $tmpl->output();}
}

sub gen_pssm {
  my ($q, $tmpl) = @_;

  my $queryfh = new File::Temp(TEMPLATE=>"CH_XXXXXX", DIR=>$TMP_DIR,SUFFIX=>".msa", UNLINK => $DEF_UNLINK);
  my $queryfile = $queryfh->filename();
  my ($queryroot) = ($queryfile =~ m/^(.*)\.msa$/);

  my $alignfile = $queryroot .".baln";
  open(ALN_FH, ">$alignfile");

  my $pssmfile = $queryroot . ".pssm";

  chmod 0644, $queryfile;

  my $is = $q->param("msa_query");
  $is =~ s/\r\n/\n/gs;
  while ( $is =~ m/\n\n$/) {
      $is =~ s/\n\n$/\n/s;
  }

# allow read of $q->param("msa_query") (which is now a clustalw/muscle/t_coffee alignment)
  my $isfh = new IO::Scalar \$is;

  my $sawblank = 1; my $idprinted = 0;
  while (<$isfh>) {
      next if (m/^CLUSTAL/);
      next if (m/^MUSCLE/);
      print ALN_FH $_ unless $sawblank && m/^\s*$/o;	# skip blanks unless non-blank
      if ($sawblank && !m/^\s*$/o) {
	    chomp;
	    my ($id, $seq) = m/^\s*(\S+)\s*(.*)/;
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

  `$BIN_DIR/blastpgp -t 1 -i $queryfile -B $alignfile -Q $pssmfile -o /dev/null -d $BL_DB_DIR/$BL_DUMMY_DB`;

  open(POS, "<$pssmfile") or die $!;
  $tmpl->param(PROFILE => join("", grep { m/^\s*(\d+|(A\s+R\s+N\s+D\s+C))/o } <POS>));
  close(POS);
}

sub gen_hmm {
  my ($q, $tmpl) = @_;

  my $alignfh = new File::Temp(TEMPLATE=>"CH_XXXXXX", DIR=>$TMP_DIR,SUFFIX=>".msa", UNLINK => $DEF_UNLINK);
  my $alignfile = $alignfh->filename();
  chmod 0644, $alignfile;

  my ($alignroot) = ($alignfile =~ m/^(.*)\.msa$/);
  my $hmmfile = $alignroot . ".hmm";


  my $is = $q->param("msa_query");
  $is =~ s/\r\n/\n/gs;
  if ($is =~ m/# STOCKHOLM 1.0/) {
    print $alignfh $is;
  }
  else {
    my $isfh = new IO::Scalar \$is;
    my $sawblank = 1; my $idprinted = 0;
################
# convert multiple sequence alignment to CLUSTAL-W format tag
#
    print $alignfh "# STOCKHOLM 1.0\n";
    while (<$isfh>) {
      $_ = "# $_" if (m/CLUSTAL 2/ || m/CLUSTAL W/ || m/T-COFFEE/ || m/MUSCLE/);

      if (m/^\s+[\.|\:|\*]/) { s/^ /#/;}
      print $alignfh $_; # unless $sawblank && m/^\s*$/o;
    }
    print $alignfh "\n//\n";
  }

  close($alignfh);

#  `$BIN_DIR/hmmbuild -F --informat CLUSTAL $hmmfile $alignfile`;
  `$BIN_DIR/hmmbuild $hmmfile $alignfile`;

  open(HMMER, "<$hmmfile") or die $!;
  $is = do { local ($/); <HMMER> };	# undef $/ for slurp;

#  $is = join("", grep { 1 } <HMMER>);

  my $exp_name = $q->param("exp_name") || "my_hmm";
  $is =~ s/$alignroot/$exp_name/go;

  $tmpl->param(HMM => $is);
  close(HMMER);
}

sub load_hmm {
  my ($q, $tmpl) = @_;

  my $exp_name = $q->param("exp_name") || "my_hmm";

  my $is = "";

  if ($q->param("hmm_file")) {
    my $file_name = get_safe_filename($q, "hmm_file");
    my $qfh = $q->upload("hmm_file");
    unless ($qfh) {
      carp("Could not upload: $file_name");
      if ($q->cgi_error()) { carp($q->cgi_error());}
      return "";
    }
    while (<$qfh>) {
	$is .= $_;
    }
    close $qfh;
    $tmpl->param(HMM => $is);
  }
  else {return "";}
}

sub load_msa {
  my ($q, $tmpl) = @_;

  my $exp_name = $q->param("exp_name") || "my_msa";

  my $is = "";

  if ($q->param("msa_file")) {
    my $file_name = get_safe_filename($q, "msa_file");
    my $qfh = $q->upload("msa_file");
    unless ($qfh) {
      carp("Could not upload: $file_name");
      if ($q->cgi_error()) { carp($q->cgi_error());}
      return "";
    }
    while (<$qfh>) {
	$is .= $_;
    }
    close $qfh;
    $tmpl->param(MSA_QUERY => $is);
    $tmpl->param(MSA_QUERY_UP => 1);
  }
  else {return "";}
}

sub cal_hmm {
  my ($q, $tmpl) = @_;

  my $hmmfh = new File::Temp(TEMPLATE=>"CH_XXXXXX", DIR=>$TMP_DIR, SUFFIX=>".hmm", UNLINK => $DEF_UNLINK);
  my $hmmfile = $hmmfh->filename();
  chmod 0644, $hmmfile;

  unless ($q->param("hmm")) { return "";}

  my ($hmmroot) = ($hmmfile =~ m/^(.*)\.hmm$/);
  my $exp_name = $q->param("exp_name") || "my_hmm";

  my $is = "";

  $is = $q->param("hmm");

  $is =~ s/\r\n/\n/gs;
  print $hmmfh $is;
  close $hmmfh;

  `$BIN_DIR/hmmcalibrate $hmmfile`;

  open(HMMER, "<$hmmfile") or die $!;
  $is = do { local ($/); <HMMER> };	# undef $/ for slurp;

#  $is = join("", grep { 1 } <HMMER>);

  $is =~ s/$hmmroot/$exp_name/g;
  $tmpl->param(HMM => $is);
  close(HMMER);
}

sub gen_msa {
  my ($q, $tmpl) = @_;

  my $ifh = new File::Temp(TEMPLATE=>"CH_XXXXXXX", DIR=>$TMP_DIR, SUFFIX=>".lib", UNLINK => $DEF_UNLINK);
  my $ifilename = $ifh->filename();

  my ($ifileroot) = ($ifilename =~ m/^(.*)\.lib$/);
  my $ofilename  = "$ifileroot.aln";
  my $tfilename  = "$ifileroot.dnd";

  my $is = $q->param("msa_query");
  $is =~ s/,/\n/gs;
  $is =~ s/\r\n/\n/gs;

  chmod 0644, $ifilename;

  print STDERR "query:$is:\n";
  print STDERR "clustal lib: $ifilename\n";
  print STDERR "clustal aln: $ofilename\n";

  my $ids = "";
  if ($q->param("q_type") && $q->param("q_type") =~ m/^acc/i) {
    for my $acc (split(/[\s,]+/, $is)) {
      my $query = get_query($acc, $q->param("q_type"));
      $query =~ s/^>gi\|\d+\|/>/;
      my ($id) = ($query =~ m/^>(\S{1,6})/);
      $id =~ s/\|//g;
      $ids .= "|$id";
      if ($query) {
	print $ifh "$query\n";
      } else {
	warn "$acc not found\n";
      }
    }
  } else {
    print $ifh $is;
    local $/ = "\n>";
    $ids = join("|", map { chomp; m!^>?(\S{1,6})!; "\Q$1\E"; } split("$/", $is));
    # $ids is a list of the first six letters of the ID: gstm1_|gstm2_|gstm3_| for labeling below
  }
  close($ifh);

  if ($q->param('msa_pgm') =~ m/muscle/) {
      `$BIN_DIR/muscle -quiet -in $ifilename -out $ofilename -clw`;
  }
  elsif ($q->param('msa_pgm') =~ m/tcoffee/) {
      $ENV{HOME_4_TCOFFEE} = $TMP_DIR;
      $ENV{TMP_4_TCOFFEE} = $TMP_DIR;
      $ENV{DIR_4_TCOFFEE} = $TMP_DIR;
      $ENV{NO_ERROR_REPORT_4_TCOFFEE} = 1;
      $ENV{NO_WARNING_4_TCOFFEE} = 1;
#      print STDERR "$BIN_DIR/t_coffee -infile $ifilename -outfile $ofilename\n";
      `$BIN_DIR/t_coffee -infile $ifilename -outfile $ofilename -quiet -no_warning -newtree $tfilename`;
      unlink($tfilename);
  }
  else {	# run clustalw
      `$BIN_DIR/clustalw -infile=$ifilename -outfile=$ofilename -type=protein`;
  }
  open(OUT, "<$ofilename") or die $!;
  #    <OUT>;  #skip CLUSTAL W line
  {
    $tmpl->param(MSA_QUERY => join("", grep { $_ =~ m/ (^\s*$) | ^($ids) /x } <OUT>));
  }
  close(OUT);
  $tmpl->param(GEN_MSA_STAT => 1);

#  unlink("$ifilename.dnd");
#  unlink("$ifilename");
#  unlink("$ofilename");
}

sub get_query {
  my ($query, $type)  = @_;

  unless ($query) {return "";}

#  printf STDERR "get_query: $query $type\n";

  if (($type && $type =~ m/^acc/i) ||
      $query =~ m/^gi\|/ ||
      $query =~ m/^\s*\d+\s*$/ ) {
      
      my $tmp_query = get_fastacmd("Protein", $query);
      unless ($tmp_query) {
#	  $query = get_ncbi("Protein", $query);
#	$tmp_query=get_uniprot("Protein",$query);
	$tmp_query=get_protein("Protein",$query);
      }

      $tmp_query =~ s/\.\d+//;
#      printf STDERR $query;
      return $tmp_query;
  }
  else {
      if ($query =~ m/^>/) {
	  return $query . "\n";
      }
      else {
	  return ">QUERY\n" . $query ."\n";
      }
  }
}

sub get_opts_byref {
  my ($q,$run_href, $opt_type) = @_;

  my %fa_opts = ();

  return () unless $run_href->{$opt_type};

  my $opt_href = $run_href->{$opt_type};

  for my $opt ( keys( %{$opt_href} )) {
    my $opt_lref = $opt_href->{$opt};
    if ($q->param($opt)) {
      if (ref($opt_lref->[1]) eq 'CODE') {
	$fa_opts{$opt} = 
	    $opt_lref->[1]->($opt_lref->[0],$q->param($opt),$q, $opt);
      }
#
#  we don't allow "this" here because we don't want to just grab unparsed
#  input parameters
#
      else { $fa_opts{$opt} = $opt_lref->[0];}
    }
    else {
      if ($opt_lref->[2]) {$fa_opts{$opt} = $opt_lref->[2];}
    }
  }
  return %fa_opts;
}

sub footer {

  return <<EOF
<hr />
<center>
<a href="fasta_www.cgi">Search Databases with FASTA</a> | 
<a href="fasta_www.cgi?rm=lalign">Find Duplications</a> | 
<a href="fasta_www.cgi?rm=misc1">Hydropathy/Secondary Structure</a> 
</center>
<hr />
EOF

}

1;
