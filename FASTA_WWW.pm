
# $Id: FASTA_WWW.pm 35 2009-10-28 18:29:25Z wrp $
# $Revision: 184 $

package FASTA_WWW; use base 'CGI::Application';

use CGI::Carp;
use CGI::Application::Plugin::Session;

use HTML::FillInForm;
use HTML::Entities;
use HTTP::Request::Common qw(GET POST);
use LWP::UserAgent;
use LWP::Simple;
use File::Temp ();
use IO::Scalar;
use URI::Escape;
use IPC::Run qw(timeout);
use Text::ParseWords;
use Data::Dumper;
use JSON;
use URI::Encode qw(uri_encode uri_decode);

use vars qw( $DEF_UNLINK $OK_CHARS $ALT_HOST_CGI $HOST_NAME $CGI_DIR $SQL_DB_HOST
	     $RUN_URL $SS_ALT_HOST_CGI $SS_HOST_NAME $SS_CGI_DIR  $DOMAIN_PLOT_URL
	     $SS_RUN_URL $BIN_DIR @NODE_HOSTS $NODE_EXT $NODE_RUN_CGI
	     $USE_REMOTE $DEBUG $FAST_LIBS $FAST_GNMS $TMP_DIR
	     $LOG_DIR $TMP_ROOT $GS_BIN $BL_BIN_DIR $BL_DB_DIR $UP_DB_DIR
	     $BL_DB_NT_DIR $BL_DATA_DIR $fa_footer $fa_footer_s $BACK_TIMEOUT $RUN_TIMEOUT
	     $HIDE_ALIGN $hide_checked $PFAM_FAM_URL $IPRO_FAM_URL);

use vars qw( $search_url_cgi $search_url1_cgi $domain_plot_url_cgi %res_opts);

require "./fawww_defs.pl";
require "./fawww_subs.pl";

# variables defined in fawww_pgms.pl
#
use vars qw( @pgm_fslist @pgm_flist @pgm_slist @pgm_hlist @pgm_blist @blp_list @pgm_psi2list
	     @pgm_mlist @pgm_shuff_list @pgm_lalign_list
             %form_list %run_list %pgm_dev %pgm_opt @annot_seq1_arr @annot_seq2_arr
	     %page_link_list %page_links $r_host $c_host );

# variables defined in fawww_libs.pl
#
use vars qw( @lib_p @lib_n @lib_pg @lib_ng );
use vars qw( %smatrix_vals %bmatrix_vals);
use vars qw( @pgm_pssmlist %pgm_pssm_br);

require "./fawww_libs.pl";
require "./fawww_pgms.pl";

use vars qw( @tmp_fh_list );

use strict;

sub cgiapp_init {
    my $self = shift;
    $self->session_config(CGI_SESSION_OPTIONS =>
			  [
			   "driver:File",
			   $self->query,
			   {Directory=>"$TMP_DIR/session" }
			  ],
			  COOKIE_PARAMS => { '-expiry' => '+48h'}
	)
}

sub setup {
  my $self = shift;

  $self->start_mode("select");
  $self->mode_param("rm");

# because the "form" pages all look so much alike, do_form() builds
# all of them, based on %form_list{}.  Likewise, all the executable
# run modes use %run_list{} and do_search()

# user entry forms available:
# select	=> select a database for a FASTA program search
# selectg	=> select genome database
# compare	=> compare two sequences
# shuffle	=> statistics from shuffle
# lalign	=> local sequence alignments
# misc1		=> analyze protein sequences (pkd, gor, cho, seg)
# blast 	=> submit a blast search

#
# the very simple code below works because do_form() can determine its
# run_mode from $self.  If this were not true, sub {closures} would be
# required.
#

# with this version, there is a new mode, 'result'.  For programs that
# have run_bkgd set, the do_search function produces a "waiting" page,
# which refreshes itself until a result is available, when it displays
# the result.

  $self->run_modes((map { $_ => \&do_form } keys %form_list),
		   (map { $_ => \&do_search } keys %run_list),
		   'wait' => \&wait_result,
		   'status' => \&status_result,
		   'retrieve' => \&retrieve_result,
		   'remote' =>  \&remote);

}

sub teardown {
    my $self = shift;
    # empty, for now.
}

sub do_form {
  my ($self) = shift @_;

  my $form_name = $self->get_current_runmode();

# check that we know the run mode as a display form
#

  unless ($form_name) {
    return fasta_error("Undefined RUN_MODE\n");
  }

  my $form_href = $form_list{$form_name};

  unless ($form_href) {
    return fasta_error("Form parameters undefined for $form_name\n");
  }

#  for right now, use session info for searches and status, not for
#  the initial search info.  Later, us to initialize things to last
#  search
#   my $session = $self->session();

# get the template
#
  my $tmpl = $self->load_tmpl($form_href->{tmpl});

  ($r_host, $c_host) = get_hosts($self);
  $tmpl->param( R_HOST => $r_host);
  $tmpl->param( C_HOST => $c_host);

  my $q = $self->query();

# the next three functions, which load the links to other programs,
# the other TMPL_VAR's specific to the form/runmode, and the libraries
# (if necessary), are not affected by input arguments.

# load up links to other programs at top of page
#
  load_links($form_name, $tmpl);

# load various other TMPL_VAR's for form
#
  mod_vars($form_href->{outputs}, $q);

  load_vars($form_href->{outputs}, $tmpl);

# load the selection of library names
#
  my $lib_sel = $q->param("lib_p") || $form_href->{lib_p_def};
  load_library($form_href, $tmpl, $lib_sel);

# the next functions change the form depending on input arguments
#
# load the list of program selection list
#
  my $pgm_sel = $q->param("pgm") || $form_href->{pgm_def};
  prog_list($q, $tmpl, $form_href->{pgm_ref}, $pgm_sel);

#
#
  load_inputs($form_href,$tmpl,$q);

# this seems a bit out of place, it could be done by load_form()
# and $RUN_URL is always fasta_www.cgi (though it could have a run-mode)
#

# these could  be changed for more sophisticated re-searching

  if ($ALT_HOST_CGI) {
    $search_url_cgi=$HOST_NAME . $CGI_DIR;
    $search_url1_cgi=$HOST_NAME . $CGI_DIR;
    $domain_plot_url_cgi=$HOST_NAME . $CGI_DIR;
  }
  else {
    $search_url_cgi= "";
    $search_url1_cgi= "";
    $domain_plot_url_cgi="";
  }

  $RUN_URL = $ENV{SCRIPT_NAME} unless($RUN_URL);

  if ($tmpl->query('name' => 'SEARCH_URL')) {
    $tmpl->param( SEARCH_URL => $RUN_URL);
  }

# get alternative search site
#
  if ($tmpl->query('name' => 'SSEARCH_URL')) {
    if ($SS_ALT_HOST_CGI) {
      $tmpl->param( SSEARCH_URL => $SS_HOST_NAME . "$SS_CGI_DIR/$SS_RUN_URL");
    }
    else {
      $tmpl->param( SSEARCH_URL => $RUN_URL);
    }
  }

  if ($q->param("DEBUG")) {
      $DEBUG = $q->param("DEBUG");
  }

  my $show_debug = $q->param("DEBUG") || $DEBUG;
  $tmpl->param(DEBUG => $show_debug);

  if ($form_href->{CAN_REMOTE} && $tmpl->query(name => "RUN_MODE")) {
    if ($q->param("remote") || $USE_REMOTE) {
      $tmpl->param( RUN_MODE => 'remote');
      $tmpl->param( SHOW_REMOTE => 1);
    }
    $tmpl->param( SHOW_REMOTE => 0);	# to enable SHOW_REMOTE, this must be changed
  }

  if ($show_debug) {
      my $cmd_line = "command args:\n";
      for my $p ($q->param()) {
	$cmd_line .= ( " $p=".$q->param($p));
      }
      return $self->dump_html() . "<hr />\n$cmd_line\n <hr />\n" . $tmpl->output();
  }
  else {return $tmpl->output();}
}

################################################################
# do_search manages executable run modes, search, searchg, compare_r,
# etc.  capabilities and options for the run modes are set by
# %run_list{} from fawww_pgms.pl
#
# In the previous version, do_search() does not use a template file,
# because it assumes that the program will generate its own output
# (and if it does not produce html, some <pre></pre> are put around
# the output.
#
# In the run_bkgd version, do_search() will use a template file for
# the background processing.  This page will provide the "running
# ...." or "searching ..." message with the name of the background
# file so that progress can be checked, and results displayed when
# things are done
#
################################################################

use vars qw($query $query_info $lib_abbr $lib_info $pgm $pgm_title);
use vars qw($query2 $q2_type $query_str2 $query_range2 $q2_file_name $lib_info);

sub do_search {

  my $self = shift;

  my $run_mode = $self->get_current_runmode;

  unless ($run_mode) {
    return fasta_error("Undefined RUN_MODE\n");
  }

# $run_href is the hash reference that describes all the parameters
# for this run/search mode, including 'pgm_ref' (list of programs),
# n_q (number of queries), query2_type, etc.
#
  my $run_href = $run_list{$run_mode};

  unless ($run_href) {
    return fasta_error("Run parameters undefined for $run_mode\n");
  }

# get the parameters submitted
#
  my $q = $self->query();

  my %run_data = ('rm'=>$run_mode);

  $run_data{"DEBUG"} = $DEBUG;

  if ($q->param("log_args")) {
      my @pnames = $q->param();
      my $pgm_args = "";
      for my $pname (@pnames) {
	$pgm_args .= "&".join("=",($pname, $q->param($pname)));
      }
      Do_log($r_host,$pgm_args);
  }

  my $raw_mode = 0;
  $raw_mode = $q->param('raw_mode') if (defined($q->param('raw_mode')));

#ensure no post-processing if from remote
#  $raw_mode = 1 if ($q->param('rem_rm') || $q->param('remote_host'));

# get session info for saving search information
#
  my $session = $self->session();

  # get the program specific mode
  if ($run_href->{indirect}) {
    unless ($q->param('pgm') &&
	    exists($run_href->{indirect}->{scalar($q->param('pgm'))})) {
	      return fasta_error("Indirect run parameters undefined for $run_mode\n");
	    }
    else {
      $run_mode = $run_href->{indirect}->{scalar($q->param('pgm'))};
      $run_href = $run_list{$run_mode};
    }
  }

  if ($run_href->{can_remote} && $q->param('remote')) {
      $q->param('rem_rm' => $run_mode);
      return remote($self);
  }
  else {
      $q->param('rem_rm' => '');
  }

#################################################################
# at this point, we are going to process the request
################################################################
  use vars qw($output $q2_tmp_name $err);

  my ($r_host, $c_host) = get_hosts($self);
  $run_data{pgm} = $pgm = $q->param("pgm");

  if ($ALT_HOST_CGI) {
    $search_url_cgi=$HOST_NAME . $CGI_DIR . $RUN_URL;
    $search_url1_cgi=$HOST_NAME . $CGI_DIR . $RUN_URL;
    $domain_plot_url_cgi=$HOST_NAME . $CGI_DIR . $DOMAIN_PLOT_URL;
  }
  else {
    $search_url_cgi= $RUN_URL;
    $search_url1_cgi= $RUN_URL;
    $domain_plot_url_cgi= $HOST_NAME . $CGI_DIR . $DOMAIN_PLOT_URL;
  }

# set default sq_type
  my $n_queries = $run_href->{n_q};
  if (exists $run_href->{sq_type}) {$q->param('sq_type',$run_href->{sq_type});}

# build list of valid program name arguments ($q->param("pgm"))
  my %pgm_name = map { $_->{pgm} => $_->{binary} } @{$run_href->{pgm_ref}};

# build list of program query/library database type matches
  my %pgm_qdb_ldb =
      map { $_->{pgm} => {q_sq => $_->{q_sq}, l_sq => $_->{l_sq}}} @{$run_href->{pgm_ref}};

#
# get program info
#
  if (!$pgm_name{$pgm}) {
    $output = fasta_error("program: $pgm not found");
    if ($DEBUG) {$output .= $self->dump_html();}
    return $output;
  }

  my %pgm_title = map { $_->{pgm} => $_->{title} } @{$run_href->{pgm_ref}};
  $pgm_title = $pgm_title{$pgm};

# get database types
  my ($query_db, $query2_db) = get_dbs($q,$pgm, $pgm_qdb_ldb{$pgm});

#  print STDERR "query_db/l_db: $query_db / $query2_db\n";

  my %f_opts = get_fasta_opts_byref($q, $run_href, "opts", \%run_data);

  my $fa_opts = "";
  if (values(%f_opts)) {
    $fa_opts = join(' ', values(%f_opts));
  }

  %res_opts = get_fa_results_byref($q, $run_href, "pgm_results");
  if (values(%res_opts)) {
    for my $r_opt ( values(%res_opts) ) {
      if (ref($r_opt)) {
	$fa_opts .= " " . $r_opt->{opt};
      }
      else {
	$fa_opts .= " " . $r_opt;
      }
    }
  }

  unless (exists $run_href->{q_arg}) {
    $query = get_query($q,"query","q_type","query_file",$query_db);
  }
  else {
    $query = get_query($q,
		       $run_href->{q_arg},$run_href->{qt_arg},$run_href->{qf_arg},
		       $query_db);
  }

# make certain we have a "query" sequence
#
  $query = check_bad_query($query);
  unless ($query) {
    if ($q->cgi_error) { $output = $q->cgi_error;}
    else { $output = "<b>ERROR</b>";}
    if ($q->param("query")) {
	$output .= fasta_error("$query_db: ". $q->param("query") ."  not found");
    }
    else {
	$output .= fasta_error("query not found");
    }
    if ($DEBUG) {$output .=  $self->dump_html();}
    return $output;
  }

  $run_data{query} = $query;

  ($query_info) = ($query =~ m/^>(.{1,60})/m);

  if ($DEBUG) {
      $output .= "<pre>$query_db - ".$q->param("query") . "\n$query\n</pre>\n<hl>\n";
  }

  my ($query_str, $query_loc) = ("\@","");
  my $query_range = "";

#
# need a tmp file for query1
#
  if ($run_href->{query1_type} && $run_href->{query1_type} eq 'tmp') {

    my $tmp_fh = new File::Temp(DIR=>$TMP_DIR,
				TEMPLATE=>"FA_WWW_XXXXXX",
				SUFFIX => ".q",
				UNLINK => $DEF_UNLINK);
    chmod 0644, $tmp_fh->filename();
    $query_str = $tmp_fh->filename();
    $query_loc = $query_str;
    $query_loc =~ s/$TMP_DIR\///;

    ## check for uri_encoded query -- possibly from json??
    if ($query =~ m/^%(25)+3E/) {
	$query =~ s/%(25)+/%/g;
	$query = uri_decode($query);
    }
    elsif ($query =~ m/^%3E.+%0A/) {
	$query = uri_decode($query);
    }

    print $tmp_fh $query . "\n";
    close $tmp_fh;
    push @tmp_fh_list, \$tmp_fh;

    $query = "";
  }

  if ($run_href->{have_ssr}) {
    if ((defined $q->param('ssr_flag') && $q->param('ssr_flag')) &&
	$q->param('ssr')) {
      $query_range = get_safe_range("", scalar($q->param('ssr')));
      if ($query_range) { $query_str .= ":$query_range"; }
    }
  }

# get second query/query_file/library
#

  if ($n_queries == 2) {
    $query2 = get_query($q,"query2","q2_type","q2_file_name",$query2_db);
    unless ($query2) {
      $output = fasta_error("$query2_db: ". $q->param("query2") . " not found");
      if ($DEBUG) {
	$output .=  $self->dump_html();
      }
      return $output;
    }
    if ($DEBUG) {
      $output .= "<pre>$query2_db - ".$q->param("query2") . "\n</pre>\n<hl>\n";
    }
    ($lib_info) = ($query2 =~ m/^(.*)$/m);

    $query_str2 = "\@";
    if ($run_href->{have_ssr2}) {
      $query_range2 = get_safe_range("", scalar($q->param('ssr2')));
      if ($query_range2) {
	$query_str2 .= ":$query_range2";
      }
    }
  }
  elsif ($run_href->{query2_type} && $run_href->{query2_type} =~ m/tmp/) {
    # get a possibly available tmp query.
    $query2 = get_query($q,"query2","q2_type","q2_file_name",$query2_db);
  }

#
# need a temporary file for query2
#
  if ($run_href->{query2_type} && $run_href->{query2_type} =~ m/tmp/) {
    my $tmp_fh = new File::Temp(DIR=>$TMP_DIR,
			     TEMPLATE=>"FA_WWW_XXXXXX",
			     SUFFIX => ".q2",
			     UNLINK => $DEF_UNLINK);
    chmod 0644, $tmp_fh->filename();
    $q2_tmp_name = $tmp_fh->filename();
    print $tmp_fh $query2 . "\n";
    close $tmp_fh;
    push @tmp_fh_list, \$tmp_fh;

    if ($run_href->{have_ssr2}) {
      $query_range2 = get_safe_range("", scalar($q->param('ssr2')));
      if ($query_range2) {
	$q2_tmp_name .= ":$query_range2";
      }
    }
  }

  if (exists $run_href->{lib_env}) {
    $ENV{'FASTLIBS'} = $run_href->{lib_env}
  }

  if (exists $run_href->{link_url_ref}) {
    set_url_envs($q, $run_href);
  }

# get program binary name
  my $fa_pgm = $pgm_name{$q->param("pgm")};

#
#  allow $fa_pgm to be a function reference, as well as a string.  If
#  it's a function reference, then call the function with the
#  information required.
#

  my $pgm_cmd;
  my $pgm_args = "";

  if (ref($fa_pgm) && ref($fa_pgm) eq 'CODE') {
    $pgm_cmd =  $fa_pgm->($q, $run_href);
  }

#
# set up command line
#
  $pgm_cmd = "$BIN_DIR/$fa_pgm";

  if ($run_href->{pgm_args}) {
    $pgm_args = $run_href->{pgm_args} . " $fa_opts";
  } else {
    $pgm_args = $fa_opts;
  }

  if ($run_href->{use_query1} || $run_href->{query1_type}) {
    my $query1_opt = (defined($run_href->{query1_opt})) ? $run_href->{query1_opt} : '';
    if ($pgm_args) {
      $pgm_args .= " ". $query1_opt . $query_str;
    } else {
      $pgm_args = $query1_opt . $query_str;
    }
  }

#  $pgm_args =~ s/[^$OK_CHARS]/_/go;

################
# get the library type or second file
#
  if (exists $run_href->{query2_type}) {
    my $query2_opt = "";
    if (exists($run_href->{query2_opt}) && $run_href->{query2_opt}) {
      $query2_opt = $run_href->{query2_opt};
    }

    if ($run_href->{query2_type} =~ m/tmp/ && $query2) {
      $pgm_args .= " $query2_opt$q2_tmp_name";
    }
#
# get library type here
#
    elsif ($run_href->{query2_type} =~ m/lib/) {
      ($lib_abbr, $lib_info) =
	$run_href->{get_lib_sub}($q,$query2_db,$run_href);

      $pgm_args .= " $query2_opt$lib_abbr";
    }
    elsif ($run_href->{query2_type} eq 'q2') {
      $pgm_args .= " $query2_opt$query_str2";
      $query = "$query\n$query2\n";
    } else {
      $output = fasta_error("Program: $pgm - query2_type not found");
      if ($DEBUG) {
	$output .= $self->dump_html();
      }
      return $output;
    }
  }
  $run_data{lib_abbr} = $lib_abbr;

  if (exists $run_href->{post_opts}) {
    my %p_opts = get_fasta_opts_byref($q, $run_href, "post_opts");
    if (values(%p_opts)) {
      my $post_opts = join(' ', values(%p_opts));
      $post_opts =~ s/[^$OK_CHARS]/_/go;
      $pgm_args .= $post_opts;
    }
  }

# should set $HIDE_ALIGN
  if (exists $run_href->{www_opts}) {
    get_www_opts_byref($q, $run_href, "www_opts");
  }

  if ($DEBUG) {
    $output .= "<pre>$pgm_cmd $pgm_args\n</pre>\n";
  }

#  $pgm_args =~ s/[^$OK_CHARS]/_/go;
  ($pgm_args) = $pgm_args =~ m/^\s*(.*)/; # de-taint and remove leading spaces

#  print STDERR join("::",@cmd_list),"\n";

  my $start_time = time();

  my $comments = get_safe_string("%s", scalar($q->param("comments"))) || "";
  $comments = HTML::Entities::encode($comments);
  unless ($comments) {
    $comments = "$pgm_title search started " . `/bin/date`;
  }

  $q->param(-name=>"comments", value => $comments);

################
# run it in the background
#

  if (defined($run_href->{iter_parms})) {
    for my $parm (@{$run_href->{iter_parms}}) {
      $run_data{$parm} = $q->param($parm);
    }
  }

  # if ($q->param('this_iter')) {
  #   $run_data{this_iter} = $q->param('this_iter');
  # }

  # if ($q->param('pssm_evalue')) {
  #   $run_data{'pssm_evalue'} = $q->param('pssm_evalue');
  # }

  if ($run_href->{run_bkgd}) {

    my @cmd_list = (shellwords($pgm_cmd), quotewords('\s+',1,$pgm_args));

    my $out_fh = new File::Temp(DIR=>$TMP_DIR,
				TEMPLATE=>"FA_RID_XXXXXXXX",
				SUFFIX => ".res",
				UNLINK => 0);

    my $out_filename = $out_fh->filename();
    my $ref_filename = $out_filename;
    $ref_filename =~ s/\.res$//;
    $ref_filename =~ s%$TMP_DIR\/%%;
    close($out_fh);
    Do_log($r_host, join(":",@cmd_list) . " >" . $out_fh->filename());

################
# before fork()ing, store info about this search in session object
# search info is in hash{$ref_filename} so that multiple searches can
# be retrieved
    $session->param( 'current' => $ref_filename,
		     $ref_filename => {
				       pgm => $pgm,
				       pgm_title => $pgm_title{$pgm},
				       result_rm => $run_mode,
				       s_time => $start_time,
				       query_info => $query_info,
				       lib_info => $lib_info,
				       result_file => $ref_filename,
				       comments => $comments,
				       status => 'RUNNING'
				      }
		   );

    my $json = JSON::PP->new();
    $json->allow_blessed(1);

    my $json_params = $json->encode(\%run_data);
##    my $json_params = encode_json(\%run_data);

    $json_params = uri_encode($json_params);

    unless (my $pid =fork()) {

################
# put the PID in a file
# (later, put the important parameters to retrieve the result:
# rm, pgm, db -- possibly use json
#
      open(SFH, ">$out_filename"."_PID") || die "cannot open $out_filename" . "_PID after fork()";
      print SFH "pid:$$\npgm:$pgm\nresult_rm:$run_mode\njson_parms:$json_params\n";
      my $remote_file = get_safe_filename($q,"remote_file");
      if ($remote_file) {print SFH "remote_file:$remote_file\n";}
      if ($HIDE_ALIGN) {print SFH "hide_align:$HIDE_ALIGN\n";}
      if ($q->param('on_remote')) { print SFH "on_remote:1\n";}
      close(SFH);

#      system(qq(echo "pid:$$\npgm:$pgm\nresult_rm:$run_mode" > $out_filename) . "_PID");
      close(STDIN);
      close(STDOUT);
      close(STDERR);

################
# build the command
      my $command = "( ". join(" ",@cmd_list) . " >" . $out_filename . "; echo `/bin/date` > " .$out_filename."_DONE ) &";
#      my @command = (" ", @cmd_list, " >$out_filename", shellwords("; echo `/bin/date` > " .$out_filename."_DONE ) &"));
#      print STDERR '@command: '.join("::",@command) . "\n";
#      Do_log($r_host, '$command: '. $command);
################
# echo the $query to the command and run it
      system("ulimit -t $BACK_TIMEOUT; $command");
      chmod 0644, $out_filename;
      exit(0);
    }
################
# in the parent, start up the "waiting" page
#
    else {
      my $tmpl = $self->load_tmpl("wait.tmpl");
      my $remote = "";

      $tmpl->param("RESULT_PGM"=>$pgm,
		   "RESULT_RM"=>$run_mode,
		   "RUN_MODE"=>"wait",
		   "DEBUG"=>$DEBUG,
		   "DBG_OUTPUT"=>HTML::Entities::encode($output),
		   "REMOTE_HOST" => "",
		   "REMOTE_FILE" => "",
		   "S_TIME"=> $start_time,
		   "E_TIME"=> 1,
		   "COMMENTS"=> HTML::Entities::encode($comments),
		   "RESULT_FILE"=> $ref_filename,
		   "REFRESH_TIME" => 1,
		   "QUERY_INFO"=>HTML::Entities::encode($query_info),
		   "LIB_INFO"=>$lib_info,
		   "HIDE_ALIGN" => $HIDE_ALIGN,
		   "JSON_PARMS" => $json_params,
		  );

      if ($q->param('on_remote')) {
	  $tmpl->param("ON_REMOTE"=>$q->param('on_remote'));
      }
      return $tmpl->output();
    }
  }
################
# else just run the program and display the results
  else {
    my @cmd_list = (shellwords($pgm_cmd), shellwords($pgm_args));
    Do_log($r_host, join(":",@cmd_list));

    my $run_output = "";
    IPC::Run::run \@cmd_list, \$query, \$run_output, \$err, timeout($RUN_TIMEOUT)
	or carp("cannot run $pgm_cmd $pgm_args -- " . (($?)>>8).":".($?&255) . "\n");

    unless ($run_href->{err2out}) {
	if ($err) {carp($err);}
    }

#    Do_log($r_host, $run_output);

    if (defined($run_href->{save_res_file}) && $run_href->{save_res_file}) {
      my $out_fh = new File::Temp(DIR=>$TMP_DIR,
				  TEMPLATE=>"FA_RID_XXXXXXXX",
				  SUFFIX => ".res",
				  UNLINK => 0);

      my $out_filename = $out_fh->filename();
      my $ref_filename = $out_filename;
      $ref_filename =~ s%$TMP_DIR\/%%;

      print $out_fh $run_output;
      close($out_fh);
      chmod(0644,$out_filename);

      $run_data{result_file} = $ref_filename;
    }

    display_result($self, $run_href, \%run_data, $pgm, $DEBUG,
		   $output, $run_output, $raw_mode,
		   scalar($q->param("on_remote")));
  }
}

################################################################
# wait_result() needs to know:
# (1) $q->param('pgm')  for $pgm_dev{$pgm}
# (2) $q->param('result_file') to get the output file name
# (3) $q->param('debug') to get debugging output
#
sub wait_result {
  my $self = shift;
  my $output="";

  my %run_data = ();
  my $run_data_hr = \%run_data;

  my $q = $self->query();

  my $run_mode = $q->param("result_rm") || "search";
  my $res_file = get_safe_filename($q,"result_file");
  my $run_href = $run_list{$run_mode};
  unless ($run_href) {
    return fasta_error("Run parameters undefined for $run_mode\n");
  }

################
# check for remote result
#
  my $r_host = "";
  my $remote_file  = "";
  my $raw_mode = 0;

  if ($q->param("remote_host")) {
    $r_host = get_safe_string("%s", scalar($q->param("remote_host")));
    $remote_file = get_safe_filename($q,"remote_file");

    $output="<h3>Search on $r_host</h3>";
    check_remote_result($q, $r_host, $remote_file, $res_file);
    $raw_mode = 0;
    $q->param(-name =>'on_remote', -value=>0);
  }

################
# get the parameters submitted
#
  $HIDE_ALIGN = $q->param("hide_align");

  unless ($res_file && -e "$TMP_DIR/$res_file".".res_DONE") {
    $res_file =~ s/\.res$//;
    $res_file = HTML::Entities::encode($res_file);

    my $start_time = $q->param("s_time");
    ($start_time) = ($start_time =~ m/(\d+)/);
    my $elapsed_time = time() - $start_time;
    my $refresh = $q->param("refresh_time") || 2;
    if ($refresh < 30) { $refresh *= 2; }
    $q->param(-name=>"refresh_time", -value => $refresh);
    my $spaces = $q->param("spaces") || 1;
    ($spaces) = ($spaces =~ m/(\d+)/);
    if ($spaces > 20) { $spaces = 20;}
    elsif ($spaces < 1) { $spaces = 1;}
    else {$spaces++;}
    $q->param(-name=>"spaces", -value => $spaces);

    my $query_info = get_safe_string("%s",scalar($q->param("query_info"))) || "";
    $query_info = HTML::Entities::encode($query_info);
    $q->param(-name=>"query_info", -value => $query_info);

    my $lib_info = get_safe_string("%s", scalar($q->param("lib_info"))) || "";
    $lib_info = HTML::Entities::encode($lib_info);
    $q->param(-name=>"lib_info", -value => $lib_info);

    my $comments = get_safe_string("%s", scalar($q->param("comments"))) || "";
    $comments = HTML::Entities::encode($comments);
    $q->param(-name=>"comments", -value => $comments);

    my $tmpl = $self->load_tmpl("wait.tmpl");
    my $json_params = encode_json($run_data_hr);
    $json_params = uri_encode($json_params);
    $tmpl->param("E_TIME"=>$elapsed_time,
		 "RESULT_FILE"=>$res_file,
		 "REFRESH_TIME"=>$refresh,
		 "SPACES"=>"." x $spaces,
		 "QUERY_INFO"=> HTML::Entities::encode($query_info),
		 "LIB_INFO"=> $lib_info,
		 "COMMENTS"=> $comments,
		 "HIDE_ALIGN" => $HIDE_ALIGN,
		 "JSON_PARMS" => $json_params,
	);

# if we are on a remote host, then we need to remind ourself in wait_result()
# running on the remote
    if ($r_host) {
      $tmpl->param("REMOTE_HOST" => $r_host,
		   "REMOTE_FILE" => $remote_file,
		   "ON_REMOTE" => 1,
		  );
    }

    if ($q->param('on_remote')) {
	$tmpl->param("ON_REMOTE"=>$q->param('on_remote'));
    }
    my $html = $tmpl->output();
    my $form =  HTML::FillInForm->new();
    return $form->fill(\$html,$q);
  }

################
# have the .res_DONE file
  my $pgm = $q->param("result_pgm") || "fap";
  $DEBUG = $q->param("DEBUG");

  if ($q->param("json_parms")) {
    my $json_param = $q->param("json_parms");
    $json_param= uri_decode($json_param);
    $run_data_hr = decode_json($json_param);
  }

  if ($DEBUG) {  $output = scalar($q->param("dbg_output")) || "";}

################
# read the file
  $res_file .= ".res";
  open(FH, "$TMP_DIR/$res_file") || die("cannot open results file\n");
  my $run_output = "";
  while (<FH>) {
    if ($_ =~ m/^<body>/) {
      $run_output .= "$_\n$output\n";
      $output = "";
    }
    else { $run_output .= $_ ; }
  }

  $run_data_hr->{result_file} = $res_file;

  if (defined($run_href->{iter_parms})) {
    for my $parm (@{$run_href->{iter_parms}}) {
      $run_data{$parm} = scalar($q->param($parm));
    }
  }

  display_result($self, $run_href, $run_data_hr, $pgm,
		 $DEBUG, $output, $run_output, $raw_mode, scalar($q->param('on_remote'))
		);
}

################################################################
# status_result()  -- requires session to be working
# check session status, list all jobs running/finished from this session id
# (later) provide ability to delete (forget) old jobs
#
sub status_result {
  my $self = shift;
  my $session = $self->session();

  my @session_params = $session->param();

  my @results = grep { !/^current/ } @session_params;

  my @status_fields = qw(pgm query_info start_time result_file);

  my $tmpl = $self->load_tmpl("status.tmpl");

  unless (scalar(@results)) {
    return $tmpl->output();
  } else {

################
# now check for delete parameter
#
    my $q = $self->query();
    my @q_params = $q->param();

    my @del_params = grep { /^del_/ } @q_params;

    if (@del_params) {
      my @del_files = ();
      for my $del_result ( @del_params ) {
	if (scalar($q->param($del_result)) =~ m/delete/i) {
	  $del_result =~ s/del_//;
	  push @del_files, $del_result
	};
      }
      if (@del_files) {	# have some files to delete
	# make a list of results in a hash
	my %results = map { $_ => 1 } @results;
	for my $del_file (@del_files) {
	  print STDERR "Deleting $del_file\n";
	  if (-e "$TMP_DIR/$del_file".".res_DONE") {
	    unlink "$TMP_DIR/$del_file".".res_DONE" || carp ("Cannot unlink $TMP_DIR/$del_file".".res_DONE");
	    unlink "$TMP_DIR/$del_file".".res_PID" || carp ("Cannot unlink $TMP_DIR/$del_file".".res_PID");;
	    unlink "$TMP_DIR/$del_file".".res" || carp ("Cannot unlink $TMP_DIR/$del_file".".res");;
	  }
	  else {
	    carp ("Cannot -e $TMP_DIR/$del_file"."_res_DONE");
	  }
	  # remove it from session data
	  #$session->param(-name=>$del_file, -value=>undef);
	  $session->clear($del_file);
	  # delete from list of results
	  delete($results{$del_file});
	}
      # generate current set of results
      @results = keys(%results);
      }
    }

#   my @results_hr = map { { $_, $session->param($_) } } @results;
#   @results_hr = sort { $a->{start_time} <=> $b->{start_time} } @results_hr;

    my @row_list = ();
    for my $result_file ( @results ) {
      my $ses_params_hr = $session->param($result_file);

      my $result_file = $ses_params_hr->{result_file};
      my $result_link = "";
      if (-e "$TMP_DIR/$result_file".".res_DONE") {
	$result_link = qq(<a href="fasta_www.cgi?rm=retrieve&RID=$result_file">$result_file</a>);
      }
      elsif ($ses_params_hr->{remote_host}) {
	if (check_remote_result($q,
				$ses_params_hr->{remote_host},
				$ses_params_hr->{remote_file},
				$result_file)) {
	  $result_link = qq(<a href="fasta_www.cgi?rm=retrieve&RID=$result_file">$result_file</a>);
	}
	else {$result_link=$result_file;}
      }
      else {$result_link = $result_file;}

      push @row_list, {STATUS_ROW_INFO=>$ses_params_hr->{pgm_title} .
			   ": " . $ses_params_hr->{query_info} ." <b>vs</b> " .
			   $ses_params_hr->{lib_info} . "<br />" . $ses_params_hr->{comments},
		       STATUS_DELETE => qq(<input type="checkbox" value="delete"  name="del_) . $result_file . qq(" ></input>),
		       STATUS_ROW_LINK=>$result_link,
		       STATUS_TIME => $ses_params_hr->{s_time}
		       };
    }
    @row_list = sort { $b->{STATUS_TIME} <=> $a->{STATUS_TIME} } @row_list;
    $tmpl->param(STATUS_LOOP=>\@row_list);
    return $tmpl->output();
  }
}

################################################################
# retrieve_result() gets information for a past result:
# unlike wait_result, which can get information from parameters,
# retrieve_result() must get everything from appropriate files.
# (1) $q->param('pgm')  for $pgm_dev{$pgm}
# (2) $q->param('result_file') to get the output file name
# (3) $q->param('debug') to get debugging output
#
sub retrieve_result {
  my $self = shift;

  my $output="";

  my %run_data = ();
  my $run_data_hr = \%run_data;

  my $q = $self->query();

  my $res_file = get_safe_filename($q,"RID");
  if ($res_file) {$res_file .= ".res";}

  unless ($res_file && -e "$TMP_DIR/$res_file"."_DONE") {
    $res_file =~ s/\.res//;
    $output .=  $q->start_html();
    unless ($res_file) {
      $output .= "<h2>missing RID parameter</h2>\n"
    }
    else {
      $output .= "<h2>$res_file not available</h2>\n";
    }
    $output .= $fa_footer;
    $output .= $q->end_html();
    return $output;
  }

  my $pid_file = $res_file . "_PID";
  my %param_hash = ();
  open PFH,"$TMP_DIR/$pid_file" || die "cannot open $pid_file";
  while (my $line = <PFH>) {
    chomp $line;
    my ($key, $val) = ($line =~ m/^(\w+):(.+)$/);
    $param_hash{$key} = $val;
  }
  close(PFH);

  if (defined($param_hash{json_parms})) {
    $run_data_hr = decode_json(uri_decode($param_hash{json_parms}))
  }

  for my $p_key ( keys(%param_hash) ) {
    unless ($p_key =~ m/json_parms/) {
      $run_data_hr->{$p_key} = $param_hash{$p_key};
    }
  }

  if (scalar($q->param('raw_mode')) && scalar($q->param('raw_mode')) == 1) {
    $param_hash{'raw_mode'} = 1;
  }

  my $run_mode = $param_hash{"result_rm"}|| "search";

  unless ($run_mode) {
    return fasta_error("Undefined retrieved result_rm\n");
  }

  my $run_href = $run_list{$run_mode};
  unless ($run_href) {
    return fasta_error("Run parameters undefined for $run_mode\n");
  }

  my $pgm = $param_hash{"pgm"};
  if ($param_hash{'remote_host'}) {
      $output = "<h3>Search on $param_hash{'remote_host'}</h3>\n";
      $param_hash{"raw_mode"} = 0;
  }

  if (defined($param_hash{'hide_align'}) || scalar($q->param('hide_align'))) {
    $HIDE_ALIGN=$param_hash{'hide_align'};
  }
  else {$HIDE_ALIGN = 0;}

################
# read the file
  open(FH, "$TMP_DIR/$res_file") || die("cannot open results file\n");
  my $run_output ="";
  while (<FH>) {
    if ($_ =~ m/^<body>/) {
      $run_output = "$_\n$output\n";
      $output = "";
    }
    else {$run_output .= $_ ;}
  }

  $run_data_hr->{result_file} = $res_file;

  if (defined($run_href->{iter_parms})) {
    for my $parm (@{$run_href->{iter_parms}}) {
      $run_data{$parm} = scalar($q->param($parm));
    }
  }

  display_result($self, $run_href, $run_data_hr, $pgm,
		 $DEBUG, $output, $run_output, $param_hash{"raw_mode"}, $param_hash{"on_remote"});
}

################################################################
# at this point we have the output
# this section needs to deal with preparing the output
#
sub display_result {
  my ($self, $run_href, $run_data_hr, $pgm, $DEBUG, $output,
      $run_output, $raw_mode, $on_remote) = @_;

  $on_remote = 0 unless defined($on_remote);
  $raw_mode = 0 unless defined($raw_mode);

################
# build list of program titles for labeling output page
  my %pgm_title = map { $_->{pgm} => $_->{title} } @{$run_href->{pgm_ref}};

# special code for setting up postscript output for plotting programs
#
  if ( exists $pgm_dev{$pgm} && $pgm_dev{$pgm}->{'dev'} eq 'SVG' ) {
    my %dv_opts = ();
    if ( exists $run_href->{dev_opts}) {
      %dv_opts = get_fasta_opts_byref($self->query, $run_href, "dev_opts");
    }
    $output .= process_svg_out($run_href, $run_data_hr, $pgm, \%dv_opts, $run_output, \%res_opts);
  }
  elsif ( exists $pgm_dev{$pgm} && $pgm_dev{$pgm}->{'dev'} eq 'ps' ) {
    my %dv_opts = ();
    if ( exists $run_href->{dev_opts}) {
      %dv_opts = get_fasta_opts_byref($self->query, $run_href, "dev_opts");
    }
    $output .= process_ps_out($pgm, \%dv_opts, $run_output, \%res_opts);
  }
#
# here for all programs that do not have plot output
#
  else {
# check to see if program generates html output
#
    if ($run_href->{no_html}) {
	if ($err) {
	    $output .= "<p />\n<pre>$err</pre>\n<hr /><p />\n";
	}
	if ($run_output) {
	    $output .= "<pre>\n$run_output\n</pre>\n";
	}
	else {
	    $output .= "<pre>\n***No run output***\n</pre>\n";
	}
    }
    else {
      if (!$raw_mode && !$on_remote && $run_href->{domain_color}) {
	$output .= $run_href->{domain_color}($run_href, $run_data_hr, $pgm, $run_output,$self->query);
      }
      else {
	$output .= $run_output;
      }
    }

################
# remove $TMP_DIR references from output
#

    $output =~ s%$TMP_DIR\/%%g;
#    $output =~ s%FA_WWW.*?\.%TMP.%g;
    $output =~ s%$BIN_DIR\/%%g;
  }

  $output .= "\n" ;

  my $header = $run_href->{header} || $fa_footer;
  my $footer = $run_href->{footer} || $fa_footer;

################
# format output
#
  my $q = $self->query();

  if ($DEBUG) {
    my $cmd_line = "command args:\n";
    for my $p ($q->param()) {
      $cmd_line .= ( " $p=".scalar($q->param($p)));
    }

    return $q->start_html("$pgm_title{$pgm} results") . "\n".
      $self->dump_html() . "\n" .  "<hr />$cmd_line\n<hr />\n" . $header .
	"$output\n$footer" . $q->end_html() . "\n";
  }

  if ($raw_mode) { return $output; }
  else {
      return
	  $q->start_html(-title=>"$pgm_title{$pgm} results",
			 -script=>{"src"=>"align_hide.js"},
	  )
	  . "<!-- DONE -->\n" . "\n$header"
	  . "$output\n$footer". $q->end_html() . "\n";
  }
}

#################################################################
#
# remote - run program on remote machine. This function simply
# (1) checks for a valid remote program
# (2) looks up the query sequence
# (2a) looks up the query2 sequence, if necessary
# (2b) uploads files if necessary, and creates new files for upload
# (3) picks a remote node and labels the output
# (4) changes $q->param("rm") to search (rather than remote),
# (5) sends things on their way using LWP::UserAgent
# (6) returns the output
#
################################################################

sub remote {

  my $self = shift;
  my $q = $self->query();
  my %rem_files = ();

#  my $rem_rm = 'search';
  my $rem_rm = scalar($q->param('rem_rm'));

  unless ($rem_rm) {
      return "<h2> no rem_rm for remote search</h2>\n". $self->dump_html() . "\n</body>\n</html>\n";
  }

  my $r_host = $q->remote_host();

# get session info for saving search information
#
  my $session = $self->session();

  my $output;

  $DEBUG = scalar($q->param("debug"));

# (1) - check for a valid program

  my @pgm_list = (@pgm_flist, @pgm_slist, @pgm_hlist, @pgm_blist, @pgm_psi2list);
  my %pgm_name = map { $_->{pgm} => $_->{binary} } @pgm_list;
#  my %pgm_qdb_ldb = map { $_->{pgm} => ($_->{q_sq}==$_->{l_sq}) } @pgm_list;

  my %pgm_qdb_ldb =
      map { $_->{pgm} => {q_sq => $_->{q_sq}, l_sq => $_->{l_sq}}} @pgm_list;

  my $pgm = scalar($q->param("pgm"));

#
# get program info
#
  if (!$pgm_name{$pgm}) {
    $output = fasta_error("Program: $pgm not found");
    if ($DEBUG) {$output .= $self->dump_html();}
    return $output;
  }

#
# (2) get the query sequence
#

  my ($query_db, $query2_db) = get_dbs($q,$pgm, $pgm_qdb_ldb{$pgm});
  my $query = get_query($q,"query","q_type","",$query_db);

  unless ($query) {
    $output = fasta_error("$query_db: ". $q->param("query"). " not found");
    if ($DEBUG) {$output .=  $self->dump_html();}
    return $output;
  }

  my ($query_info) = ($query =~ m/^>(.*)$/m);

  $q->param("query", $query);	# use the query sequence, not an accession
  $q->param("q_type", "fa");	# q_type is sequence

  my $rem_href = $run_list{$rem_rm};

  my %pgm_title = map { $_->{pgm} => $_->{title} } @{$rem_href->{pgm_ref}};
  $pgm_title = $pgm_title{$pgm};

#
# need to check for PSSM file, and transfer it if present
#


# (2a) get query2 sequence, if one is available
#

  if ($rem_href->{n_q} == 2 ) {
    my $query2 = get_query($q,"query2","q2_type","",$query2_db);

    unless ($query2) {
      $output = fasta_error("$query_db: ". $q->param("query"). " not found");
      if ($DEBUG) {
	$output .=  $self->dump_html();
	return $output;
      }
    }

    $q->param("query2", $query2); # use the query sequence, not an accession
    $q->param("q2_type", "fa"); # q_type is sequence
  }
  elsif ($rem_href->{query2_type} =~ m/lib/) {
    my %pgm_qdb_ldb =
      map { $_->{pgm} => {q_sq => $_->{q_sq}, l_sq =>$_->{l_sq}} } @{$rem_href->{pgm_ref}};
    my ($query_db, $query2_db) = get_dbs($q,$pgm, $pgm_qdb_ldb{$pgm});
    ($lib_abbr, $lib_info) =
      $rem_href->{get_lib_sub}($q,$query2_db,$rem_href);
  }

# (2b) we also need to get other files that have been uploaded
# first, we need to know more about the remote mode that will be run:

  if ($rem_href->{rem_files}) {
      %rem_files = get_remote_files($rem_href->{rem_files}, $q);
  }

# (3) get a host node and label the output
  my $n_host = get_node_host();

# fill out full ip address
  $n_host .= $NODE_EXT;

  if ($DEBUG) {
      $output .= "<pre>$query_db - ".$q->param("query") . "\n</pre>\n<hl>\n";
  }

# (4) changes $q->param("rm") to search (rather than remote)

  $q->param("remote",0);	# make certain remote search is done on remote
  $q->param("debug", $DEBUG);
  $q->param("rm",$rem_rm);	# make run-mode rm=search
  $q->param("raw_mode",1);
  $q->param("on_remote", 1);

  # all the other parameters (p_lib, n_lib, matrix, etc) remain the same

  my $start_time = time();

  my $comments = get_safe_string("%s",scalar($q->param("comments"))) || "";
  $comments = HTML::Entities::encode($comments);
  unless ($comments) {
    $comments = "$pgm_title search started " . `/bin/date`;
  }

  $q->param(-name=>"comments", value => $comments);

# (5) - send things to the remote host

  my $ua = LWP::UserAgent->new;
  $ua->agent("$0");
  $ua->from('wrp@virginia.edu');

  my $n_uri = "http://".$n_host . $NODE_RUN_CGI;
#  print STDERR "Remote request to: $n_uri\n";

################
# get a filename to use as tag, and ultimate destination
#
  my $out_fh = new File::Temp(DIR=>$TMP_DIR,
			      TEMPLATE=>"RM_RID_XXXXXXXX",
			      SUFFIX => ".res",
			      UNLINK => 0);
  my $out_filename = $out_fh->filename();
  close($out_fh);
  chmod 0644, $out_filename;
################
# generate a PID file
#
  open(SFH, ">$out_filename"."_PID") ||
      die "Cannot open $out_filename"."_PID in remote()\n";
  print SFH "pgm:$pgm\nresult_rm:$rem_rm\nremote_host:$n_host\nraw_mode:1\n";
  if (defined(scalar($q->param('hide_align')))) {
    $HIDE_ALIGN=$q->param('hide_align');
    print SFH "hide_align:",scalar($q->param('hide_align')),"\n";;
  }
  else { $HIDE_ALIGN=0;}
  close(SFH);

  $out_filename =~ s/.res//;
  $out_filename =~ s%$TMP_DIR\/%%;

  $q->param("result_file"=>$out_filename);
  $q->param("remote_host"=>$n_host);

  # capture the current parameters to send to remote host
  my %rem_args =  map {($_ => scalar($q->param($_)))} $q->param();

  my $req;

  my $json_parms = encode_json(\%rem_args);
  $json_parms = uri_encode($json_parms);

  # I have some files, add them, and use Content_type=>form-data
  for my $rf_args (keys %rem_files) {
# flip undef location -- perhaps will help uploads work
      $rem_args{$rf_args} = [undef, $rem_files{$rf_args}, 'Content-type' => 'application/octet-stream'];
  }
# POST version
  $req = POST($n_uri, 'Content_Type' => 'multipart/form-data', 'Content' => \%rem_args);

#  GET version
#  my @rem_keys = keys(%rem_args);
#  my $first_arg = shift @rem_keys;
#  my $get_args = "?$first_arg=$rem_args{$first_arg}";
#
#  while (my $arg_keys = shift @rem_keys ) {
#      $get_args .= "&"."$arg_keys=$rem_args{$arg_keys}";
#  }
#  $req = GET($n_uri.$get_args);

  my $res = $ua->request($req);

  my $remote_output = "";
  my $remote_file = "";
  if ($res->is_success) {
#      $output .= $res->content;
# check to see if we are done, and to get remote_filename
    $remote_output = $res->content;
    if ($remote_output =~ m/<!-- DONE -->/) {
      $output .= $remote_output;
      $session->param( 'current' => $out_filename,
		       $out_filename => {
				       pgm => $pgm,
				       pgm_title => $pgm_title{$pgm},
				       result_rm => $rem_rm,
				       s_time => $start_time,
				       query_info => $query_info,
				       lib_info => $lib_info,
				       result_file => $out_filename,
				       comments => $comments,
				       status => 'DONE',
				       json_parms => $json_parms,
				      }
		     );
    }
    else {
################
# we have to wait for it
#      print STDERR "running on $n_host file: $remote_output\n"; (find non-interpolated < TMPL_VAR > but )
      ($remote_file) = ($remote_output =~ m/<!-- RUNNING:(\w+) -->/);
#      print STDERR "running on $n_host file: $remote_file\n";

      $session->param( 'current' => $out_filename,
		       $out_filename => {
				       pgm => $pgm,
				       pgm_title => $pgm_title{$pgm},
				       result_rm => $rem_rm,
				       s_time => $start_time,
				       query_info => $query_info,
				       lib_info => $lib_info,
				       result_file => $out_filename,
				       remote_file => $remote_file,
				       comments => $comments,
				       status => 'REMOTE',
				       remote_host => $n_host,
				       json_parms => $json_parms,
				      }
		     );

      my $tmpl = $self->load_tmpl("wait.tmpl");

      $tmpl->param("RESULT_PGM"=>$pgm,
		   "RESULT_RM"=>$rem_rm,
		   "RUN_MODE"=>"wait",
		   "DEBUG"=>$DEBUG,
		   "DBG_OUTPUT"=>$output,
		   "REMOTE_HOST" => $n_host,
		   "REMOTE_FILE" => $remote_file,
		   "S_TIME"=> time(),
		   "E_TIME"=> 1,
		   "RESULT_FILE"=> $out_filename,
		   "REFRESH_TIME" => 1,
		   "QUERY_INFO"=>HTML::Entities::encode($query_info),
		   "LIB_INFO"=>$lib_info,
		   "HIDE_ALIGN" => $HIDE_ALIGN,
		   "JSON_PARMS" => $json_parms,
		  );

      return $tmpl->output();
    }

  } else {
    $output .=  $res->error_as_HTML;
  }

# (6) return the output
#  actually start the program waiting for the output
  if (scalar($q->param("debug"))) {
    return $q->start_html() . "\n". $self->dump_html() . "\n" .  $output;
  }

  return $q->start_html("search on remote $n_host") . "\n" . $output;
}

################
# produce list of programs for display in form template
#
sub prog_list {

  my ($q,$tmpl,$pgm_lref,$pgm_select) = @_;

  my @search_pgm = map { { PGM_DESC => $_->{label},
			   PGM_VAL => $_->{pgm},
			   PGM_SEL =>
			       ($_->{pgm} eq $pgm_select ? "selected=\"selected\"": "")
			   }
		       } @$pgm_lref;
  $tmpl->param( SEARCH_PGM => \@search_pgm);
}

################
# produce a list of databases for form template
#
sub lib_list {

  my ($tmpl, $name, $list_ref, $lib_sel) = @_;

  my @lib_list;

  @lib_list = @$list_ref;

  my @libs = map { { LIB_DESC => $_->[0],
		     LIB_VAL => $_->[1],
		     LIB_SELECT => ($lib_sel && $_->[1] eq $lib_sel) ? qq(selected="selected") : "",
		     }
	       } @lib_list;

  $tmpl->param( $name => \@libs);
}

################
# transform FASTLIBS file into protein/DNA form list
#
sub fast2libs {
  my ($fast_libs, $libp_ref, $libn_ref) = @_;

  open (FH, $fast_libs) || die " cannot open $fast_libs\n";

  while (<FH>) {
    chomp $_;
    if (m/^([^\$]+)\$0(\w)/) {	# match protein with $0
      push @$libp_ref, [$1, $2];
    }
    elsif (m/^([^\$]+)\$1(\w)/) {	# match DNA with $1
      push @$libn_ref, [$1, $2];
    }
  }
  close (FH);
}

# relevant params():
# sq_type: 1 - protein, 2,3,5 DNA both, forward, reverse
# q_type  "FASTA format"/"Accession/GI"
# query: number or sequence
#
# my $query = get_query($q,"query","q_type","",$query_db);
#

use vars qw( $test_aa );

sub get_query {
  my ($q, $name, $type, $file, $db )  = @_;
  my @acc_list = ();
  my $q_library = "";

  unless (($file && scalar($q->param($file))) || scalar($q->param($name))) {return "";}

  if (scalar($q->param($name)) && scalar($q->param($name)) =~ m/^TEST/) {
    return $test_aa;
  }
#
# file_name trumps name, but needs type
#
  if ($file && scalar($q->param($file))) {
    my $qfh;
    $qfh = $q->upload($file);
    unless($qfh) {return "";}

# $q->tmpFileName($qfd) contains the name of the temporary file,
# which could be used for the search, or stat'ed for size
#
    if (scalar($q->param($type)) && scalar($q->param($type)) =~ m/^acc/i) {
      @acc_list = <$qfh>;
      chomp @acc_list;
    }
    else {
      while (<$qfh>) {$q_library .= $_;}
      close($qfh);
      $q_library =~ s/\r\n/\n/gos;
      $q_library =~ s/\r/\n/go;
      return $q_library;
    }
  }
  else {			# use param($name), not $param($file)
    my $q_acc_name = scalar($q->param($name));
    if ((scalar($q->param($type)) && scalar($q->param($type)) =~ m/^acc/i
	 && $q_acc_name !~ m/^>/ && length($q_acc_name) < 100) || (
	$q_acc_name !~ m/^>/ && ($q_acc_name =~ m/^gi\|/ ||
	$q_acc_name =~ m/^\s*\d+\s*$/ || $q_acc_name =~ m/_/ ||
	$q_acc_name =~ m/^[A-Z]\w{5}$/))) {

      my $acc_list = $q_acc_name;
      $acc_list =~ s/\r//go;

      @acc_list = split(/[\n,]/,$acc_list);

      chomp(@acc_list);
    } else {		     # param($name) has sequences, return them
      my $query = $q_acc_name;
      $query =~ s/\r//go;
      if ($name =~ m/^query/ && $query !~ m/^>/) {
	return ">QUERY\n" . $query ."\n";
      } else {
	return $query . "\n";
      }
    }
  }

# we are here with @acc_list - return them the sequences from the acc's

  for my $acc ( @acc_list ) {

    $acc =~ s/[\n\r]//g;
    next unless($acc);

#    print STDERR "call get_fastacmd: $acc\n";

    my $query = "";

    if ($acc =~ m/^sp\|/) {
	$query = get_fastacmd($db, $acc);
	unless ($query) {
#	    $query = get_uniprot($db, $acc);
	    $query = get_protein($db, $acc);
	}
    }
    elsif ($acc =~ m/^ref\|/ || $acc =~ m/(NX)(PM)_\d+/) {
	$query = get_fastacmd($db, $acc);
	unless ($query) {
#	    $query = get_ncbi($db, $acc);
	    $query = get_protein($db, $acc);
	}
    }
    elsif ($acc =~ m/^(tr|up)\|/ ||
	   $acc =~  m/\|[OPQ][0-9][A-Z0-9]{3}[0-9]|[A-NR-Z][0-9]([A-Z][A-Z0-9]{2}[0-9]){1,2}/) {
#	$query = get_uniprot($db, $acc);
	$query = get_protein($db, $acc);
    }
    else {
#    print STDERR "call get_fastacmd: $acc\n";
	$query = get_fastacmd($db, $acc);
	unless ($query) {
#	    $query = get_ncbi($db, $acc);
	    $query = get_protein($db, $acc);
	}
	unless ($query) {
#	    $query = get_uniprot($db, $acc);
	    $query = get_ncbi($db, $acc);
	}
    }
    $q_library .= $query;
  }
  return $q_library;
}

################
# gets database name, type from $q->param()
# returns ($lib_abbr, $lib_info)

sub get_lib {
  my ($q, $lib_db, $run_href) = @_;

  my ($fa_lib, $fa_file, $fa_info);
#
# set up appropriate protein or DNA library, including defaults
#
  if (scalar($q->param("lib_abbr"))) {$fa_lib = scalar($q->param("lib_abbr"));}
  elsif ($lib_db =~ /^P/i) {
    if (scalar($q->param("p_lib"))) {$fa_lib = $q->param("p_lib");}
    else {$fa_lib = "a";}
    ($fa_file, $fa_info) = scan_fastlibs($fa_lib, $run_href->{lib_env},0);
  }
  else {
    if (scalar($q->param("n_lib"))) {$fa_lib = scalar($q->param("n_lib"));}
    else {$fa_lib = "m";}
    ($fa_file, $fa_info) = scan_fastlibs($fa_lib, $run_href->{lib_env},1);
  }

  return ($fa_lib, $fa_info);
}

################
# returns ($lib_filename, $lib_info)
#

sub get_lib_full {
  my ($q, $lib_db, $run_href) = @_;

#  return "/slib2/blast/pir1.lseg";

  my $fa_lib;

#
# set up appropriate protein or DNA library, including defaults
#

  if ($lib_db =~ /^P/i) {
    if (scalar($q->param("p_lib"))) {$fa_lib = scalar($q->param("p_lib"));}
    else {$fa_lib = "a";}
    return scan_fastlibs($fa_lib, $run_href->{lib_env}, 0);
  }
  else {
    if (scalar($q->param("n_lib"))) {$fa_lib = scalar($q->param("n_lib"));}
    else {$fa_lib = "m";}
    return scan_fastlibs($fa_lib, $run_href->{lib_env}, 1);
  }
}

################
# returns complete file name of library specified by abbreviation
# returns ($lib_file, $lib_info)
sub scan_fastlibs {
    my ($abbr, $fastlibs, $lib_type) = @_;

    unless (open(FLIBS, "<$fastlibs")) {
	print STDERR "could not open $fastlibs\n";
	return "";
    }
    else {
#	print STDERR "$fastlibs - opened\n";
    }

    my $ss = $lib_type . $abbr;
#    print STDERR " search for \$$ss\$\n";
    while (<FLIBS>) {
      chomp;
      if (m/\$$ss\$/i) {
	close FLIBS;
	my ($lib_info, $lib) = (split(/\$/))[0, -1];
#	print STDERR "found $lib \n";
	unless ($lib =~ m/^\{/) { return $lib;}
	else {
#	  my ($env) = ($lib =~ m/{(\w+)}/);
#	  print STDERR "looking for $env: $ENV{$env}\n";
	  $lib =~ s/\{(\w+)\}/$ENV{$1}/;
	  return ($lib, $lib_info);
	}
      }
    }
    close FLIBS;
    return "/slib2/blast/pir1.lseg";
}

################
# returns ($bl_lib_filename)
# sets $lib_info separately
#
sub get_blib {
  my ($prefix, $param_val, $q, $param_arg) = @_;

  my ($bl_lib, $bl_info);
#
# set up appropriate protein or DNA library, including defaults
#
  if (scalar($q->param("p_lib"))) {
    my %bl_lib_hash = map { $_->[0]=>{name=>$_->[2], info=>$_->[1]} } @blp_list;
    $bl_lib = $bl_lib_hash{scalar($q->param("p_lib"))}->{name};
    $bl_info = $bl_lib_hash{scalar($q->param("p_lib"))}->{info};
  }
  else {
    $bl_lib = "pir1";
    $bl_info = "PIR1 Annotated";
  }
  $bl_lib = "$BL_DB_DIR/$bl_lib";

  $lib_info = $bl_info;
  return ("$prefix $bl_lib");
}

# parse a set of options named by $opt_type ("opts", "post_opts")
# options look like this:
# 	 pgm_results => {
#
# 	 },
sub get_fa_results_byref {
  my ($q,$run_href, $opt_type) = @_;

  my %fa_opts = ();

  # return of no options specified in structure
  return () unless $run_href->{$opt_type};

  # point to the option hashref
  my $opt_href = $run_href->{$opt_type};

  ################
  # run through the file options
  for my $opt ( keys( %{$opt_href} )) {
    my $opt_arg_href = $opt_href->{$opt};

    if (ref($opt_arg_href->{res}) eq 'CODE') {
	my $tmp_opt = $opt_arg_href->{res}->($opt_arg_href->{cmd_arg},$opt_arg_href->{suff},scalar($q->param($opt)),$q, $opt);
	if ($tmp_opt) { $fa_opts{$opt} = $tmp_opt;}
    }
  }
  return %fa_opts;
}

# parse a set of options named by $opt_type ("opts", "post_opts")
# options look like this:
# 	 opts => {
# 	     eval => { cmd_arg => "-e", val  => \&get_safe_number},
# 	     comp_stat => {cmd_arg => "-C 1", val => \&get_option, default_arg =>"-C 0"},
# 	     seg_filter => {"-F T", \&get_option, "-F F"},
# 	     gap => { cmd_arg => "-G", val => \&get_safe_number},
# 	     ext => {cmd_arg=>"-E", val =>\&get_safe_number},
# 	     smatrix => {cmd_arg =>"", val=>\&get_bmatrix},
# 	 },
sub get_fasta_opts_byref {
  my ($q,$run_href, $opt_type, $run_data_hr) = @_;

  my %fa_opts = ();

  # return of no options specified in structure
  return () unless $run_href->{$opt_type};

  # point to the option hashref
  my $opt_href = $run_href->{$opt_type};

  ################
  # keys ( %{$option_href} are the possible $q->param() names
  # an alternative strategy would look at $q->param() in the list context,
  # but this would make default parameters more challenging
  #
  my $have_run_data_params = (defined($run_data_hr));

  for my $opt ( keys( %{$opt_href} )) {
    my $opt_arg_href = $opt_href->{$opt};
    if (defined($q->param($opt))) {
      if ($have_run_data_params) {
	$run_data_hr->{$opt} = $q->param($opt);
      }
      if (ref($opt_arg_href->{val}) eq 'CODE') {
	# have a function - run it
	my $tmp_opt = $opt_arg_href->{val}->($opt_arg_href->{cmd_arg},scalar($q->param($opt)),$q, $opt);
	if ($tmp_opt) {$fa_opts{$opt} = $tmp_opt;}
	#  function_ref->(option{cmd_arg}, param_value, $q, param_name)
      }
      #
      #  we don't allow "this" here because we don't want to just grab unparsed
      #  input parameters
      #
      else { # no function, just fill in the value
	$fa_opts{$opt} = $opt_arg_href->{cmd_arg};
      }
    } else { # no parameter entered, use default
      if ($opt_arg_href->{default_arg}) {
	$fa_opts{$opt} = $opt_arg_href->{default_arg};
      }
    }
  }
  return %fa_opts;
}

# parse a set of options named by $opt_type ("www_opts")
# options look like this:
# 	 www_opts => {
#		show_align => { arg => 0, val => \&get_option },
# 	 },
# and set run_href->{www_opts}->{arg} = get_option()
#

sub get_www_opts_byref {
  my ($q,$run_href, $opt_type) = @_;

  # return of no options specified in structure
  return unless $run_href->{$opt_type};

  # point to the option hashref
  my $opt_href = $run_href->{$opt_type};

  ################
  # keys ( %{$option_href} are the possible $q->param() names
  # an alternative strategy would look at $q->param() in the list context,
  # but this would make default parameters more challenging
  #
  for my $opt ( keys( %{$opt_href} )) {
    my $opt_arg_href = $opt_href->{$opt};
    if (defined($q->param($opt))) {
      if (ref($opt_arg_href->{val}) eq 'CODE') {
	# have a function - run it
	${$opt_arg_href->{arg}} = $opt_arg_href->{val}->($opt_arg_href->{cmd_arg},scalar($q->param($opt)),$q, $opt);
	#  function_ref->(option{cmd_arg}, param_value, $q, param_name)
      }
    } else { # no parameter entered, use default
      if ($opt_arg_href->{default_arg}) {
	${$opt_arg_href->{arg}} = $opt_arg_href->{default_arg};
      }
    }
  }
}

##
# given an array of strings, return $string_array[arg]
#
sub put_indexed_args {
  my ($opt, $p_arg) = @_;

  unless ($p_arg) {return "";}

  ($p_arg) = ($p_arg =~ m/([E\d\-\.]+)/i);
  unless ($p_arg) {return "";}

  unless (ref($opt) eq 'ARRAY') {
    return "";
  }

  return $opt->[$p_arg];
}

sub get_bmatrix {
  my ($opt, $p_arg) = @_;

  if ($p_arg) {
    if ($p_arg > 0 && $p_arg < 5 && exists $bmatrix_vals{$p_arg}) {
    } 
    else { return "";  }
  } 
  else { return ""; }

  return sprintf($opt, $bmatrix_vals{$p_arg});
}

sub get_smatrix {
  my ($opt, $p_arg) = @_;
  my $matrix_str = "";

  if ($p_arg) {
      if ($p_arg > 20 && $p_arg <= 24) {
	  $matrix_str = "-r ".$smatrix_vals{$p_arg};
      }
      elsif ($p_arg >= 0 && $p_arg < 15) {
	  $matrix_str = "-s ".$smatrix_vals{$p_arg};
      }
      else { $matrix_str = "";}
  }
  else { $matrix_str = "";}
  return $matrix_str;
}

sub get_query_range {
  my ($q,$param) = @_;

  # do the simple case first ssr:start-stop

  if ($q->param($param)) {
      return get_safe_range("", scalar($q->param($param)));
  }

  if ($q->param("start") || $q->param("stop")) {
    $q->param("start","") unless ($q->param("start"));
    $q->param("stop","") unless ($q->param("stop"));
    return $q->param("start")."-" .$q->param("stop");
    }
  else {
    return "";
  }
}

sub get_db_range {
  my ($q,$param) = @_;

  # do the simple case first db_range:start-stop

  if ($q->param($param)) {
      return get_safe_range("-M", scalar($q->param($param)));
  }
}

#
# put_res2file generates a tmp file for output that can be read later
# sprintf formatted string referring to the file using the $opt format
#
sub put_res2file {
  my ($opt, $suff) = @_;

  # create a temporary file
  my $tmp_fh = new File::Temp(DIR=>$TMP_DIR,
			      TEMPLATE => "FA_WWW_XXXXXX",
			      SUFFIX => $suff,
			      UNLINK => $DEF_UNLINK);
  chmod 0644, $tmp_fh->filename();

  close($tmp_fh);
  push @tmp_fh_list, \$tmp_fh;

  return {file => $tmp_fh->filename(), opt => sprintf("$opt",$tmp_fh->filename())};
}

#
# get_text2file takes an argument with text in it, and returns an
# sprintf formatted string referring to the file using the $opt format
#
sub get_text2file {
  my ($opt, $p_arg) = @_;

  # check to see if text is available
  return "" unless ($p_arg);

  # create a temporary file
  my $tmp_fh = new File::Temp(DIR=>$TMP_DIR,
			      TEMPLATE => "FA_WWW_XXXXXX",
			      SUFFIX => ".txt",
			      UNLINK => $DEF_UNLINK);
  chmod 0644, $tmp_fh->filename();

  $p_arg =~ s/\r\n/\n/ogs;

  print $tmp_fh "$p_arg\n";
  close($tmp_fh);
  push @tmp_fh_list, \$tmp_fh;

  return sprintf("$opt",$tmp_fh->filename());
}

#
# get_query2file puts $query into a file and returns the
# sprintf formatted string referring to the file using the $opt format
#
sub get_query2file {
  my ($opt) = @_;

  # check to see if text is available
  return "" unless ($query);

  # create a temporary file
  my $tmp_fh = new File::Temp(DIR=>$TMP_DIR,
			      TEMPLATE => "FA_WWW_XXXXXX",
			      SUFFIX => ".txt",
			      UNLINK => $DEF_UNLINK);
  chmod 0644, $tmp_fh->filename();

  $query =~ s/\r\n/\n/ogs;

  print $tmp_fh "$query\n";
  close($tmp_fh);
  push @tmp_fh_list, \$tmp_fh;

  return sprintf("$opt",$tmp_fh->filename());
}

#
# get_rid2file takes NCBI BLAST RID, downloads the associated PSSM
# decodes/bunzip2's it, saves it  to a temporary file, and returns its
# uploaded name as an argument
#
sub get_rid2file {
  my ($opt, $p_arg) = @_;

  # check to see if filename is available
  unless ($p_arg) {
#    carp("p_arg - missing: $opt");
    return "";
  }

  # remove RID: at beginning
  $p_arg =~ s/^\s*RID:\s*//;

  my %r_args =
    (
     "CMD" => "Get",
     "FORMAT_OBJECT"=> "PSSM",
     "FORMAT_TYPE" => "Text",
     "RID" => $p_arg,
    );

  my $ua = LWP::UserAgent->new;
  $ua->agent("$0");
  $ua->from('wrp@virginia.edu');

  my $n_uri = "https://www.ncbi.nlm.nih.gov/BLAST/Blast.cgi";

  my $req = POST $n_uri, \%r_args;
  my $res = $ua->request($req);
  my $pssm = '';

  if ($res->is_success) {
      $pssm .= $res->content;
      $pssm = bz2pssm($pssm);
  } else {
      print STDERR  $res->error_as_HTML;
      return "";
  }

# create a temporary file
  my $tmp_fh = new File::Temp(DIR=>$TMP_DIR,
			      TEMPLATE => "FA_WWW_XXXXXX",
			      SUFFIX => ".RID",
			      UNLINK => $DEF_UNLINK);

  chmod 0644, $tmp_fh->filename();

  print $tmp_fh $pssm;

  close($tmp_fh);
  push @tmp_fh_list, \$tmp_fh;

#  print STDERR "RID2file: ". $tmp_fh->filename()."\n";

  return sprintf($opt, $tmp_fh->filename());
}

sub bz2pssm {
  my $enc_bz_pssm = shift;
  my $bz_pssm = '';
  my ($pssm, $err);

  $enc_bz_pssm  =~ s/^.*\n*PSSM:2\n//os;
  $enc_bz_pssm =~s/[^A-F0-9]//g;

  while ( $enc_bz_pssm=~/(..)/g ) {
    $bz_pssm .= chr(hex($1));
  }

  my @cmd_list = ('bunzip2');

  IPC::Run::run \@cmd_list, \$bz_pssm, \$pssm, \$err,
      or carp("cannot run bzip -- $err " . (($?)>>8).":".($?&255) . "\n");

  return $pssm;
}

sub get_remote_files {
  my ($rem_list_r, $q) = @_;

  my %rem_files=();

  for my $r_arg ( keys %$rem_list_r ) {
    if ($q->param($r_arg)) {
      my $file = $rem_list_r->{$r_arg}->[0]("%s", scalar($q->param($r_arg)), $q, $r_arg);
      if ($file) {
	$rem_files{$rem_list_r->{$r_arg}->[1]} = $file;
      }
      $q->param($r_arg, '');
    }
  }
  return %rem_files;
}

sub set_envs {

  $ENV{'FASTLIBS'} = shift;

}

sub set_url_envs {

  my ($q, $run_href) = @_;
  my $gnm_str = $run_href->{link_url_ref};;

  $ENV{'REF_URL'} = qq(<a href="seq_info.cgi?db=%s&amp;cmd=Search&amp;term=%s&amp;doptcmdl=DocSum">Sequence Lookup</a>&nbsp;&nbsp;);

#   $ENV{'SRCH_URL'} = qq(<a href="$search_url_cgi?rm=search$gnm_str&amp;query=%s&amp;q_type=acc&amp;db=%s&amp;lib=%s&amp;pgm=%s&amp;start=%ld&amp;stop=%ld&amp;n1=%d&amp;o_pgm=%s\">Re-search database</a>&nbsp;&nbsp;);

  $ENV{'SRCH_URL'} = qq(<a href="$search_url1_cgi?rm=select$gnm_str&amp;dummy=%s&amp;query=%s&amp;q_type=acc&amp;db=%s&amp;lib=%s&amp;pgm=%s&amp;start=%ld&amp;stop=%ld&amp;n1=%d&amp;o_pgm=%s\">Re-search w/subject</a>&nbsp;&nbsp;);

  $ENV{'SRCH_URL1'} = qq(<a href="$search_url1_cgi?rm=compare&amp;query=%s&amp;q_type=acc&amp;query2=%s&amp;q2_type=acc&amp;db=%s&amp;lib=%s&amp;pgm=%s&amp;start=%ld&amp;stop=%ld&amp;n1=%d&amp;o_pgm=%s\">Pairwise alignment</a>\n);

  my ($q_ann_val, $l_ann_val) = (0,0);

  $q_ann_val = $q->param('annot_seq1') if (defined ($q->param('annot_seq1')));
  $l_ann_val = $q->param('annot_seq2') if (defined ($q->param('annot_seq2')));

  my $q_ann_file = $q->param('annot_seq1_file') if (defined ($q->param('annot_seq1_file')));
  my $l_ann_file = $q->param('annot_seq2_file') if (defined ($q->param('annot_seq2_file')));

  my $svg_height = 48;

  if ($l_ann_file || $l_ann_val) {
    $svg_height += 14;
  }

  if ($q_ann_file || $q_ann_val) {
    $svg_height += 14;
  }

  $ENV{'DOMAIN_PLOT_URL'} = qq(<object type="image/svg+xml" data="$domain_plot_url_cgi?pgm=%s&amp;q_name=%s&amp;q_cstart=%ld&amp;q_cstop=%ld&amp;q_astart=%ld&amp;q_astop=%ld&amp;l_name=%s&amp;l_cstart=%ld&amp;l_cstop=%ld&amp;l_astart=%ld&amp;l_astop=%ld&amp;regions=%s&amp;doms=%s\" width=\"660\" height=\"$svg_height\"></object>\n);


}

#
# for programs where query and library database match, put 1
#
sub get_dbs {
  my ($q, $pgm, $qdb_ldb) = @_;
  my ($q_db, $l_db);
  my @db_names = ("Protein", "DNA");

  # if we have param("db"), ignore param("sq_type")

  return ($db_names[$qdb_ldb->{q_sq}],
	  $db_names[$qdb_ldb->{l_sq}]);
}

#
# the load_links(), load_library(), and load_vars()
# functions use table driven strategies to load all the parts of the
# templates
#

# links to other (related pages)
#
sub load_links {
    my ($form, $tmpl) = @_;
    my $tbl_rows = @{$page_link_list{$form}->[0]};
    my @tbl_list = ();

    my $first_row = 1;
    for my $pgm ( @{$page_link_list{$form}->[0]} ) {
	if ($pgm eq 'this') {
	    push @tbl_list, {LINK =>  "<h2>$page_links{$form}->{desc}</h2>",
			     ROWS => ($first_row ? $tbl_rows : 0),
			     TEXT => $page_link_list{$form}->[1]
			 };
	}
	else {
	    push @tbl_list,
	    { LINK => qq[<a href="$page_links{$pgm}->{link}"><font size="+0.5">$page_links{$pgm}->{desc}</font></a>],
	      ROWS => ($first_row ? $tbl_rows : 0),
	      TEXT => $page_link_list{$form}->[1]
	      };
	}
	$first_row = 0;
    }
    $tmpl->param(LINKS_LIST => \@tbl_list);
}

sub load_library {
  my ($form_href, $tmpl, $lib_sel) = @_;

  if ($tmpl->query('name' => 'LIB_P')) {
    if ($form_href->{lib_env}) {
      my @lib_fp = ();
      my @lib_fn = ();
      fast2libs($form_href->{lib_env}, \@lib_fp, \@lib_fn);
      lib_list($tmpl, "LIB_P", \@lib_fp, $lib_sel);
      if ($tmpl->query('name' => 'LIB_N')) {
	  lib_list($tmpl, "LIB_N", \@lib_fn, "");
      }
    }
    elsif ($form_href->{lib_ref}) {	# currently only for BLAST
      my @lib_fp = map { [ $_->[1], $_->[0] ] } @{$form_href->{lib_ref}};
      my @lib_fn = (["",""]);

      lib_list($tmpl, "LIB_P", \@lib_fp, $lib_sel);
      if ($tmpl->query('name' => 'LIB_N')) {
	  lib_list($tmpl, "LIB_N", \@lib_fn, "");
      }
    }
  }
}

sub build_run_pssm {
  my ($q, $run_href) = @_;

  my ($pssmfh, $pssmfile) = (undef,"");;


  $ENV{BLASTDB} = $BL_DB_DIR;
  $ENV{BLASTMAT} = $BL_DATA_DIR;
  $ENV{BLASTFILTER} = $BL_DATA_DIR;

  my $is = $q->param("msa_query");
  if ($is) {
    my ($queryfh, $queryfile) = File::Temp::tempfile("CH_XXXXXX", DIR=>$TMP_DIR,SUFFIX=>".msa", UNLINK => $DEF_UNLINK);
    my $oldfh = select $queryfh; $|++;

    my ($alignfh, $alignfile) = File::Temp::tempfile("CH_XXXXXX", DIR=>$TMP_DIR,SUFFIX=>".baln", UNLINK => $DEF_UNLINK);

    ($pssmfh, $pssmfile) = File::Temp::tempfile("CH_XXXXXX", DIR=>$TMP_DIR,SUFFIX=>".asn1", UNLINK => $DEF_UNLINK);

    chmod 0755, $queryfile, $alignfile, $pssmfile;

    select $alignfh; $|++;	# turn on autoflush for $alignfh
    select $oldfh;

    $is =~ s/\r\n/\n/gs;

    # allow read of param("msa_query") (which is now a clustalw alignment)
    my $isfh = new IO::Scalar \$is;
    my $sawblank = 1; my $idprinted = 0;
    my ($id, $seq);
    while (<$isfh>) {
      next if (m/^CLUSTAL W/);
      next if (m/^MUSCLE/);
      print $alignfh $_ unless $sawblank && m/^\s*$/o; # skip blanks unless non-blank
      if ($sawblank && !m/^\s*$/o) {
	chomp;
	($id, $seq) = m/^\s*(\S+)\s*(.*)/;
	$seq =~ s/\W//g;
	print $queryfh ">$id\n" unless $idprinted++;
	print $queryfh "$seq\n";
	$sawblank--;
      } elsif (!$sawblank && m/^\s*$/o) {
	$sawblank++;
      }
    }
    #     generate PSSM (asn.1 format)
    system("$BL_BIN_DIR/blastpgp",
	   split(' ',"-i $queryfile -B $alignfile -J T -u 2 -C $pssmfile -o /dev/null -d $BL_DB_DIR/pir1"));
  }
  # here we have a pssm, if it exists
  # now run ssearch with pssm, if it exists

  if ($pssmfile) {
    return "$BIN_DIR/$pgm_pssm_br{$q->param('pgm')} " . qq(-P "$pssmfile 2");
  } else {
    return "$BIN_DIR/$pgm_pssm_br{$q->param('pgm')}";
  }

}

sub process_svg_out {
  my ($run_href, $run_data_hr, $pgm, $dopts_ref, $run_output, $res_opts_hr) = @_;

  my $y_height = 660;
  my $aln_output = "";
  my $text_width = 72;

  my $tmp_lavh = new File::Temp(DIR => $TMP_DIR, SUFFIX => ".lav",
				TEMPLATE=>"LAV_WWW_XXXXXX", UNLINK => 0);

  if ($res_opts_hr->{aln_output}) {
    my $tmp_file = $res_opts_hr->{aln_output}->{file};
    my $tmp_query = '';
    open (my $F_ALN, $tmp_file) || die "cannot open alignment file: ".$tmp_file;
    $_ = <$F_ALN>;
    s/$tmp_file/TMPF/g;
    ($tmp_query) = (m/\s(\S+)$/);
    s/$tmp_query/TMPQ/g;
    $aln_output = $_;
    while (<$F_ALN>) {
      s/$tmp_query/TMPQ/g;
      if (m/^\s*\d+>>>/ && length($_) > $text_width) {$aln_output .= substr($_, 0, $text_width); $aln_output .= "\n";}
      else { $aln_output .= $_;}
    }
    close($F_ALN);
  }

  my $tmp_lavname = $tmp_lavh->filename();
  print $tmp_lavh $run_output;
  close $tmp_lavh;
  push @tmp_fh_list, \$tmp_lavh;
  chmod 0644, $tmp_lavname;

  my $url_psname = $tmp_lavname;
  $url_psname =~ s%$TMP_DIR\/%%g;

  my $dopts="";
  if (ref($dopts_ref) && values(%$dopts_ref)) {
#    for my $key (keys(%$dopts_ref)) {
#      print STDERR "$key\t".$dopts_ref->{$key}."\n";
#    }
    $dopts = "&". join("&",values(%$dopts_ref));
  }

  my $tmp_pdfname = "tmp_lav.cgi?name=$url_psname&Z=1&del=no&size=6000x$y_height"."0&dev=pdf" . $dopts;
  my $svg_url="tmp_lav.cgi?name=$url_psname&Z=1&del=no&size=660x$y_height&dev=svg" . $dopts;
  my $gif_url="tmp_lav.cgi?name=$url_psname&Z=1&del=no&size=660x$y_height&dev=png" . $dopts;

  my $output = "";

  # $output ..= qq(\n<pre>$err\n</pre>\n<hr />\n);
  # $output .= qq(<form action="$svg_url"><a href="$tmp_pdfname">Click for PDF</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="$svg_url">Download SVG</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="checkbox" name="xA" value=1>Annotate Seq 1&nbsp;<input type="checkbox" name="yA" value=1>Annotate Seq 2&nbsp;<input type='submit' name='plot' value="Re-plot"><input type="hidden" name="name" value="$url_psname"></form>\n);

  if ($aln_output) {
      $output .= qq(<table><tr><td width='50%' valign='top' id="td_plot">\n);
      $output .= qq(<div id="show_hide_d" style="position:fixed;">);
  }

  $output .= qq(<a href="$tmp_pdfname">Click for PDF</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="$svg_url">Download SVG</a>);

  if ($aln_output) {
      $output .= qq(<br /><input type='radio' name="show_lav" onclick="document.getElementById('lav_plot').style.display='none'; document.getElementById('lav_plot').style.position='automatic'; document.getElementById('td_plot').style.width='25%'; document.getElementById('td_aln').style.width='75%';" value="1" />Hide plot);
      $output .= qq(&nbsp;&nbsp;&nbsp;<input type='radio' name="show_lav" onclick="document.getElementById('lav_plot').style.display='block'; document.getElementById('td_plot').style.width='50%'; document.getElementById('td_aln').style.width='50%';" value="1" checked="checked" />Show plot);
      $output .= qq(&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type='radio' name="show_aln" onclick="document.getElementById('aln_disp').style.display='none';" value="1" />Hide align);
      $output .= qq(&nbsp;&nbsp;&nbsp;<input type='radio' name="show_aln" onclick="document.getElementById('aln_disp').style.display='block';" value="1" checked="checked" />Show align<br />);
      $output .= qq(</div>\n);
      $output .= qq(<div id="lav_plot" style="float:left; width: 660px ; margin-left: 0px; margin-right: -10px; margin-top: 24px; position:fixed;" >\n);
  }
  else { $output .= "\n";}
  $output .= qq(<p /><a name='#plot'>\n);
  $output .= qq(<object data="$svg_url" width="660" height="684" type="image/svg+xml">\n);
  $output .= qq(<img src="$gif_url" />\n</object>\n);
  $output .= qq(</a>\n);
  $output .= qq(<p /><a href="$tmp_pdfname">Click for PDF</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="$svg_url">Download SVG</a>\n);

  if ($aln_output) {
#    $output .= qq(</div></td><td width=50%><div style="float:left; width: 100%; margin-left: 0; margin-right: 10px;">\n$aln_output\n</div></td></tr></table>\n);

    if ($pgm =~ m/\%xANNOT\%/ && $dopts_ref->{annot_seq1}) {
      my $annot_str = $dopts_ref->{annot_seq1};
      $pgm =~ s/\%xANNOT\%/$annot_str/;
    }

    if ($pgm =~ m/\%yANNOT\%/ && $dopts_ref->{annot_seq2}) {
      my $annot_str = $dopts_ref->{annot_seq2};
      $pgm =~ s/\%yANNOT\%/$annot_str/;
    }

    if ($run_href->{domain_color}) {
      $aln_output = $run_href->{domain_color}($run_href, $run_data_hr, $pgm, $aln_output);
    }

    $output .= qq(</div></td><td width=50% id="td_aln"><div id="aln_disp">\n$aln_output\n</div></td></tr></table>\n);
  }
  return $output;
}

sub process_ps_out {
  my ($pgm, $dopts_ref, $run_output) = @_;
  my $ps_out = "";

  if ($pgm_dev{$pgm}->{'pgm_ps'}) {	# need to run a filter program <stdin >stdout
    my $filter_script = $pgm_dev{$pgm}->{'pgm_ps'};

    my $ps_cmd = "$BIN_DIR/".$filter_script;

    my @ps_cmd_list = shellwords($ps_cmd);

    Do_log($r_host, join(":",@ps_cmd_list));

    my $ps_err;

    IPC::Run::run \@ps_cmd_list, \$run_output, \$ps_out, \$ps_err
	or carp("cannot run $ps_cmd -- " . (($?)>>8).":".($?&255) . "\n");
  } else {
    $ps_out = $run_output;
  }

  my $y_height = 624;
  if ($pgm eq 'pkd') {
    $y_height = 288;
  }
  my $tmp_psh = new File::Temp(DIR => $TMP_DIR, SUFFIX => ".ps",
			       TEMPLATE=>"PAL_WWW_XXXXXX", UNLINK => 0);

  my $tmp_psname = $tmp_psh->filename();
  print $tmp_psh $ps_out;
  close $tmp_psh;
  push @tmp_fh_list, \$tmp_psh;
  chmod 0644, $tmp_psname;

  my $url_psname = $tmp_psname;
  $url_psname =~ s%$TMP_DIR\/%%g;

  my $dopts="";
  if (ref($dopts_ref)) {
    for my $key (keys(%$dopts_ref)) {
      print STDERR "$key\t".$dopts_ref->{$key}."\n";
    }

    $dopts = "&". join("&",values(%$dopts_ref));
  }

  my $tmp_pdfname = "tmp_gs.cgi?name=$url_psname&del=no&size=6000x$y_height"."0&dev=pdf" . $dopts;

  my $gif_url="tmp_gs.cgi?name=$url_psname&del=no&size=600x$y_height&dev=png" . $dopts;
  my $output .= qq(\n<pre>$err\n</pre>\n<hr />\n);
  $output .= qq(<p /><a href="$tmp_pdfname">Click for PDF</a>\n);
  $output .= qq(<p /><a href="$tmp_pdfname"><IMG SRC="$gif_url" ALT="[PNG image]"></a>\n);
  $output .= qq(<p /><a href="$tmp_pdfname">Click for PDF</a>\n<p />\n);
}

sub check_remote_result {
  my ($q, $r_host, $remote_file, $res_file) = @_;


  my $ua = LWP::UserAgent->new;
  $ua->agent("$0");
  $ua->from('wrp@virginia.edu');

  my $r_uri = "http://".$r_host . $NODE_RUN_CGI;

#  my %rem_args =  map {($_ => $q->param($_))} $q->param();
  my %rem_args = ();
  $rem_args{'result_file'} = $remote_file;
  $rem_args{'rm'}='wait';
  $rem_args{'raw_mode'} = 1;
  $rem_args{'on_remote'} = 1;
  if (defined($q->param('hide_align')) && $q->param('hide_align')) {
    $HIDE_ALIGN = $rem_args{'hide_align'} = $q->param('hide_align');
  }
  else {
    $HIDE_ALIGN=0;
  }

  delete($rem_args{'remote_host'}); # prevent recursion
  delete($rem_args{'remote_file'});

  my $req = POST $r_uri, \%rem_args;
  my $res = $ua->request($req);

  my $remote_output = "";
  if ($res->is_success) {

    $remote_output = $res->content;
    if ($remote_output =~ m/<!-- DONE -->/ ) {
#	if (! -e "$TMP_DIR/$res_file".".res") {
	    open(RFH,">$TMP_DIR/$res_file".".res") || die "Cannot open $res_file".".res for output";
	    print RFH $remote_output;
	    close(RFH);
#	}

#	if (! -e "$TMP_DIR/$res_file".".res_DONE") {
	    open(RFH,">$TMP_DIR/$res_file".".res_DONE") ||
		die "Cannot open $res_file".".res_DONE for status";
	    print RFH `/bin/date`;
	    close(RFH);
#      }

      return 1;
    } else {
      return 0;
      # still don't have result
    }
  }
  else {
    print STDERR  $res->error_as_HTML;
    return 0;
  }
  return 0;
}

sub get_remote_params {
  my ($q, $r_host, $param_file, $res_file) = @_;


  my $ua = LWP::UserAgent->new;
  $ua->agent("$0");
  $ua->from('wrp@virginia.edu');

  my $r_uri = "http://".$r_host . $NODE_RUN_CGI;

#  my %rem_args =  map {($_ => $q->param($_))} $q->param();
  my %rem_args = ();
  $rem_args{'param_file'} = $param_file;
  $rem_args{'rm'}='get_params';


  my $req = POST $r_uri, \%rem_args;
  my $res = $ua->request($req);

  my $param_output = "";
  if ($res->is_success) {
    return decode_json(uri_decode($res->content));
  }
  else {
    return 0;
  }
}

1;
