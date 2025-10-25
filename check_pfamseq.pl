#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use DBI;

my ($host,$db, $user, $pass) = ("a48", "pfam27", "web_user", "fasta_www");

my $dbh = DBI->connect(qq{dbi:mysql:database=$db;host=$host},
		       $user,
		       $pass
		      ) or die $DBI::errstr;

## get total query count grouped by auto_pfamA
my $st_get_seq_doms_clan = $dbh->prepare(<<EOSQL);

SELECT  auto_pfamA_reg_full, auto_pfamA, pfamA_acc, seq_start, seq_end, length, model_start, model_end, model_length, auto_clan, domain_evalue_score
FROM    pfamA_reg_full_significant
JOIN    pfamseq USING(auto_pfamseq)
JOIN    pfamA USING(auto_pfamA)
LEFT JOIN clan_membership using(auto_pfamA)
WHERE   pfamseq_acc = ?
 AND    in_full=1
ORDER BY seq_start

EOSQL

my @fields = qw(auto_reg_full a_pfamA pfA_acc s_start s_end s_len m_start m_end m_len a_clan evalue);

print join("\t",("acc", @fields)),"\n";

while (my $acc = shift(@ARGV) ) {
  chomp $acc;

  if ($acc =~ m/^(sp|tr)\|([A-Z][A-Z0-9]{5})\|/i) {
    $acc = $2;
  }
  elsif ($acc =~ m/^gi\|\d+\|/) {
      my @fields = split(/\|/,$acc);
      $acc = $fields[3];
  }

  $st_get_seq_doms_clan->execute($acc);

  while (my @pf_data = $st_get_seq_doms_clan->fetchrow_array()) {
    $pf_data[-2] = 0 unless ($pf_data[-2]);
    print join("\t",($acc, @pf_data)),"\n";
  }
}
