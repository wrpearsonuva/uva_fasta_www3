
################################################################
# subroutines shared by FASTA_WWW.pm and CHAPS.pm to generate
# table-based pages
################################################################

use HTML::Entities;
use IPC::Run;

# uppercase hash keys are (almost) always TMPL_VAR names
# find them and load them (TITLE, RUN_MODE, OPTION1, OPTION2, SUBMIT)
#
sub load_form {
  my ($form_name, $tmpl) = @_;

  for my $field ( keys %{$form_list{$form_name}}  ) {
    next unless ($field eq uc($field));
    if ($tmpl->query('name' => $field)) {
      $tmpl->param($field => $form_list{$form_name}->{$field});
    }
  }
}

################################################################
# get_option() and get_neg_option() are used as part of an argument
# parsing strategy that takes a hash_ref of the form:
# 	 opts => {
# 	     eval => { cmd_arg => "-e", val=> \&get_safe_number},
# 	     comp_stat => { cmd_arg => "-C 1", val=> \&get_option, default_arg => "-C 0"},
# 	     seg_filter => { cmd_arg => "-F T", val=> \&get_option, default_arg => "-F F"},
# 	     p_lib => { cmd_arg => "-d", val=> \&get_blib},
# 	     gap => { cmd_arg => "-G", val=> \&get_safe_number},
# 	     ext => { cmd_arg => "-E", val=> \&get_safe_number},
# 	     smatrix => { cmd_arg => "", val=> \&get_bmatrix},
# 	 },
#
# and checks each $q->param(key).  If found, then val{cmd_arg} is added to
# the option string, based on the subsequent val{val}() code_ref. For If
# the code_ref is found, the function call is: code_ref->(val{cmd_arg},
# $q->param($opt), $q, $opt); get_option() and get_net_option() only
# use val{cmd_arg} and $q->param($opt) for options to be invoked, they must
# have name='option' value='1' or something
#
sub get_option {
  my ($opt, $p_arg) = @_;
  if ($p_arg) {
    return $opt;
  } else {
    return "";
  }
}

################
# for things that are on by default -- turn them off
# if the argument is not set or set to zero, then return the option
sub get_neg_option {
    my ($opt, $p_arg) = @_;
    if (!defined($p_arg) || !$p_arg) {return $opt;}
    else {return "";}
}

################
# get a safe number from $p_arg;
#
sub get_safe_number {
  my ($opt, $p_arg) = @_;

  unless (defined($p_arg)) {return "";}

  if ($p_arg =~ m/DEFAULT/i) {return "";}

  ($p_arg) = ($p_arg =~ m/([E\d\-\.]+)/i);
  unless (length($p_arg)>0) {return "";}

#  return "$opt $p_arg";
  if ($opt =~ m/%/) {
    return sprintf($opt,$p_arg);
  }
  elsif (length($opt)>0) {
    return "$opt $p_arg";
  }
  return $p_arg;
}

sub get_safe_string {
  my ($opt,$p_arg) = @_;

  unless ($p_arg) {return "";}

  $p_arg =~ s/[^$OK_CHARS]/_/go;
  ($p_arg) = ($p_arg =~ m/([$OK_CHARS]+)/);

  if ($opt =~ m/%/) {
    return sprintf($opt,$p_arg);
  }
  elsif (length($opt)>0) {
    return "$opt $p_arg";
  }
  return $p_arg;
}

sub get_string2file {
  my ($opt,$p_arg) = @_;

  unless ($p_arg) {return "";}

  my $str_fh = new File::Temp(DIR=>$TMP_DIR,
			      TEMPLATE => "FA_WWW_XXXXXX",
			      SUFFIX => ".str",
			      UNLINK => $DEF_UNLINK);
  my $str_filename = $str_fh->filename();
  chmod 0644, $str_filename;

  if ($p_arg =~ m/;/) {
    $p_arg =~ s/;/\n/g;
  }

  print $str_fh $p_arg."\n";
  close($str_fh);

  return sprintf($opt,$str_filename);
}

sub get_safe_filename {
  my ($q,$p_arg) = @_;

  unless ($q->param($p_arg)) {return "";}

  my $value=$q->param($p_arg);

  $value =~ s/[^$OK_CHARS]/_/go;

  ($value) = ($value =~ m/([$OK_CHARS]+)/);
  return $value;
}

sub get_safe_range {
  my ($opt, $p_arg) = @_;

  unless ($p_arg) {return "";}
  ($p_arg) = ($p_arg =~ m/(\d*\-?\d*)/);
  unless ($p_arg) {return "";}

  if ($opt) {return "$opt $p_arg";}
  else {return $p_arg;}
}

################
# get_file2file takes an uploaded file, copies it
# to a temporary file, and returns its
# uploaded name as an argument
#
# $opt -- command line option returned
# $p_arg  -- $q->param($arg)
# $q -- CGI query
# $arg -- parameter name
sub get_file2file {
  my ($opt, $p_arg, $q, $arg) = @_;

  # check to see if filename is available
  unless ($p_arg) {
    return "";
#    if (defined($opt) && $opt) {carp("p_arg - missing: $opt");}
#    else {carp("p_arg - missing");}
  }

  my $qfh = $q->upload($arg);

  if (!$qfh) {
    print STDERR "File upload failure: $p_arg\n";
    if ($q->cgi_error) {print STDERR $q->cgi_error();}
    return "";
  }

################
# capable of decoding PSSM:2
#
  my $buffer;
  my $data = '';
  while (read($qfh,$buffer,2048)) {$data .= $buffer;}
  close($qfh);

  if ($data =~ m/^.*\n*PSSM:2\n/s) {
      $data = bz2pssm($data);
  }

# create a temporary file
  my $tmp_fh = new File::Temp(DIR=>$TMP_DIR,
			      TEMPLATE => "FA_WWW_XXXXXX",
			      SUFFIX => ".asn1",
			      UNLINK => $DEF_UNLINK);
  chmod 0644, $tmp_fh->filename();

  print $tmp_fh $data;
  close($tmp_fh);
  push @tmp_fh_list, \$tmp_fh;

  return sprintf($opt, $tmp_fh->filename());
}

################
# get_local_file takes an uploaded file, copies it
# to a temporary file, and returns its
# uploaded name as an argument
#
# $opt -- command line option returned
# $p_arg  -- $q->param($arg)
# $q -- CGI query
# $arg -- parameter name
sub get_local_file {
  my ($opt, $p_arg, $q, $arg) = @_;

  # check to see if filename is available
  unless ($p_arg) {
    return "";
#    if (defined($opt) && $opt) {carp("p_arg - missing: $opt");}
#    else {carp("p_arg - missing");}
  }

  if (-e "$TMP_DIR/$p_arg") {
    return sprintf($opt, "$TMP_DIR/$p_arg");
  }
  else {
    return "";
  }
}

################
# get_pssm2file takes an uploaded file, copies it to a temporary file,
# converts it from ASN.1 text to binary if necessary, and returns
# uploaded name as an argument
#
# $opt -- command line option returned
# $p_arg  -- $q->param($arg)
# $q -- CGI query
# $arg -- parameter name
#
sub get_pssm2file {
  my ($opt, $p_arg, $q, $arg) = @_;
  my $do_asntxt2bin = 0;

  # check to see if filename is available
  unless ($p_arg) {
#    print STDERR " ** get_pssm2file : p_arg - missing: $opt\n";
    return "";
  }

  my $qfh = $q->upload($arg);

  if (!$qfh) {
    print STDERR "File upload failure: $p_arg\n";
    if ($q->cgi_error) {print STDERR $q->cgi_error();}
    return "";
  }

################
# capable of decoding PSSM:2
#
  my $buffer;
  my $data = '';
  while (read($qfh,$buffer,2048)) {$data .= $buffer;}
  close($qfh);

  if ($data =~ m/^.*\n*PSSM:2\n/s) {
      $data = bz2pssm($data);
  }
  elsif ($data =~ m/^PssmWithParameters/) {
    $do_asntxt2bin = 1;
  }

# create a temporary file
  my $asn_fh = new File::Temp(DIR=>$TMP_DIR,
					       TEMPLATE => "FA_WWW_XXXXXX",
					       SUFFIX => ".asn1",
					       UNLINK => $DEF_UNLINK);
  my $asn_filename = $asn_fh->filename();
  chmod 0644, $asn_filename;

  print $asn_fh $data;
  close($asn_fh);

  if ($do_asntxt2bin) {
    my $asn_bin_filename = $asn_filename;
    $asn_bin_filename .= ".bin";
#    Do_log("nohost","$BL_BIN_DIR/asntool -m $BL_DATA_DIR/asn.all -v $asn_filename -e $asn_bin_filename");
    system("$BL_BIN_DIR/asntool -m $BL_DATA_DIR/asn.all -v $asn_filename -e $asn_bin_filename");
    unless (-e $asn_bin_filename) {
      carp(" get_pssm2file : did not create $asn_bin_filename\n");
      return "";
    }
    unlink($asn_filename);
    $asn_filename = $asn_bin_filename;
    push @tmp_fh_list, $asn_bin_filename;
  }
  else {
    push @tmp_fh_list, \$tmp_fh;
  }

  return sprintf($opt, $asn_filename);
}

# modified 2/26/2007 to use HTML::Entities::encode to protect against XSS
#
sub fasta_error {

    my $msg = shift;

    return "<p /><hr /><p /><h2>". HTML::Entities::encode($msg) ." </h2><p /><hr /><p /></body></html>\n";
}

sub get_fastacmd {

  my ($db,$query) = @_;
  my ($db_file, $db_type, $db_suff);
  use vars qw($in $out $err);	# used for IPC::Run


  if (length($query) > 100) {
      return $query;
  }

  if ($db =~ m/P/i) {
      ## $db_file = "$BL_DB_DIR/nr";
      $db_file = "$UP_DB_DIR/uniprot_sprot";
      $db = "-pT";
      $db_type = 'prot';
      $db_suff = '.pin'
  }
  else {
      # no nt fastacmd
      return "";
      $db_file = "$BL_DB_NT_DIR/nt";
      $db = "-pF";
      $db_type = 'nucleotide';
      $db_suff = '.nin'
  }

  unless (-e $db_file.$db_suff) {
    return "";
  }

  $query =~ s/^\w+\|//;

  ($query) = ($query =~ m/(\w+)/);

  # check for PDB entry
  if ( !($query =~  m/^\d+$/ || $query =~ m/[A-Z][A-Z0-9]{6}/i || $query =~ m/_/ || $query =~ m/[A-Z][A-Z0-9]{10}/i)
       && $query =~ m/^(\d[A-Z0-9]{3})([A-Z])/i) {
      $query = "pdb|$1|$2";
  }

  use vars qw($in $out $err);

  $in = "";


#   my @cmd_list = split(/\s+/,"$BL_BIN_DIR/fastacmd -cT -d $db_file $db -tT -s $query");
  my @cmd_list = split(/\s+/,"$BL_BIN_DIR/blastdbcmd -db $db_file -entry $query");

#  print STDERR join(' ',@cmd_list),"\n";

  IPC::Run::run \@cmd_list, \$in, \$out, \$err; # timeout(240)

##  if ($err) {
##      print STDERR "fastacmd warning for query $query\n*** $err ***\n"; return "";
##  }

  open(POS, '<', \$out) || return "";	# get output from fastacmd

  my $header = <POS>;
  my $line = "";

  return "" unless ($header);

  ##  my @headers = split(/\001/,$header);
  my @headers = split(/ >/,$header);

  my $my_head;
  for $my_head ( @headers ) {
      if ($my_head =~ m/$query/i) {
	  $header = $my_head;
#	  print STDERR "$query:\n$header\n";
	  last;
      }
  }

  if (! $my_head && defined($headers[0])) {
      $header = $headers[0]
  }
  else {
      return "";
  }

  if ($header =~ m/gi\|\d+\|/) {
      $header =~ s/gi\|\d+\|//;
  }
  if ($header =~ m/[sp|tr|ref|up]\|/) {
# remove version
      $header =~ s/([A-Z]\w+)\.\d+/$1/;
##      $header =~ s/RecName: \w+=//g;
##      $header =~ s/AltName: \w+=//g;
##      $header =~ s/Short=/ /g;
  }


  while (<POS>) {
    $line=$line . $_;
  }
  close(POS);

  if ($header !~ m/^>/) {
    $header = '>' . $header;
  }

  return "$header\n$line";
}

sub get_protein {
  my ($db, $acc) = @_;

  return scalar(join('',`$BIN_DIR/get_protein.py \'$acc\'`));
}

sub get_ncbi {
    my ($db,$seq_in) = @_;
    use vars qw( $url $entry_line $parse );

    my $eutil_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/";

    $seq_in =~ s/gi\|//;

    if ($db =~ m/^P/i) {$db="Protein";}
    else {$db = "nuccore";}

#    print "<pre>seq_in: $seq_in\ndb: $db\n</pre>\n";

    if ($seq_in =~ m/^\d+$/) {
        $url= $eutil_url. "efetch.fcgi?db=$db&rettype=fasta&retmode=text&id=$seq_in";
        return get($url);
    }
    else {      # not gi, do a search first -
	$seq_in =~ s/\s+/+/g;
        $url="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=$db&usehistory=y&term=$seq_in";
        my $esearch_result = get($url);

#	print STDERR $esearch_result;

	my ($count, $querykey, $webenv) = (0, 0, '');
	if (defined($esearch_result) && $esearch_result) {
	  ($count, $querykey, $webenv) = ($esearch_result =~
					  m|<Count>(\d+)</Count>.*<QueryKey>(\d+)</QueryKey>.*<WebEnv>(\S+)</WebEnv>|s);
	}

#	print STDERR "get_ncbi.nlm ::".$seq_in."::$count\n";
#	print STDERR "Count: $count - QueryKey: $querykey - WebEnv: $webenv\n";

	if ($count < 1 || $count !~ m/^[0-9]+$/) { return "";}

	my $efetch = "";
	my $retstart;
	my $retmax=100;

	for($retstart = 0; $retstart < $count; $retstart += $retmax) {
	    $url = $eutil_url . "efetch.fcgi?"
               . "rettype=fasta&retmode=text&"
	       . "retstart=$retstart&retmax=$retmax&"
               . "db=$db&query_key=$querykey&WebEnv=$webenv";

	    my $this_fetch = get($url);
	    if ($this_fetch) {
	      $efetch .= $this_fetch;
	    }
	    else {
	      print STDERR "get(url) empty count: $count restart:$restart url: $url\n";
	    }
	}
#	print STDERR $efetch;
	if ($efetch =~ m/\|sp\|/) {
	  $efetch =~ s/RecName: \w+=//g;
	  $efetch =~ s/AltName: \w+=//g;
	  $efetch =~ s/Short=/ /g;
	}
	return $efetch if ($efetch =~ m/$seq_in/);
	return "";
    }
}

sub get_uniprot {
    my ($db, $seq_in) = @_;

    use vars qw( $url $sequence );

    if ($seq_in =~ m/^gi\|/) {
      my ($tmp, $gi, $sdb, $acc, $id) = split(/\|/,$seq_in);
      $seq_in = $acc;
    }
    elsif ($seq_in =~ s/^(tr|sp|up)\|//i) {
      my ($sdb, $acc,$id) = split(/\|/,$seq_in);
      $seq_in = $acc;
    }

    unless ($db =~ m/^P/i) {return "";}

    if ($seq_in =~ m/^(TR|SP):/) {
	$seq_in =~ s/^(TR|SP)://;
    }

    $url="https://www.uniprot.org/uniprot/$seq_in".".fasta";

    ## $sequence = get $url;
    ## $sequence = "" if ($sequence =~ m/404/);

    ## get_protein.py replaces get $url because perl urllib follows redirects
    $sequence = `get_protein.py \'$seq_in\'`;

    return $sequence;
}

# replaced 1-Nov-2006 with valid eutils calls
#
sub get_ncbi_old {

    my ($db,$seq_in) = @_;
    use vars qw( $url $entry_line $parse );

    $seq_in =~ s/gi\|//;

    if ($db =~ m/^P/i) {$db="Protein";}
    else {$db = "Nucleotide";}

#    print "<pre>seq_in: $seq_in\ndb: $db\n</pre>\n";


    if ($seq_in =~ m/^\d+$/) {
        $url="https://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=$db&cmd=Text&dopt=FASTA&uid=$seq_in";
        $entry_line = get $url;
        $parse = 0;
    }
    else {      # not gi, look for accession
        $url="https://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=$db&cmd=Search&doptcmdl=FASTA&term=$seq_in";
        $entry_line = get $url;
        $parse = 1;
    }

#    print $entry_line;
#    print "\n================\n";

    if (!$entry_line || $entry_line eq "" ||
        $entry_line =~/ No Documents Found /i ||
        $entry_line =~/temporarily unavailable/i) {

	$seq_in = "";
	return $seq_in;
    }

    if ($parse) {
        ($seq_in) = $entry_line =~ m/<pre>(.+?)<\/pre>/s;
        $seq_in =~ s/^.*>gi\|/>gi\|/;
    }
    else { $seq_in = $entry_line;}

    return $seq_in;
}

sub gp2fasta {
    my @entry = @_;

    my $locus = '';
    my $acc = '';
    my $gi = '';
    my $def = '';

    while ($_ = shift @entry) {
        if (!$locus && /^LOCUS/) {($locus) = /^LOCUS\s+(\w+)\s/;}
        elsif (!$def && /^DEFINITION/) {($def) = /^DEFINITION  (.+)$/;}
        elsif (!$acc && /^ACCESSION/) {($acc) = /^ACCESSION\s+(\w+)/;}
        elsif (!$gi && /^PID/) { ($gi) = /^PID\s+g(\d+)/; last;}
    };

    do {
        $_ = shift @entry;
    } until (/^ORIGIN/);

    my $seq = '';
    while ($_ = shift @entry) {
        if ($_ eq '//') {last;}
        $seq = $seq . substr($_,10,65);
    }
    $seq =~ s/\s+//g;
    $seq =~ s/(.{60})/$1\n/g;
    my $gp2fasta = ">gi|".$gi.'|db|'.$acc.'|'.$locus.' '.$def."\n";
    $gp2fasta = $gp2fasta . $seq;
    return $gp2fasta;
}

################################################################
# process a hash of input arguments that looks like:
# inputs => {
#   query => {SEARCH_QUERY => "this", SEARCH_FRM_ACC => "selected",
#             SEARCH_RANGE => &get_search_range},
#  query2 => {SEARCH_QUERY2 => "this", SEARCH_FRM_ACC2 => "selected"}
# }
################################################################
#
sub load_inputs {
  my ($form_href, $tmpl, $q) = @_;

# first deal with dependencies:
#
#   inp_dep_list => [qw(mquery query)]
# and:
#   inp_dep => {mquery => [mquery, \&clean_mquery],
#                query => [mquery, \&query_from_mquery]
#              }
# we look at the list of desired inputs and see if the inputs can be
# produced from other inputs
#
  for my $req_inp ( @{$form_href->{inp_dep_list}} ) {
  # can we resolve the dependency?
    if (exists $form_href->{inp_deps}->{$req_inp}) {
  # get the [name,\&function()] list
      my $req_inp_l = $form_href->{inp_deps}->{$req_inp};
  # if the names are the same, then do it, even if the argument is defined.
      if ($req_inp eq $req_inp_l->[0] )	{
	if (defined $q->param($req_inp_l->[0])) {
	  $q->param($req_inp,$req_inp_l->[1](scalar($q->param($req_inp_l->[0]))));
	}
      }
  # otherwise, only do it if the parameter has not been defined
      else {
	if (! defined($q->param($req_inp)) &&
	    defined $q->param($req_inp_l->[0])) {
	  $q->param($req_inp, $req_inp_l->[1](scalar($q->param($req_inp_l->[0]))));
	}
      }
    }
  }

#      "inputs" sets template vars in form from input parameters
#      inputs => { arg1 => {TMP_VAR1 => value, TMP_VAR2 => \&value_func, ...},
#
  my $input_href = $form_href->{inputs};

#    keys %$input_href are often "query", "query2", but also include
#    "remote", "msa_query", "hmm_query"
#
  for my $query ( keys %{$input_href} ) {   # query value from $q->param()
    if (scalar($q->param($query))) {
	load_vars($input_href->{$query}, $tmpl, $q, $query);
    }
  }
}

sub mod_vars {
  my ($out_href, $q) = @_;

  if (defined($q->param("hide_align")) && $q->param("hide_align")) {
      if ($out_href->{OPTION3} =~ m/"hide_align"/s) {
	  $out_href->{OPTION3} =~ s/"hide_align"/"hide_align" checked/s;
      }
  }
}
################################################################
# load_vars() is called in two places, once as
#
# load_vars($form_href->{outputs}, $tmpl);
# where $href->{outputs} looks like:
#     { SUBMIT => 'Compare Sequences',
#      Q2_FILE_UP => 1,
#      SSR_FLAG => '1',
#      ...
#
# and once as:
#  for my $query ( keys %{$input_href} ) {   # query value from $q->param()
#    if ($q->param($query)) {load_vars($input_href->{$query}, $tmpl, $q, $query);}
#  }
#  where %$input_href looks like:
#     inputs =>
#    { query => {SEARCH_QUERY => "this", SEARCH_FRM_ACC => "selected",
#		SSR => \&get_query_range},
#      query2 => {SEARCH_QUERY2 => "this", SEARCH_FRM_ACC2 => "selected"}
#    },
#
################################################################
# In the former case (2 args), we just need to map TMPL_VARs to text
# strings. In the latter case (4 args), we are getting information
# from CGI parameters ($q) and possibly validating input or doing
# other transformations before setting the TMPL_VAR
#
################################################################
# take a hash_ref of the form:
#  outputs =>
#   { TITLE => qq(Misc. Protein Analysis)}
#  and fill in the TMPL_VAR (key, TITLE) with the value
#

sub load_vars {
  my ($input_href, $tmpl, $q, $query) = @_;

  for my $tmpl_var ( keys %{$input_href} ) { # keys are TMPL_VAR's

    my $value = $input_href->{$tmpl_var};    # get the TMPL_VAR name from the list

    unless ($value) {
      warn "Missing value for $tmpl_var";
      next;
    }

    if ($tmpl->query('name' => $tmpl_var)) { # check that it's in the template

      # if the value of TMPL_VAR is a function, execute it and set the variable
      if (ref($value) && ref($value) eq 'CODE' ) {
	$tmpl->param($tmpl_var => $value->($q,lc($tmpl_var)));
      }

      # otherwise if it is 'this', set it safely from an input parameter
      elsif ($value eq 'this' && $query && ref($q) eq 'CGI') {
	# some protection from XSS
	my $u_query = $q->param($query);
	$tmpl->param($tmpl_var => HTML::Entities::encode($u_query));
      }

      # otherwise (simplest case) just assign the $value to TMPL_VAR
      else {
	$tmpl->param($tmpl_var => $value);
      }
    }
  }
}

sub get_node_host {
  my $n_host = "";
  my @node_hosts = @NODE_HOSTS;
  my $node_ext = $NODE_EXT;

  if (-e $NODE_STATUS_FILE) {
    my @node_list = ();
    open(FH, $NODE_STATUS_FILE) || goto random;
    while (my $node_line = <FH>) {
      chomp $node_line;
      my %node_entry;
      @node_entry{('host', 'load')}= split(/:/,$node_line);
      push @node_list, \%node_entry;
    }
    close(FH);
    goto random unless (@node_list);
    @node_list = sort { $a->{load} <=> $b->{load} } @node_list;
    @node_hosts = map { $_->{host} } @node_list[0 .. scalar(@node_list)+1/2];
    $node_ext = "";
  }
# get it randomly
  random:
    $n_host = $node_hosts[int rand scalar @node_hosts];
# fill out full ip address
    $n_host .= $node_ext;

  return $n_host;
}

sub check_bad_query {
    my ($query) = @_;

    return "" if ($query =~ m%<a\s+href\s*=\s*"http://%i);
    return "" if ($query =~ m/\.pen\.io"/i || $query =~ m/purchaseonline/i );
#    return "" if () ($query = () =~ m/\+/gi) > 10);
#    my @bad_match_array = ($query =~ m/\+/gi);   # breaks Na(+) in description
#    return if (scalar(@bad_match_array));

    return $query;
}

1;
