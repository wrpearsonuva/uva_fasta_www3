#!/usr/bin/perl -w

# ann_feats2.pl gets an annotation file from fasta36 -V with a line of the form:

# gi|62822551|sp|P00502|GSTA1_RAT Glutathione S-transfer\n  (at least from pir1.lseg)
#
# it must:
# (1) read in the line
# (2) parse it to get the up_acc
# (3) return the tab delimited features
#

# this version can read feature2 uniprot features (acc/pos/end/label/value), but returns sorted start/end domains

use strict;

use DBI;
use Getopt::Long;
use Pod::Usage;

use vars qw($host $db $port $user $pass);

my %domains = ();
my $domain_cnt = 0;

my $hostname = `hostname`;

unless ($hostname =~ m/ebi/) {
  ($host, $db, $port, $user, $pass)  = ("a48", "uniprot", 0, "web_user", "fasta_www");
}
else {
  ($host, $db, $port, $user, $pass)  = ("mysql-pearson", "up_db", 4124, "web_user", "fasta_www");
}

my ($lav, $neg_doms, $no_doms, $no_feats, $shelp, $help, $ipr) = (0,0,0,0,0,0,0,0);

my %annot_types = ();
my @dom_keys = qw( DOMAIN REPEAT );
my @dom_vals = ( [ '[', ']'],[ '[', ']']);

GetOptions(
    "host=s" => \$host,
    "db=s" => \$db,
    "user=s" => \$user,
    "password=s" => \$pass,
    "port=i" => \$port,
    "lav" => \$lav,
    "no_doms" => \$no_doms,
    "no-doms" => \$no_doms,
    "nodoms" => \$no_doms,
    "neg" => \$neg_doms,
    "neg_doms" => \$neg_doms,
    "neg-doms" => \$neg_doms,
    "negdoms" => \$neg_doms,
    "no_feats" => \$no_feats,
    "no-feats" => \$no_feats,
    "nofeats" => \$no_feats,
    "ipr" => \$ipr,
    "h|?" => \$shelp,
    "help" => \$help,
    );

pod2usage(1) if $shelp;
pod2usage(exitstatus => 0, verbose => 2) if $help;
pod2usage(1) unless @ARGV;

my $connect = "dbi:MariaDB(AutoCommit=>1,RaiseError=>1):database=$db";
$connect .= ";host=$host" if $host;
$connect .= ";port=$port" if $port;

my $dbh = DBI->connect($connect,
		       $user,
		       $pass
		      ) or die $DBI::errstr;

my $get_annot_sub = \&get_fasta_annots;
if ($lav) {
  $no_feats = 1;
  $get_annot_sub = \&get_lav_annots;
  @annot_types{@dom_keys} = @dom_vals unless ($no_doms);
}

if ($neg_doms) {
  $domains{'NODOM'}=0;
}

my $get_annots_id = $dbh->prepare('select acc, start, stop, ipr_acc, s_descr, len from prot2ipr_s join annot2 using(acc) join ipr_annot using(ipr_acc) where id=? order by start');
my $get_annots_acc = $dbh->prepare('select acc, start, stop, ipr_acc, s_descr, len from prot2ipr_s join annot2 using(acc) join ipr_annot using(ipr_acc) where acc=? order by start');

my $get_annots_sql = $get_annots_id;

my ($tmp, $gi, $sdb, $acc, $id, $use_acc);

# get the query
my $query = shift @ARGV;

$query =~ s/^>//;

my $ANN_F;

my @annots = ();

#if it's a file I can open, read and parse it
if ($query !~ m/\|/ && open($ANN_F, $query)) {

  while (my $a_line = <$ANN_F>) {
    $a_line =~ s/^>//;
    chomp $a_line;
    push @annots, show_annots($a_line, $get_annot_sub);
  }
}
else {
  push @annots, show_annots($query, $get_annot_sub);
}

for my $seq_annot (@annots) {
  print ">",$seq_annot->{seq_info},"\n";
  for my $annot (@{$seq_annot->{list}}) {
    if (!$lav && defined($domains{$annot->[4]})) {
      $annot->[-2] .= " :".$domains{$annot->[4]};
    }
    print join("\t",@$annot[0 .. 3]),"\n";
  }
}

exit(0);

sub show_annots {
  my ($annot_line, $get_annot_sub) = @_;

  my %annot_data = (seq_info=>$annot_line);

  if ($annot_line =~ m/^gi\|/) {
    $use_acc = 1;
    ($tmp, $gi, $sdb, $acc, $id) = split(/\|/,$annot_line);
  }
  elsif ($annot_line =~ m/SP:(\w+)/) {
    $use_acc = 0;
    $sdb = 'sp';;
    $id = $1;
  }
  elsif ($annot_line =~ m/TR:(\w+)/) {
    $use_acc = 0;
    $sdb = 'tr';
    $id = $1;
  }
  else {
    $use_acc = 1;
    ($sdb, $acc, $id) = split(/\|/,$annot_line);
  }

  # remove version number
  unless ($use_acc) {
    $get_annots_sql = $get_annots_id;
    $get_annots_sql->execute($id);
  }
  else {
    $get_annots_sql = $get_annots_acc;
    $acc =~ s/\.\d+$//;
    $get_annots_sql->execute($acc);
  }

  $annot_data{list} = $get_annot_sub->(\%annot_types, $get_annots_sql);

  return \%annot_data;
}

sub get_fasta_annots {
  my ($annot_types, $get_annots_sql) = @_;

  my ($acc, $pos, $end, $value, $ipr_acc, $s_descr, $comment, $len, $seq_len);

  $seq_len = 0;

  my @feats2 = ();	# features with start/stop, for checking overlap, adding negative

  while (($acc, $pos, $end, $ipr_acc, $s_descr, $len) = $get_annots_sql->fetchrow_array()) {
    $seq_len = $len unless ($seq_len);

    $value = domain_name($ipr_acc,$s_descr);
    if ($ipr) {$value = $ipr_acc;}

    push @feats2, [$pos, "-", $end, $value, $ipr_acc];
  }

  # ensure that domains do not overlap
  for (my $i=1; $i < scalar(@feats2); $i++) {
    my $diff = $feats2[$i-1]->[2] - $feats2[$i]->[0];
    if ($diff >= 0) {
      $feats2[$i-1]->[2] = $feats2[$i]->[0]+ int($diff/2);
      $feats2[$i]->[0] = $feats2[$i-1]->[2] + 1;
    }
  }

  my @n_feats2 = ();
  my @feats = ();

  if ($neg_doms && scalar(@feats2)) {
    my $last_end = 0;
    for my $feat ( @feats2 ) {
      if ($feat->[0] - $last_end > 10) {
	push @n_feats2, [$last_end+1, "-", $feat->[0]-1, "NODOM", "NODOM"];
      }
      $last_end = $feat->[2];
    }
    if ($seq_len - $last_end > 10) {
      push @n_feats2, [$last_end+1, "-", $seq_len, "NODOM", "NODOM"];
    }
  }

  for my $feat (@feats2, @n_feats2) {
    push @feats, [$feat->[0], '[', '-', $feat->[-2], $feat->[-1] ];
    push @feats, [$feat->[2], ']', '-', "", ""];
  }

  @feats = sort { $a->[0] <=> $b->[0] } (@feats);

  return \@feats;
}

sub get_lav_annots {
  my ($annot_types, $get_annots_sql) = @_;

  my ($pos, $end, $label, $value, $comment);

  my @feats = ();

  my %annot = ();
  while (($acc, $pos, $end, $label, $value) = $get_annots_sql->fetchrow_array()) {
    next unless ($label =~ m/^DOMAIN/ || $label =~ m/^REPEAT/);
    push @feats, [$pos, $end, $value];
  }

  return \@feats;
}

# domain name takes a uniprot domain label, removes comments ( ;
# truncated) and numbers and returns a canonical form. Thus:
# Cortactin 6.
# Cortactin 7; truncated.
# becomes "Cortactin"
#

sub domain_name {

  my ($ipr_acc, $s_descr) = @_;

  $s_descr =~ s/[\-_]domain//;
  $s_descr =~ s/[\-_]homology//;

  $s_descr =~ s/^(.{20})/$1/;

  if (!defined($domains{$ipr_acc})) {
      $domain_cnt++;
      $domains{$ipr_acc} = $domain_cnt;
  }
  return $s_descr;
}



__END__

=pod

=head1 NAME

ann_feats2.pl

=head1 SYNOPSIS

 ann_feats2.pl --no_doms --no_feats --lav 'sp|P09488|GSTM1_NUMAN' | accession.file

=head1 OPTIONS

 -h	short help
 --help include description
 --no-doms  do not show domain boundaries (domains are always shown with --lav)
 --no-feats do not show feature (variants, active sites, phospho-sites)
 --lav  produce lav2plt.pl annotation format, only show domains/repeats

 --host, --user, --password, --port --db -- info for mysql database

=head1 DESCRIPTION

C<ann_feats2.pl> extracts feature, domain, and repeat information from
a msyql database (default name, uniprot) built by parsing the
uniprot_sprot.dat and uniprot_trembl.dat feature tables.  Given a
command line argument that contains a sequence accession (P09488) or
identifier (GSTM1_HUMAN), the program looks up the features available
for that sequence and returns them in a tab-delimited format:

 >sp|P09488
 2	-	88	DOMAIN: GST N-terminal.
 7	V	F	Mutagen: Reduces catalytic activity 100- fold.
 23	*	-	MOD_RES: Phosphotyrosine (By similarity).
 33	*	-	MOD_RES: Phosphotyrosine (By similarity).
 34	*	-	MOD_RES: Phosphothreonine (By similarity).
 90	-	208	DOMAIN: GST C-terminal.
 108	V	S	Mutagen: Changes the properties of the enzyme toward some substrates.
 108	V	Q	Mutagen: Reduces catalytic activity by half.
 109	V	I	Mutagen: Reduces catalytic activity by half.
 116	#	-	BINDING: Substrate.
 116	V	A	Mutagen: Reduces catalytic activity 10-fold.
 116	V	F	Mutagen: Slight increase of catalytic activity.
 173	V	N	in allele GSTM1B; dbSNP:rs1065411.
 210	V	T	in dbSNP:rs449856.

If features are provided, then a legend of feature symbols is provided
as well:

 =*:phosphorylation
 ==:active site
 =@:site
 =^:binding
 =!:metal binding

If the C<--lav> option is specified, domain and repeat features are
presented in a different format for the C<lav2plt.pl> program:

  >sp|P09488|GSTM1_HUMAN
  2	88	GST N-terminal.
  90	208	GST C-terminal.

C<ann_feats2.pl> is designed to be used by the B<FASTA> programs with
the C<-V \!ann_feats2.pl> option.  It can also be used with the lav2plt.pl
program with the C<--xA "\!ann_feats2.pl --lav"> or C<--yA "\!ann_feats2.pl --lav"> options.

=head1 AUTHOR

William R. Pearson, wrp@virginia.edu

=cut
