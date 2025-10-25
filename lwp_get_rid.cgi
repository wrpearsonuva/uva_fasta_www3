#!/usr/bin/perl -w

#  lwp_get_rid.cgi - get a PSSM given and RID
#

use strict;

use CGI;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use IPC::Run;

my $q = new CGI;

my $file = $q->param('RID');
my $output = "";

unless ($file) {
    print STDERR "*** no \'RID\' parameter ***\n\n";
    exit(0);
}

my %r_args = 
  (
   "CMD" => "Get",
   "FORMAT_OBJECT"=> "PSSM",
   "FORMAT_TYPE" => "Text",
  );

  $r_args{'RID'} = $q->param('RID');

  my $ua = LWP::UserAgent->new;
  $ua->agent("$0");
  $ua->from('wrp@virginia.edu');

  my $n_uri = "http://www.ncbi.nlm.nih.gov/blast/Blast.cgi";

  my $req = POST $n_uri, \%r_args;
  my $res = $ua->request($req);

  if ($res->is_success) {
      my $enc_bz_pssm .= $res->content;
      
#      open(BZ, "> pssm.txt");
#      print BZ $enc_bz_pssm;
#      close BZ;

      $enc_bz_pssm  =~ s/^.*\n*PSSM:2\n//os;

      $enc_bz_pssm =~ s/[\r\n]//ogs;

      $enc_bz_pssm =~s/[^A-F0-9]//g;

      my $bz_pssm = '';

      while ( $enc_bz_pssm=~/(..)/g ) {
	$bz_pssm .= chr(hex($1));
      }

#      open(BZ, "> pssm.bz2");
#      print BZ $bz_pssm;
#      close BZ;

      my @cmd_list = ('/usr/bin/bunzip2');
      my ($pssm, $err);

      IPC::Run::run \@cmd_list, \$bz_pssm, \$output, \$err,
	  or warn("cannot run buzip -- " . (($?)>>8).":".($?&255) . "\n");

  } else {
      $output .=  $res->error_as_HTML;
  }

print $output;

exit(0);

