#!/usr/bin/perl -w

use IPC::Run;

my ($pssm, $buf);

open(IN, "<$ARGV[0]") || die "Cannot open $ARGV[0]";

while (read(IN,$buf,2048)) { $pssm .= $buf;}

print pssm2bz($pssm);

exit(0);

# pssm2bz($pssm) returns encoded_bz_pssm
#
sub pssm2bz {
  my $pssm = shift;
  my ($bz_pssm, $enc_bz_pssm, $err);

  my @cmd_list = ('bzip2');

  IPC::Run::run \@cmd_list, \$pssm, \$bz_pssm, \$err,
      or carp("cannot run bzip -- $err " . (($?)>>8).":".($?&255) . "\n");

  my @bz_pssm_a = split(//,$bz_pssm);

  for (@bz_pssm_a) {
    push @enc_pssm_a, ord($_) >> 4;
    push @enc_pssm_a, ord($_)&15;
  }

  @enc_pssm_a = map { ($_ < 10) ? chr($_ + 48) : chr($_ + 55) } @enc_pssm_a;

  $enc_bz_pssm = join('',@enc_pssm_a);

  $enc_bz_pssm =~ s/(.{60})/$1\n/g;

  $enc_bz_pssm  = "PSSM:2\n" . $enc_bz_pssm . "\n";

  return $enc_bz_pssm;
}
