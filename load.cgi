#!/usr/bin/perl -Tw

use strict;
use CGI;

$ENV{PATH} = "/usr/bin";

my $q = new CGI;

my $c_host = $q->server_name || `/bin/hostname`;
chomp $c_host;

print "Content-type: text/plain\n\n";

my $w_string = `/usr/bin/w`;
for my $line ( split(/\n/,$w_string)) {
  chomp $line;
  if ($line && ($line =~ m/load average.*:/)) {
    my @lline = split(/,*\s+/,$line);
    print "$c_host:$lline[-3]\n";
    last;
  }
}
exit(0);
