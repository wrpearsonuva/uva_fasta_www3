#!/usr/bin/perl -w

use IPC::Run qw(timeout);

## my $BL_BIN_DIR="/Users/wrp/bin/";
my $BL_BIN_DIR="/seqprg/bin/";
## my $BL_DATA_DIR="/Users/wrp/data/";
my $BL_DATA_DIR="/seqprg/data/";

my $BL_DB_DIR="/slib2/ncbi_bl_dbs";
my $BL_DB_NT_DIR="/slib2/ncbi_bl_dbs";

for ( @ARGV ) {
    print get_fastacmd('P', $_);
}

sub get_fastacmd {

  my ($db,$query) = @_;
  my $db_file;

  if ($db =~ m/P/i) {
      $db_file = "$BL_DB_DIR/nr";
      $db = "-pT";
  }
  else {
      # no nt fastacmd
      return "";
      $db_file = "$BL_DB_NT_DIR/nt";
      $db = "-pF";
  }

  $query =~ s/^\w+\|//;

  ($query) = ($query =~ m/(\w+)/);

  use vars qw($in $out $err);

  $in = "";

  ##  my @cmd_list = split(/\s+/,$BL_BIN_DIR."fastacmd -cT -d $db_file $db -tT -s $query");
  my @cmd_list = split(/\s+/,$BL_BIN_DIR."blastdbcmd -db $db_file -entry $query");

  IPC::Run::run \@cmd_list, \$in, \$out, \$err;

#   open (POS, $BL_BIN_DIR ."fastacmd -cT -d $db_file $db -tT -s $query |") || warn "Cannot open POS : $BL_DB_DIR/nr \n";

#  print STDERR join(' ',@cmd_list),"\n";

  if ($err) {
      print STDERR "fastacmd warning for query $query\n*** $err ***\n"; return "";
  }

  open(POS, '<', \$out) || return "";

  my $header = <POS>;
  my $line = "";

  return "" unless ($header);

  ## my @headers = split(/\001/,$header);
  my @headers = split(/\s>/,$header);

  my $my_head;
  for $my_head ( @headers ) {
      if ($my_head =~ m/$query/i) {
	  $header = $my_head;
#	  print STDERR "$query:\n$header\n";
	  last;
      }
  }

  if (! $my_head) {
      $header = $headers[0]
  }

  while (<POS>) {
    $line=$line . $_;
  }
  close(POS);

  return ">$header\n$line\n";

}
