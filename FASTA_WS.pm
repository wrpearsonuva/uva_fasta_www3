
# $Id: FASTA_WS.pm 35 2009-10-28 18:29:25Z wrp $
# $Revision: 52 $

package FASTA_WS; use base 'CGI::Application';

use CGI::Carp;

use HTML::FillInForm;
use HTML::Entities;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use LWP::Simple;
use File::Temp ();
use IO::Scalar;
use IPC::Run qw(timeout);
use Text::ParseWords;

use vars qw( $DEF_UNLINK $OK_CHARS $ALT_HOST_CGI $HOST_NAME $CGI_DIR $SQL_DB_HOST
	     $RUN_URL $SS_ALT_HOST_CGI $SS_HOST_NAME $SS_CGI_DIR
	     $WS_RUN_URL $BIN_DIR @NODE_HOSTS $NODE_EXT $NODE_RUN_CGI
	     $USE_REMOTE $DEBUG $FAST_LIBS $FAST_GNMS $TMP_DIR
	     $LOG_DIR $TMP_ROOT $GS_BIN $BL_BIN_DIR $BL_DB_DIR
	     $BL_DB_NT_DIR $BL_DATA_DIR $fa_footer);

use vars qw( $search_url_cgi $search_url1_cgi );

require "./fawww_defs.pl";
require "./fawww_subs.pl";

# variables defined in fawww_pgms.pl
#
use vars qw( @pgm_flist @pgm_slist @pgm_hlist @pgm_blist @blp_list @ws_list
	     @pgm_mlist @pgm_shuff_list @pgm_lalign_list
             %form_list %run_list %pgm_dev %pgm_opt
	     %page_link_list %page_links $r_host $c_host );

# variables defined in fawww_libs.pl
#
use vars qw( @lib_p @lib_n @lib_pg @lib_ng );
use vars qw( %smatrix_vals %bmatrix_vals);
use vars qw( @pgm_pssmlist %pgm_pssm_br);

require "./fawww_libs.pl";
require "./fawww_pgms.pl";
require "./fawww_ws_subs.pl";

use vars qw( @tmp_fh_list );

use strict;

sub cgiapp_init {
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

# get the template
#
  my $tmpl = $self->load_tmpl($form_href->{tmpl});

  ($r_host, $c_host) = get_hosts($self);
  $tmpl->param( R_HOST => $r_host);
  $tmpl->param( C_HOST => $c_host);

# the next three functions, which load the links to other programs,
# the other TMPL_VAR's specific to the form/runmode, and the libraries
# (if necessary), are not affected by input arguments.

# load up links to other programs at top of page
#
  load_links($form_name, $tmpl);

# load various other TMPL_VAR's for form
#
  load_vars($form_href->{outputs}, $tmpl);

# load the selection of library names
#
  load_library($form_href, $tmpl);

# the next functions change the form depending on input arguments
#
  my $q = $self->query();

# load the list of program selection list
#
  my $pgm_sel = $q->param("pgm") || $form_href->{pgm_def};
  prog_ws_list($q, $tmpl, $form_href->{pgm_ref}, $pgm_sel);

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
  }
  else {
    $search_url_cgi= "";
    $search_url1_cgi= "";
  }

  if ($tmpl->query('name' => 'SEARCH_URL')) {
    $tmpl->param( SEARCH_URL => $RUN_URL);
  }

# get alternative search site
#
  if ($tmpl->query('name' => 'SSEARCH_URL')) {
    if ($SS_ALT_HOST_CGI) {
      $tmpl->param( SSEARCH_URL => $SS_HOST_NAME . "$SS_CGI_DIR/$WS_RUN_URL");
    }
    else {
      $tmpl->param( SSEARCH_URL => $WS_RUN_URL);
    }
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

  if ($DEBUG) {
      return $self->dump_html() . "\n" . $tmpl->output();
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

use vars qw($query $query_info $lib_val $lib_info $pgm $pgm_title);
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

# get session info for saving search information
#
  # get the program specific mode 
  if ($run_href->{indirect}) {
    unless ($q->param('pgm') &&
	    exists($run_href->{indirect}->{$q->param('pgm')})) {
	      return fasta_error("Indirect run parameters undefined for $run_mode\n");
	    }
    else {
      $run_mode = $run_href->{indirect}->{$q->param('pgm')};
      $run_href = $run_list{$run_mode};
    }
  }

  if ($run_href->{can_remote} && $q->param('remote')) {
      $q->param('rem_rm' => $run_mode);
      return remote($self);
  }

#################################################################
# at this point, we are going to process the request
################################################################
  use vars qw($output $q2_tmp_name $err);

  my ($r_host, $c_host) = get_hosts($self);
  $pgm = $q->param("pgm");
  $DEBUG = $q->param("DEBUG");

# set default sq_type
  my $n_queries = $run_href->{n_q};
  if (exists $run_href->{sq_type}) {$q->param('sq_type',$run_href->{sq_type});}

# build list of valid program name arguments ($q->param("pgm"))
  my ($pgm_href) = grep { $_->{pgm} eq $pgm }  @{$run_href->{pgm_ref}};

# get program info
#
  unless (defined($pgm_href)) {
    $output = fasta_error("program: $pgm not found");
    if ($DEBUG) {$output .= $self->dump_html();}
    return $output;
  }

  $pgm_title = $pgm_href->{title};

# get database types
  my ($query_db, $query2_db) = get_dbs($q,$pgm, ($pgm_href->{q_sq} == $pgm_href->{l_sq}));

#  print STDERR "query_db/l_db: $query_db / $query2_db\n";

  my %ws_opts = get_ws_opts_byref($q, $run_href, "opts");

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
  unless ($query) {
    if ($q->cgi_error) { $output = $q->cgi_error;}
    $output .= fasta_error("$query_db: ".$q->param("query")."  not found");
    if ($DEBUG) {$output .=  $self->dump_html();}
    return $output;
  }

  ($query_info) = ($query =~ m/^>(.{1,60})/m);

  if ($DEBUG) {
      $output .= "<pre>$query_db - ".$q->param("query") . "\n$query\n</pre>\n<hl>\n";
  }

  my $query_str = "\@";
  my $query_range = "";

#
# neet a tmp file for query1
#
 if ($run_href->{ws_query1_type} && $run_href->{ws_query1_type} eq 'tmp') {
    my $tmp_fh = new File::Temp(DIR=>$TMP_DIR,
			     TEMPLATE=>"FA_WWW_XXXXXX",
			     SUFFIX => ".q",
			     UNLINK => $DEF_UNLINK);
    chmod 0644, $tmp_fh->filename();
    $query_str = $tmp_fh->filename();
    print $tmp_fh $query . "\n";
    close $tmp_fh;
    push @tmp_fh_list, \$tmp_fh;
    $query = "";
  }

  if ($run_href->{have_ssr}) {
      if ((defined $q->param('ssr_flag') && $q->param('ssr_flag')) &&
	  $q->param('ssr')) {
	  $query_range = get_safe_range("", $q->param('ssr'));
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
      $query_range2 = get_safe_range("", $q->param('ssr2'));
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
      $query_range2 = get_safe_range("", $q->param('ssr2'));
      if ($query_range2) {
	$q2_tmp_name .= ":$query_range2";
      }
    }
  }

  if (exists $run_href->{lib_env}) {
    $ENV{'FASTLIBS'} = $run_href->{lib_env}
  }
  ;
#  if (exists $run_href->{link_url_ref}) {
#    set_url_envs($run_href->{link_url_ref});
#  }

  my $fa_pgm = $pgm_href->{binary};

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
  if ($run_href->{use_query1} || $run_href->{ws_query1_type}) { 
    my $query1_opt = (defined($run_href->{query1_opt})) ? $run_href->{query1_opt} : '';
    if ($pgm_args) {
      $pgm_args .= " ". $query1_opt . $query_str;
    } else {
      $pgm_args = $query1_opt . $query_str;
    }
  }

################
# get the library type or second file
#
  if (exists $run_href->{query2_type}) {
    if ($run_href->{query2_type} =~ m/tmp/ && $query2) {
      $pgm_args .= " $q2_tmp_name";
    } 
#
# get library type here
#
    elsif ($run_href->{query2_type} =~ m/lib/) {
      ($lib_val, $lib_info) =
	$run_href->{ws_get_lib_sub}($q,$query2_db,$run_href);
    }
    elsif ($run_href->{query2_type} eq 'q2') {
      $pgm_args .= " " . $query_str2;
      $query = "$query\n$query2\n";
    } else {
      $output = fasta_error("Program: $pgm - query2_type not found");
      if ($DEBUG) {
	$output .= $self->dump_html();
      }
      return $output;
    }
  }

  if (exists $run_href->{post_opts}) {
    my %p_opts = get_fasta_opts_byref($q, $run_href, "post_opts");
    if (values(%p_opts)) {
      $pgm_args .= join(' ', values(%p_opts));
    }
  }

  if ($DEBUG) {
    $output .= "<pre>$pgm_cmd $pgm_args\n</pre>\n";
  }

#  print STDERR join("::",@cmd_list),"\n";

  my $start_time = time();

  my $comments = get_safe_string("", $q->param("comments")) || "";
  $comments = HTML::Entities::encode($comments);
  unless ($comments) {
    $comments = "$pgm_title search started " . `/bin/date`;
  }

  $q->param(-name=>"comments", value => $comments);

################
# run it in the background
#

#    Do_log($r_host, join(":",@cmd_list) . " >" . $out_fh->filename());

################################################################
# With web services, I do not need to put a job in the background and run it.
# I simply need to submit the job to web services, and in the rm=wait mode, 
# check to see if the job has finished.  When it finishes, display the results.
################################################################
#
# dummy run to send a sequence and get a result id
#

  if ($run_href->{run_ws}) {
    my %tool_params = (%ws_opts, %{$pgm_href->{ws_opt}});

    $tool_params{sequence} = $query;
    $tool_params{database} = $lib_val;
    $tool_params{program} = $pgm_href->{ws_name};

    for my $opt (keys %tool_params) {
      delete($tool_params{$opt}) unless $tool_params{$opt};
    }

#    for my $opt (keys %tool_params) {
#      print STDERR "$opt : $tool_params{$opt}\n";
#    }

    my $job_id = rest_run('wrp@virginia.edu',$pgm_href->{title},\%tool_params);

    my $tmpl = $self->load_tmpl("wait_ws.tmpl");
    my $remote = "";

    $tmpl->param("RESULT_PGM"=>$pgm,
		 "RESULT_RM"=>$run_mode,
		 "RUN_MODE"=>"wait",
		 "DEBUG"=>$DEBUG,
		 "RID"=>$job_id,
		 "DBG_OUTPUT"=>$output,
		 "REMOTE_HOST" => "",
		 "REMOTE_FILE" => "",
		 "S_TIME"=> $start_time,
		 "E_TIME"=> 1,
		 "COMMENTS"=> $comments,
		 "REFRESH_TIME" => 1,
		 "QUERY_INFO"=>HTML::Entities::encode($query_info),
		 "LIB_INFO"=>$lib_info
	);

    return $tmpl->output();
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

  my $q = $self->query();

  my $run_mode = $q->param("result_rm") || "search";
  my $job_id = get_safe_filename($q,"RID");
  my $run_href = $run_list{$run_mode};
  unless ($run_href) {
    return fasta_error("Run parameters undefined for $run_mode\n");
  }

################
# get the parameters submitted
#

  my $status = rest_get_status($job_id);

  if ($status ne 'FINISHED') {
    $job_id = HTML::Entities::encode($job_id);

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

    my $query_info = get_safe_string("",$q->param("query_info")) || "";
    $query_info = HTML::Entities::encode($query_info);
    $q->param(-name=>"query_info", -value => $query_info);

    my $lib_info = get_safe_string("", $q->param("lib_info")) || "";
    $lib_info = HTML::Entities::encode($lib_info);
    $q->param(-name=>"lib_info", -value => $lib_info);

    my $comments = get_safe_string("", $q->param("comments")) || "";
    $comments = HTML::Entities::encode($comments);
    $q->param(-name=>"comments", -value => $comments);

    my $tmpl = $self->load_tmpl("wait_ws.tmpl");
    $tmpl->param("E_TIME"=>$elapsed_time,
		 "RID"=>$job_id,
		 "REFRESH_TIME"=>$refresh,
		 "SPACES"=>"." x $spaces,
		 "QUERY_INFO"=> HTML::Entities::encode($query_info),
		 "LIB_INFO"=> $lib_info,
		 "COMMENTS"=> $comments);
    my $html = $tmpl->output();
    my $form =  HTML::FillInForm->new();
    return $form->fill(\$html,$q);

  }

################
# here if rest_status eq "FINISHED"

  my $pgm = $q->param("result_pgm") || "fap";
  $DEBUG = $q->param("DEBUG");

  if ($DEBUG) {  $output = $q->param("dbg_output") || "";}

################
# get the file:

  my $run_output = rest_get_result($job_id, "domains-html");

  display_result($self, $run_href, $pgm,
		 $DEBUG, $output, $run_output, 0, $run_href->{ws_no_html});
}

################################################################
# status_result()  -- requires session to be working
# check session status, list all jobs running/finished from this session id
# (later) provide ability to delete (forget) old jobs
#
sub status_result {
  my $self = shift;
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

  my $q = $self->query();

  my $res_file = get_safe_filename($q,"RID");
  if ($res_file) {$res_file .= ".out";}

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
  while (<PFH>) {
    chomp;
    my ($key, $val) = split(/:/);
    $param_hash{$key} = $val;
  }
  close(PFH);

  if ($q->param('raw_mode') && $q->param('raw_mode') == 1) {
    $param_hash{'raw_mode'} = 1;
  }

  my $run_mode = $param_hash{"result_rm"}|| "search";

  unless ($run_mode) {
    return fasta_error("Undefined RUN_MODE\n");
  }

  my $run_href = $run_list{$run_mode};
  unless ($run_href) {
    return fasta_error("Run parameters undefined for $run_mode\n");
  }

  my $pgm = $param_hash{"result_pgm"};
  if ($param_hash{'remote_host'}) {
      $output = "<h3>Search on $param_hash{'remote_host'}</h3>\n";
  }

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

  display_result($self, $run_href, $pgm,
		 $DEBUG, $output, $run_output, $param_hash{"raw_mode"});
}

################################################################
# at this point we have the output
# this section needs to deal with preparing the output
#
sub display_result {
  my ($self, $run_href, $pgm, $DEBUG, $output,
      $run_output, $raw_mode, $no_html) = @_;

################
# build list of program titles for labeling output page
  my %pgm_title = map { $_->{pgm} => $_->{title}} grep {defined($_->{ws_name})} @{$run_href->{pgm_ref}};

# special code for setting up postscript output for plotting programs
#
  if ( exists $pgm_dev{$pgm} && $pgm_dev{$pgm}->{'dev'} eq 'SVG' ) {
    $output .= process_svg_out($pgm, $run_output);
  }
  elsif ( exists $pgm_dev{$pgm} && $pgm_dev{$pgm}->{'dev'} eq 'ps' ) {
    $output .= process_ps_out($pgm, $run_output);
  }
#
# here for all programs that do not have plot output
#
  else {
# check to see if program generates html output
#
    if ($no_html) {
      $output .= "<p />\n<hr /><p />\n<pre>\n$run_output\n</pre>\n";}
    else {
      $output .= $run_output;
    }

################
# remove $TMP_DIR references from output
#
    $output =~ s%$TMP_DIR\/%%g;
    $output =~ s%FA_WWW.*?\.%TMP.%g;
    $output =~ s%$BIN_DIR\/%%g;
  }

  $output .= "\n" ;

  my $footer = $run_href->{footer} || $fa_footer;

################
# need for formatting output
#
  my $q = $self->query();

  if ($DEBUG) {
    return $q->start_html("$pgm_title{$pgm} results") . "\n". 
      $self->dump_html() . "\n" .  $footer .
	"$output\n$footer" . $q->end_html() . "\n";
  }

  if ($raw_mode) { return $output; }
  else {
      return $q->start_html("$pgm_title{$pgm} results") 
	  . "<!-- DONE -->\n" . "\n$footer"
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
  my $rem_rm = $q->param('rem_rm');

  unless ($rem_rm) {
      return "<h2> no rem_rm for remote search</h2>\n". $self->dump_html() . "\n</body>\n</html>\n";
  }

  my $r_host = $q->remote_host();

# get session info for saving search information
#
  my $session = $self->session();

  my $output;

  $DEBUG = $q->param("debug");

# (1) - check for a valid program

  my @pgm_list = (@pgm_flist, @pgm_slist, @pgm_hlist, @pgm_blist);
  my %pgm_name = map { $_->{pgm} => $_->{bin} } @pgm_list;
  my %pgm_qdb_ldb = map { $_->{pgm} => ($_->{q_sq}==$_->{l_sq}) } @pgm_list;

  my $pgm = $q->param("pgm");

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

  my ($pgm_href) = grep { $pgm eq $_->{pgm}} @{$rem_href->{pgm_ref}};
  $pgm_title = $pgm_href->{title};

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
    my ($pgm_qdb_ldb) = 
      grep { ($_->{q_sq}==$_->{l_sq}) if ($_->{pgm} eq $pgm) } @{$rem_href->{pgm_ref}};
    my ($query_db, $query2_db) = get_dbs($q,$pgm, $pgm_qdb_ldb);
    ($lib_val, $lib_info) =
      $rem_href->{get_ws_lib_sub}($q,$query2_db,$rem_href);
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

  # all the other parameters (p_lib, n_lib, matrix, etc) remain the same

  my $start_time = time();

  my $comments = get_safe_string($q->param("comments")) || "";
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
  close(SFH);

  $out_filename =~ s/.res//;
  $out_filename =~ s%$TMP_DIR\/%%;

  $q->param("result_file"=>$out_filename);
  $q->param("remote_host"=>$n_host);

  my %rem_args =  map {($_ => $q->param($_))} $q->param();

  my $req;

  # I have some files, add them, and use Content_type=>form-data
  for my $rf_args(keys %rem_files) {
      $rem_args{$rf_args} = [$rem_files{$rf_args}, undef, 'Content-type' => 'application/octet-stream'];
  }
  $req = POST($n_uri, 'Content_Type' => 'form-data', 'Content' => \%rem_args);

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
				       pgm_title => $pgm_title,
				       result_rm => $rem_rm,
				       s_time => $start_time,
				       query_info => $query_info,
				       lib_info => $lib_info,
				       result_file => $out_filename,
				       comments => $comments,
				       status => 'DONE',
				      }
		     );
    }
    else {
################
# we have to wait for it
      ($remote_file) = ($remote_output =~ m/<!-- RUNNING:(\w+) -->/);
      print STDERR "running on $n_host file: $remote_file\n";

      $session->param( 'current' => $out_filename,
		     $out_filename => {
				       pgm => $pgm,
				       pgm_title => $pgm_title,
				       result_rm => $rem_rm,
				       s_time => $start_time,
				       query_info => $query_info,
				       lib_info => $lib_info,
				       result_file => $out_filename,
				       remote_file => $remote_file,
				       comments => $comments,
				       status => 'REMOTE',
				       remote_host => $n_host,
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
		  );

      return $tmpl->output();
    }

  } else {
    $output .=  $res->error_as_HTML;
  }

# (6) return the output
#  actually start the program waiting for the output
  if ($q->param("debug")) {
    return $q->start_html() . "\n". $self->dump_html() . "\n" .  $output;
  }

  return $q->start_html("search on remote $n_host") . "\n" . $output;
}

################
# produce list of programs for display in form template
#
sub prog_ws_list {

  my ($q,$tmpl,$pgm_lref,$pgm_select) = @_;

  my @search_pgm = map { { PGM_DESC => $_->{label},
			   PGM_VAL => $_->{pgm},
			   PGM_SEL => 
			       ($_->{pgm} eq $pgm_select ? "selected=\"selected\"": "")
			   }
		       } grep { defined($_->{ws_name})} @$pgm_lref;
  $tmpl->param( SEARCH_PGM => \@search_pgm);
}

################
# produce a list of databases for form template
#
sub lib_list {

  my ($tmpl,$name, $list_ref) = @_;

  my @lib_list;

  @lib_list = @$list_ref;

  my @libs = map { { LIB_DESC => $_->[0],
		     LIB_VAL => $_->[1]
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
    if (m/^([^\$]+)\$0(\w)/) {
      push @$libp_ref, [$1, $2];
    }
    elsif (m/^([^\$]+)\$1(\w)/) {
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

use vars qw( $test_aa );

sub get_query {
  my ($q, $name, $type, $file, $db )  = @_;
  my @acc_list = ();
  my $q_library = "";

  unless ($q->param($file) || $q->param($name)) {return "";}

  if ($q->param($name) =~ m/^TEST/) {
    return $test_aa;
  }

#
# file_name trumps name, but needs type
#
  if ($q->param($file)) {
    my $qfh;
    $qfh = $q->upload($file);
    unless($qfh) {return "";}

# $q->tmpFileName($qfd) contains the name of the temporary file,
# which could be used for the search, or stat'ed for size
#
    if ($q->param($type) && $q->param($type) =~ m/^acc/i) {
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
    if (($q->param($type) && $q->param($type) =~ m/^acc/i
	 && $q->param($name) !~ m/^>/ && length($q->param($name)) < 100) ||
	$q->param($name) =~ m/^gi\|/ ||
	$q->param($name) =~ m/^\s*\d+\s*$/ ) {

      my $acc_list = $q->param($name);
      $acc_list =~ s/\r//go;

      @acc_list = split(/[\n,]/,$acc_list);

      chomp(@acc_list);
    } else {		     # param($name) has sequences, return them
      my $query = $q->param($name);
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
    my $query = get_fastacmd($db, $acc);

    unless ($query) {
      $query = get_ncbi($db, $acc);
    }

    unless ($query) {
      $query = get_uniprot($db, $acc);
    }

    #      printf STDERR $query;
    $q_library .= $query;
  }
  return $q_library;
}

################
# gets database name, type from $q->param()
# returns ($lib_val, $lib_info)

sub get_lib {
  my ($q, $lib_db, $run_href) = @_;

  my ($fa_lib, $fa_file, $fa_info);
#
# set up appropriate protein or DNA library, including defaults
#
  if ($lib_db =~ /^P/i) {
    if ($q->param("p_lib")) {$fa_lib = $q->param("p_lib");}
    else {$fa_lib = "a";}
    ($fa_file, $fa_info) = scan_fastlibs($fa_lib, $run_href->{lib_env},0);
  }
  else {
    if ($q->param("n_lib")) {$fa_lib = $q->param("n_lib");}
    else {$fa_lib = "m";}
    ($fa_file, $fa_info) = scan_fastlibs($fa_lib, $run_href->{lib_env},1);
  }

  return ($fa_lib, $fa_info);
}

################
# gets database name, type from $q->param()
# returns ($lib_val, $lib_info)

sub ws_get_lib {
  my ($q, $lib_db, $run_href) = @_;

  my ($ws_lib, $ws_info);

  if ($q->param("p_lib")) {
    my $p_lib = $q->param("p_lib");
    my ($lib_ref) = grep { $_->{abbr} eq $p_lib } @{$run_href->{ws_lib_ref}};
    $ws_lib = $lib_ref->{val};
    $ws_info = $lib_ref->{info}
  }
  else {
    $ws_lib = "uniprotkb_swissprot";
    $ws_info = "UniProtKB SwissProt";
  }

  return ($ws_lib, $ws_info);
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
    if ($q->param("p_lib")) {$fa_lib = $q->param("p_lib");}
    else {$fa_lib = "a";}
    return scan_fastlibs($fa_lib, $run_href->{lib_env}, 0);
  }
  else {
    if ($q->param("n_lib")) {$fa_lib = $q->param("n_lib");}
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
  if ($q->param("p_lib")) {
    my $p_lib = $q->param("p_lib");
    my ($bl_lib_ref) =  grep { $_->[0] eq $p_lib } @blp_list;
    $bl_lib = $bl_lib_ref->{name};
    $bl_info = $bl_lib_ref->{info};
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
# 	 opts => {
# 	     eval => ["-e", \&get_safe_number],
# 	     comp_stat => ["-C 1", \&get_option, "-C 0"],
# 	     seg_filter => ["-F T", \&get_option, "-F F"],
# 	     p_lib => ["-d", \&get_blib],
# 	     gap => ["-G", \&get_safe_number],
# 	     ext => ["-E", \&get_safe_number],
# 	     smatrix => ["", \&get_bmatrix],
# 	 },

sub get_fasta_opts_byref {
  my ($q,$run_href, $opt_type) = @_;

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
  for my $opt ( keys( %{$opt_href} )) {
    my $opt_list_r = $opt_href->{$opt};
    if (defined($q->param($opt))) {
      if (ref($opt_list_r->{val}) eq 'CODE') {
	# have a function - run it
	$fa_opts{$opt} = 
	  $opt_list_r->{val}->($opt_list_r->{cmd_arg},$q->param($opt),$q, $opt);
	#  function_ref->(option{cmd_arg}, param_value, $q, param_name)
      }
      #
      #  we don't allow "this" here because we don't want to just grab unparsed
      #  input parameters
      #
      else { # no function, just fill in the value
	$fa_opts{$opt} = $opt_list_r->{cmd_arg};
      }
    } else { # no parameter entered, use default
      if ($opt_list_r->{default_arg}) {
	$fa_opts{$opt} = $opt_list_r->{default_arg};
      }
    }
  }
  return %fa_opts;
}

sub get_ws_opts_byref {
  my ($q, $run_href, $opt_type) = @_;

  my %ws_opts = ();

  # return of no options specified in structure
  return () unless $run_href->{$opt_type};

  # point to the option hashref
  my $opt_href = $run_href->{$opt_type};

  ################
  # keys ( %{$option_href} are the possible $q->param() names
  # an alternative strategy would look at $q->param() in the list context,
  # but this would make default parameters more challenging
  #
  for my $opt ( keys( %{$opt_href} )) {
    my $opt_list_r = $opt_href->{$opt};
    if (defined($q->param($opt))) {
      if (defined($opt_list_r->{ws_arg})) {
	if (ref($opt_list_r->{val}) eq 'CODE') {
	  # have a function - run it
	  $ws_opts{$opt_list_r->{ws_arg}} = $opt_list_r->{val}->($opt_list_r->{cmd_arg},$q->param($opt),$q, $opt);
	  #  function_ref->(option{cmd_arg}, param_value, $q, param_name)
	  $ws_opts{$opt_list_r->{ws_arg}} =~ s/\-\w\s*//;
	}
      }
      elsif (defined($opt_list_r->{ws_flag})) {
	$ws_opts{$opt_list_r->{ws_flag}} = 'true';
      }
      #
      #  we don't allow "this" here because we don't want to just grab unparsed
      #  input parameters
      #
      else { # no function, just fill in the value
	$ws_opts{$opt} = $opt_list_r->{cmd_arg};
      }
    } else { # no parameter entered, use default
      if ($opt_list_r->{default_arg}) {
	$ws_opts{$opt} = $opt_list_r->{default_arg};
      }
    }
  }
  return %ws_opts;
}

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
  my $matrix_str = "";

  if ($p_arg) {
      if ($p_arg > 0 && $p_arg < 5 && exists $bmatrix_vals{$p_arg}) {  
	  $matrix_str = "-M ".$bmatrix_vals{$p_arg};
      }
      else { $matrix_str = "";}
  }    
  else { $matrix_str = "";}
  return $matrix_str;
}

sub get_smatrix {
  my ($opt, $p_arg) = @_;
  my $matrix_str = "";

  if ($p_arg) {
      if ($p_arg >= 10 && $p_arg <= 13) {
	  $matrix_str = "-r ".$smatrix_vals{$p_arg};
      }
      elsif ($p_arg >= 0 && $p_arg <= 9) {  
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
      return get_safe_range("", $q->param($param));
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
      return get_safe_range("-M", $q->param($param));
  }
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
    print STDERR "p_arg - missing: $opt\n";
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

  my $n_uri = "http://www.ncbi.nlm.nih.gov/BLAST/Blast.cgi";

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

sub get_remote_files {
  my ($rem_list_r, $q) = @_;

  my %rem_files=();

  for my $r_arg ( keys %$rem_list_r ) {
    if ($q->param($r_arg)) {
      my $file = $rem_list_r->{$r_arg}->[0]("%s", $q->param($r_arg), $q, $r_arg);
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

  my $gnm_str = shift;

  $ENV{'REF_URL'} = qq(<a href="http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=%s&amp;cmd=Search&amp;term=%s&amp;doptcmdl=DocSum">Entrez Lookup</a>&nbsp;&nbsp;);

  $ENV{'SRCH_URL'} = qq(<a href="$search_url_cgi?rm=search$gnm_str&amp;query=%s&amp;db=%s&amp;lib=%s&amp;pgm=%s&amp;start=%ld&amp;stop=%ld&amp;n1=%d\">Re-search database</a>&nbsp;&nbsp;);

  $ENV{'SRCH_URL1'} = qq(<a href="$search_url1_cgi?rm=select$gnm_str&amp;query=%s&amp;db=%s&amp;lib=%s&amp;pgm=%s&amp;start=%ld&amp;stop=%ld&amp;n1=%d\">General re-search</a>&nbsp;&nbsp;);

}

#
# for programs where query and library database match, put 1 
#
sub get_dbs {
  my ($q, $pgm, $qdb_ldb) = @_;
  my ($q_db, $l_db);
  my @db_names = ("Protein", "DNA");

  # if we have param("db"), ignore param("sq_type") 

  if ($q->param("db")) { $q_db = $q->param("db"); }
  else {
    if ($q->param("sq_type") && $q->param("sq_type") > 1) {
      $q_db = "DNA";
    }
    else { $q_db = "Protein";}
  }

  if ($qdb_ldb) {
    $l_db = $q_db;
  }
  else {
    $l_db = ($q_db =~ m/^P/i) ? "DNA" : "Protein";
  }

  return ($q_db, $l_db);
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
	    { LINK => qq[<a href="$page_links{$pgm}->{link}"><font size="+1">$page_links{$pgm}->{desc}</font></a>],
	      ROWS => ($first_row ? $tbl_rows : 0),
	      TEXT => $page_link_list{$form}->[1]
	      };
	}
	$first_row = 0;
    }
    $tmpl->param(LINKS_LIST => \@tbl_list);
}

sub load_library {
  my ($form_href, $tmpl) = @_;

  if ($tmpl->query('name' => 'LIB_P')) {
    if ($form_href->{ws_lib_list}) {
      my @libs = map { {LIB_DESC => $_->{desc}, LIB_VAL => $_->{abbr} } } @{$form_href->{ws_lib_list}};
      $tmpl->param( LIB_P => \@libs);

      if ($tmpl->query('name' => 'LIB_N')) {
	  lib_list($tmpl, "LIB_N", [["",""]]);
      }
    }
    elsif ($form_href->{lib_env}) {
      my @lib_fp = ();
      my @lib_fn = ();
      fast2libs($form_href->{lib_env}, \@lib_fp, \@lib_fn);
      lib_list($tmpl, "LIB_P", \@lib_fp);
      if ($tmpl->query('name' => 'LIB_N')) {
	  lib_list($tmpl, "LIB_N", \@lib_fn);
      }
    }
  }
}
################################################################
# check_remote_result($host, $remote_file, $result_file)
#
# load page from $r_host/$NODE_RUN_CGI with:
#   result_file=$remote_file
#   rm='wait'
#   raw_mode='1'
#  with rm=wait, the web site checks the status of result_file, 
#  if result_file contains <!-- DONE -->, it also has the results
#  otherwise keep waiting
#
################################################################
#
sub check_remote_result {
  my ($r_host, $remote_file, $res_file) = @_;

  my $ua = LWP::UserAgent->new;
  $ua->agent("$0");
  $ua->from('wrp@virginia.edu');

  my $r_uri = "http://".$r_host . $NODE_RUN_CGI;

#  my %rem_args =  map {($_ => $q->param($_))} $q->param();
  my %rem_args = ();
  $rem_args{'result_file'} = $remote_file;
  $rem_args{'rm'}='wait';
  $rem_args{'raw_mode'} = 1;
#
#  this has no purpose
#  delete($rem_args{'remote_host'}); # prevent recursion
#  delete($rem_args{'remote_file'});

  my $req = POST $r_uri, \%rem_args;
  my $res = $ua->request($req);

  my $remote_output = "";
  if ($res->is_success) {

    $remote_output = $res->content;
    if ($remote_output =~ m/<!-- DONE -->/) {
      open(RFH,">$TMP_DIR/$res_file".".res") ||
	die "Cannot open $res_file".".res for output";
      print RFH $remote_output;
      close(RFH);

      open(RFH,">$TMP_DIR/$res_file".".res_DONE") ||
	die "Cannot open $res_file".".res_DONE for status";
      print RFH `/bin/date`;
      close(RFH);
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

1;
