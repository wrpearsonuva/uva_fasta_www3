#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use HTML::Template;
use DBI;
use CGI qw(header param start_html end_html);

my ($host,$db, $user, $pass) = ("a48", "pfam28", "web_user", "fasta_www");

my $dbh = DBI->connect(qq{dbi:mysql:database=$db;host=$host},
		       $user,
		       $pass
		      ) or die $DBI::errstr;

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

my $st_get_sequence = $dbh->prepare(<<EOSQL);

SELECT pfamseq_acc, pfamseq_id, description, sequence
FROM pfamseq
WHERE pfamseq_acc = ?
EOSQL


my @fields = qw(auto_reg_full pfA_acc pfA_id s_start s_end s_len m_start m_end m_len m_cov evalue clan_acc clan_id );

my $q = new CGI;

my $acc=$q->param('acc');
my $doms_only = $q->param('doms_only') || 0;
my $show_seq = $q->param('seq') || 0;
my $seq_only = $q->param('seq_only') || 0;

my @f_titles = ("acc", @fields);
my $output = join("\t",@f_titles)."\n";
my @hfields = map { {'hfield'=> $_} } @f_titles;


my $found = 0;
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

my @d_rows = ();
my ($pfamseq_acc, $pfamseq_id, $descr, $sequence, $fa_seq, $description) = ("","","","",0,"");

my @pf_fields = qw(auto_pfamA_reg_full pfamA_acc pfamA_id seq_start seq_end length model_start model_end model_length model_cov evalue clan_acc clan_id);


if ($acc) {
  $st_get_seq_doms_clan->execute($acc);

  my $pf_data_hr;
  while ($pf_data_hr = $st_get_seq_doms_clan->fetchrow_hashref()) {
    $found = 1;
    $pf_data_hr->{clan_acc} = 0 unless $pf_data_hr->{clan_acc};
    $pf_data_hr->{clan_id} = 0 unless $pf_data_hr->{clan_id};
    $pf_data_hr->{model_cov} = sprintf("%.4f",($pf_data_hr->{model_end} - $pf_data_hr->{model_start}+1)/$pf_data_hr->{model_length});

    my @dom_data = ($acc, @{$pf_data_hr}{@pf_fields});
    $output .= join("\t",@dom_data)."\n";

    my @d_fields = map { {'dfield'=>$_} } @dom_data;
    push @d_rows, {dfields => \@d_fields};
  }

  $st_get_sequence->execute($acc);
  ($pfamseq_acc, $pfamseq_id, $descr, $sequence) = $st_get_sequence->fetchrow_array();
  $description = "$pfamseq_acc|$pfamseq_id $descr";

  if ( $show_seq || $seq_only) {
    $sequence =~ s/(.{60})/$1\n/g;
    $fa_seq = ">sp|$pfamseq_acc|$pfamseq_id $descr\n$sequence\n";
  }
}

unless ($seq_only || $doms_only) {
  print $q->header();
  my $tmpl = HTML::Template->new(filename=>'check_pfamseq28.tmpl',associate=>$q);
  $tmpl->param(ACC=>$acc);
  if ($found) {
    $tmpl->param(not_found => 0);
    $tmpl->param(description => $description);
    $tmpl->param(theader=>\@hfields);
    $tmpl->param(trows=>\@d_rows);
    #$tmpl->param(DOMAIN_INFO=>$output);
    $tmpl->param(sequence => $fa_seq);
    print $tmpl->output();
  }
  else {
    $tmpl->param(not_found => 1);
    print $tmpl->output();
  }
}
else {
  print $q->header(type=>'text/plain');
  if ($seq_only) { print $fa_seq,"\n";}
  else {
    print $output;
  }
}
