#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use HTML::Template;
use DBI;
use CGI qw(header param start_html end_html);
use LWP::Simple;
use XML::Twig;

my @fields = qw(pfA_acc pfA_id s_start s_end s_len m_start m_end m_len m_cov evalue clan_acc clan_id );

my ($q, $acc, $doms_only, $show_seq, $seq_only, $www_flag) = (0,0,0,0,0,0);

my $DOC_ROOT = $ENV{'DOCUMENT_ROOT'};

$q = new CGI;
$acc=$q->param('acc');
($acc) =~ m/(\w+)/;

$doms_only = $q->param('doms_only') || 0;
($doms_only) =~ m/(\w+)/;

$show_seq = $q->param('seq') || 0;
($show_seq) =~ m/(\w+)/;

$seq_only = $q->param('seq_only') || 0;
($seq_only) =~ m/(\w+)/;

$www_flag = $q->param('www') || 0;
($www_flag) =~ m/(\w+)/;


my @f_titles = ();

if ($www_flag) {
  @f_titles = ("acc", @fields);
}
else {
  @f_titles = ("acc", "auto_reg_full", @fields);
}
my $output = join("\t",@f_titles)."\n";

if ($acc) {
  if ($acc =~ m/^(sp|tr)\|([A-Z][A-Z0-9]{5})\|/i) {
    $acc = $2;
  } elsif ($acc =~ m/^gi\|\d+\|/) {
    my @fields = split(/\|/,$acc);
    $acc = $fields[3];
  }
} else {
  $acc = "";
}

my ($pfamseq_acc, $pfamseq_id, $descr, $sequence, $fa_seq, $description) = ("","","","",0,"");

my @pf_fields = ();
my @dom_data = ();

if ($www_flag) {
  @pf_fields = qw(acc accession id start end length hmm_start hmm_end model_length model_cov evalue clan_acc clan_id);
}
else {
  @pf_fields = qw(acc auto_pfamA_reg_full pfamA_acc pfamA_id seq_start seq_end length model_start model_end model_length model_cov evalue clan_acc clan_id);
}

my ($dom_data_ref, $seq_data_ref) = (0,0);
if ($acc) {
  if ($www_flag) {
    $dom_data_ref = get_pfam_dom_www($acc);
    $seq_data_ref = get_pfam_seq_www($acc);
  }
  else {
    my $dbh = init_dbh();
    $dom_data_ref = get_pfam_dom_sql($dbh, $acc);
    $seq_data_ref = get_pfam_seq_sql($dbh, $acc);

  }

  for my $dom_ref (@$dom_data_ref) {
    $output .= join("\t",@{$dom_ref}{@pf_fields})."\n";
  }

  my ($pfamseq_acc, $pfamseq_id, $descr, $sequence) = @{$seq_data_ref}{qw(pfamseq_acc pfamseq_id description sequence)};
  $description = "$pfamseq_acc|$pfamseq_id $descr";

  if ( $show_seq || $seq_only) {
    $sequence =~ s/(.{60})/$1\n/g;
    $fa_seq = ">sp|$pfamseq_acc|$pfamseq_id $descr\n$sequence\n";
  }
}

unless ($seq_only || $doms_only) {
  print $q->header();
  my $tmpl = HTML::Template->new(filename=>'check_pfamseq_u.tmpl',associate=>$q);
  $tmpl->param(ACC=>$acc);
  if ($dom_data_ref) {
    $tmpl->param(not_found => 0);
    $tmpl->param(description => $description);

    my @hfields = map { {'hfield'=> $_} } @f_titles;
    $tmpl->param(theader=>\@hfields);


    my @d_rows = ();
    for my $dom_ref ( @{$dom_data_ref}) {
      my @d_fields = map { {'dfield'=>$_} } @{$dom_ref}{@pf_fields};
      push @d_rows, {dfields => \@d_fields};
    }

    $tmpl->param(trows=>\@d_rows);
    #$tmpl->param(DOMAIN_INFO=>$output);
    if ($fa_seq) {
      $tmpl->param(sequence => $fa_seq);
    }
    print $tmpl->output();
  }
  else {
    $tmpl->param(not_found => 1);
    print $tmpl->output();
  }
}
else {
  if ($DOC_ROOT) {print $q->header(type=>'text/plain');}
  if ($seq_only && $fa_seq) { print $fa_seq,"\n";}
  else {
    print $output;
  }
}

sub get_pfam_dom_sql {
  my ($dbh, $acc) = @_;


  ## get total query count grouped by auto_pfamA
  my $st_get_seq_doms_clan = $dbh->prepare(<<EOSQL);

SELECT  auto_pfamA_reg_full, pfamA_acc, pfamA_id, seq_start, seq_end, length, model_start, model_end, model_length, domain_evalue_score as evalue, clan_acc, clan_id
FROM    pfamA_reg_full_significant
JOIN    pfamseq USING(pfamseq_acc)
JOIN    pfamA USING(pfamA_acc)
LEFT JOIN clan_membership using(pfamA_acc)
LEFT JOIN clan using(clan_acc)
WHERE   pfamseq_acc = ?
 AND    in_full=1
ORDER BY seq_start

EOSQL

  $st_get_seq_doms_clan->execute($acc);

  my @dom_list = ();
  while (my $pf_data_hr = $st_get_seq_doms_clan->fetchrow_hashref()) {
    $pf_data_hr->{clan_acc} = 0 unless $pf_data_hr->{clan_acc};
    $pf_data_hr->{clan_id} = 0 unless $pf_data_hr->{clan_id};
    $pf_data_hr->{model_cov} = sprintf("%.4f",($pf_data_hr->{model_end} - $pf_data_hr->{model_start}+1)/$pf_data_hr->{model_length});
    $pf_data_hr->{acc} = $acc;
    push @dom_list, $pf_data_hr;
  }
  return \@dom_list;
}

sub get_pfam_seq_sql {
  my ($dbh, $acc) = @_;

  my $st_get_sequence = $dbh->prepare(<<EOSQL);

SELECT pfamseq_acc, pfamseq_id, description, sequence
FROM pfamseq
WHERE pfamseq_acc = ?
EOSQL

  $st_get_sequence->execute($acc);

  my $seq_hr = $st_get_sequence->fetchrow_hashref();
  return $seq_hr;
}

sub init_dbh {
  my ($host,$db, $user, $pass) = ("wrpa48.bioch.virginia.edu", "pfam37", "web_user", "fasta_www");
  my $dbh = DBI->connect(qq{dbi:MariaDB:database=$db;host=$host},
			 $user,
			 $pass
			) or die $DBI::errstr;
  return $dbh;
}


my ($pfseq_length, $pf_model_length, $clan_acc, $clan_id, $pfseq_acc, $pfseq_id, $pfseq_descr, $pfseq_sequence) = (0,0,"","","","","","");
my @pf_domains = ();

sub get_length {
    my ($t, $elt) = @_;
    $pfseq_length = $elt->{att}->{length};
    $pfseq_sequence = $elt->{first_child}->{pcdata};
}

sub push_match {
    my ($t, $elt) = @_;
#    return unless ($elt->{att}->{type} =~ m/Pfam-A/);
    my $attr_ref = $elt->{att};
    my $loc_ref = $elt->first_child('location')->{att};
    push @pf_domains, { %$attr_ref, %$loc_ref };
}

sub get_model_length {
    my ($t, $elt) = @_;
    $pf_model_length = $elt->{att}->{model_length};
}

sub get_entry {
    my ($t, $elt) = @_;
    $pfseq_acc = $elt->{att}->{accession};
    $pfseq_id = $elt->{att}->{id};
    $pfseq_descr = $elt->{first_child}->{first_child}->{cdata};
    $pfseq_descr =~ s/\n//mg;
}

sub get_clan {
    my ($t, $elt) = @_;
    my $attr_ref = $elt->{att};
#    print Dumper($attr_ref);
    ($clan_acc, $clan_id) = ($attr_ref->{clan_acc},$attr_ref->{clan_id});
}

sub get_pfam_dom_www {
  my ($acc) = @_;

  my %pfamA_fams = ();

  my $loc="http://pfam.xfam.org/";
  my $url = "protein/$acc?output=xml";

  my $res = get($loc . $url);

  my $twig_dom = XML::Twig->new(twig_roots => {matches => 1, sequence => 1, entry=>1},
			    twig_handlers => {
					      'entry' => \&get_entry,
					      'match' => \&push_match,
					      'sequence' => \&get_length,
					     },
			    pretty_print => 'indented');
  my $xml = $twig_dom->parse($res);

  @pf_domains = sort { $a->{start} <=> $b->{start} } @pf_domains;

  for my $curr_dom (@pf_domains) {
    unless (defined($pfamA_fams{$acc})) {
      $curr_dom->{length} = $pfseq_length;

      my $acc = $curr_dom->{accession};
      $url = "family/$acc?output=xml";

      my $res = get($loc . $url);

      my $twig_fam = XML::Twig->new(twig_roots => {hmm_details => 1, clan_membership=> 1},
				    twig_handlers => {
					'hmm_details' => \&get_model_length,
					'clan_membership' => \&get_clan,
				    },
				    pretty_print => 'indented');

      ($clan_acc, $clan_id) = ("","");
      my $fam_xml = $twig_fam->parse($res);

      $pfamA_fams{$acc} = { model_length => $pf_model_length, clan_acc=>$clan_acc, clan_id=>$clan_id};
      $curr_dom->{model_length} = $pf_model_length;
      $curr_dom->{clan_acc} = $clan_acc;
      $curr_dom->{clan_id} = $clan_id;
    }
    else {
      @{$curr_dom}{qw(model_length clan_acc clan_id)} = @{$pfamA_fams{$acc}}{qw(model_length clan_acc clan_id)}
    }
    $curr_dom->{acc} = $acc;
    $curr_dom->{model_cov} = sprintf("%.4f",($curr_dom->{hmm_end} - $curr_dom->{hmm_start}+1)/$curr_dom->{model_length});
  }

  return \@pf_domains;
}

sub get_pfam_seq_www {
  my ($acc) = @_;

  return {'pfamseq_acc'=>$pfseq_acc, 'pfamseq_id'=>$pfseq_id, 'description'=>$pfseq_descr, 'sequence'=>$pfseq_sequence};
}

