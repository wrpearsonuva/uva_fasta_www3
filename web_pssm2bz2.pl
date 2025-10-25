#!/usr/bin/perl -w

no encoding;
use IPC::Run;

my $enc_bz_pssm = '';
      
while (<>) {$enc_bz_pssm .= $_;}

$enc_bz_pssm  =~ s/^.*\n?PSSM:2\n//os;

# $enc_bz_pssm =~ s/^PSSM:2$//;

$enc_bz_pssm =~ s/[\r\n]//ogs;

$enc_bz_pssm =~s/[^A-F0-9]//g;

my $bz_pssm = '';

while ( $enc_bz_pssm =~ m/(..)/g ) {
    $bz_pssm .= chr(hex($1));
}

open (BZ, ">pssm.bz2");
print BZ $bz_pssm;
close(BZ);


my @cmd_list = ('bunzip2');
my ($pssm, $err);

IPC::Run::run \@cmd_list, \$bz_pssm, \$pssm, \$err,
    or cluck("cannot run bunzip -- " . (($?)>>8).":".($?&255) . "\n");

print $pssm;

