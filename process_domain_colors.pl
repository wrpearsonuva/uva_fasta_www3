
use LWP::UserAgent;
use LWP::Simple;
use File::Temp ();
use URI::Escape;
use Data::Dumper;

# this function does several (too many) things.  Originally, it was
# designed just to edit some of the domain alignment score information
# to provide coloring now, it does much more complex stuff to produce
# SVG diagrams by inserting links that access dynamically created
# domain files.

# it should be more modular

# modified in July, 2017 to allow:
# (1) check boxes for selecting sequences for next iteration
# (2) reformat -m 9B ouput to look like -m 9I
# (3) work with blastp output (with domain annots)
#

sub process_domain_colors {
  my ($run_href, $run_data_hr, $pgm, $run_output) = @_;

  my $iter_box = (defined($run_href->{iter_box}) && $run_href->{iter_box});
  my $blast_fmt = (defined($run_href->{out_fmt}) && $run_href->{out_fmt} =~ m/blast/);
  my $pssm_evalue = 1e-3;
  if (defined($run_data_hr->{pssm_eval})) {
    $pssm_evalue = $run_data_hr->{pssm_eval};
  }

# only do this if there is already some HTML in $run_output
#
  unless ($run_output =~ m/<html>/i || $run_output =~ m/<pre>/i) {
    return "<pre>\n$run_output\n</pre>\n";
  }

  @block_colors = qw( slategrey lightgreen lightblue pink cyan tan gold plum darkgreen );

# @block_colors = qw( slategrey #A6CEE3 #1F78B4 #B2DF8A #33A02C #FB9A99 #E31A1C #FDBF6F #FF7F00 );

  my ($l_descr, $h_descr) = ("","");

  my $color_sep = '\s+:\d';
  $color_sep = '~';

  my $output = "<style>\n";
  $output .= qq(.box {display: inline-block; width: 20px; height: 9px; margin: 1px;}\n);
  for (my $i=0; $i < scalar(@block_colors); $i++) {
    $output .= qq(span.c_$i { background-color:$block_colors[$i];}\n);
    $output .= qq(span.cs_$i { background-color:$block_colors[$i];font-size:xx-small;class="stripe-1"}\n);
    $output .= qq(span.v_$i { background-color:$block_colors[$i]; fill-opacity=0.5}\n);
  }

  $output .= <<EOS ;

#footer {
 position:fixed;
 left:0px;
 bottom:0px;
 height:16px;
 width:100%;
 background:tan;
 text-align:center;
 font-size:14px;
 font-family:sans-serif;
}

/* IE 6 */
* html #footer {
  position:absolute;
 top:expression((0-(footer.offsetHeight)+(document.documentElement.clientHeight ? document.documentElement.clientHeight : document.body.clientHeight)+(ignoreMe = document.documentElement.scrollTop ? document.documentElement.scrollTop : document.body.scrollTop))+'px');}

EOS

  $output .= "</style>\n";

  my $submit_string = "";
  my %prev_sel_set = ();

  my $this_iter = 1;
  if ($iter_box) {
    if ($run_data_hr->{sel_accs_list}) {
      for my $sel_acc (split(/;/,$run_data_hr->{sel_accs_list})) {
	$prev_sel_set{$sel_acc} = 1;
      }
    }

    if ($run_data_hr->{this_iter}){
      $this_iter = ++$run_data_hr->{this_iter};
    }
    else {
      $this_iter = $run_data_hr->{this_iter} = 2;
    }

    my $submit_dest = "fasta_www.pl";
    if (defined($run_href->{submit_dest} && $run_href->{submit_dest})) {
      $submit_dest = $run_href->{submit_dest};
    }

    $output .= <<EOS ;
<script type="text/javascript">
function get_sel_accs_n() {
  var checkboxes = document.getElementsByName('sel_accs_n');
  var checkboxesChecked = [];
  // loop over them all
  for (var i=0; i<checkboxes.length; i++) {
     // And stick the checked ones onto an array...
     if (checkboxes[i].checked) {
        checkboxesChecked.push(checkboxes[i].value);
     }
  }
  // Return the array if it is non-empty, or null
  var return_value = checkboxesChecked.length > 0 ? checkboxesChecked.join(';') : '';
  return return_value;
//    return checkboxesChecked;
}

function OnSubmitForm()
{
  document.myform.method ="post";
  document.myform.enctype ="multipart/form-data";
  document.myform.action = "$submit_dest";
  var sel_accs_list = get_sel_accs_n();
//  alert(sel_accs_list);
  document.getElementById("sel_accs_list_id").value = sel_accs_list;
  return true;
}
</script>

EOS

    $submit_string = qq(<input type="submit" name="input" value="next iteration: $this_iter" onclick="this.form.action='$submit_dest'; this.form.target='_self';"/>);
  }

  $output .= qq(<div id="footer"><a href="#" onclick="show_hide_class('align_class'); return false">[show/hide all alignments]</a></div>);

  # start user agent once
  my $ua = LWP::UserAgent->new();

  # if we are in IE <= 8, we (may) need a TMP file.
  my ($tmp_ann_h, $tmp_ann_name, $cl_ann_name, $tmp_ann_cnt) = (0,"","",0);

  my $inline_svg = 0;
  my $http_user_agent = $ENV{HTTP_USER_AGENT};

  # create a temporary file in case some of the domain links are too
  # long, the file contains the infomation that would be in the cgi
  # argument string.

  ($tmp_ann_h, $tmp_ann_name) =
    File::Temp::tempfile("ANN_XXXXXX", DIR => $TMP_DIR, SUFFIX => ".arg",
			 UNLINK => 0);
  ($cl_ann_name) = ($tmp_ann_name =~ m/([\w\.]+)$/);
  # }

  my @lines = split(/\n/,$run_output);

  my $display_type = 'inline';
  if ($HIDE_ALIGN) {
    $display_type = 'none';
  }

  my ($curr_id, $id_l, $id_a) = ("","","");

  my ($box_cnt, $submit_cnt) = (0,0);

  my $mod_cgi_pgm = "";
  my $m9B_result = 0;
  my ($in_result_list, $in_align) = (0,0);

  for my $line (@lines) {
    my $output_done = 0;
    if ($line =~ m/^#/) {	# FASTA command line invocation
      chomp($line);

      $line =~ s/</&lt;/g;
      $line =~ s/>/&gt;/g;
      $line .= "<br />\n";
      # $line = qq(<pre>$line</pre>\n);
      $output .= $line;
      next;
    }

    if ($line =~ m/^The best scores/ || $line =~ m/^Sequences producing significant alignments:/) {
      $in_result_list = 1;
      if ($line =~ m/^Sequences producing/) {
	$blast_fmt = 1;
	$output .= "$line\n";
	next;
      }

      # edit line if is from -m 9B instead of -m 9I
      if ($line =~ m/\t/) {
	$m9B_result = 1;
	my @title_parts = split(/\t/,$line);
	$title_parts[0] =~ s/<!--\s*$//;
	$line = $title_parts[0] . ' %_id  %_sim  alen'."\n";
	## $line =~ s/are: {10}/are:/;
	$line =~ s/are:  /are:       /;
      }

      if ($iter_box) {
# these no longer used because getting from json_parms
#	my $result_file = $run_data_hr->{result_file};
#	my $this_query_info = $run_data_hr->{query_seq};
#	my $this_lib_info = $run_data_hr->{lib_abbr};
	$submit_cnt++;
	$output .= '</pre>';
	$output .= qq(<form name="myform" action="" enctype="multipart/form-data" onsubmit="return OnSubmitForm();">);
	$output .= <<EOS ;
<input type="hidden" id="sel_accs_list_id" name="sel_accs_list" value="-" />
EOS

	if ($run_data_hr) {
	  # make sure no on-remote
	  if ($run_data_hr->{on_remote}) {
	    $run_data_hr->{on_remote} = 0;
	  }

#	  print STDERR Data::Dumper->Dump([$run_data_hr]);
	  for my $q_param ( keys(%$run_data_hr)) {
	    my $value = $run_data_hr->{$q_param};
	    my $uri_value = $value;
	    if ($value) {
		$uri_value=uri_escape($value);
	    }
	    else {
		$uri_value="";
	    }
	    my $hidden_var = qq(<input type="hidden" name="$q_param" value="$uri_value" />);
	    $output .=  $hidden_var;
	  }
	}
	$output .= $submit_string . qq(<a href="#last_sig">Jump to last significant match</a>)."<hr />";
	$output .= "<pre>";
	# include some arguments for next iteration
	$output .= $line;
      }
      next;
    }

    if ((!$blast_fmt && $line =~ /^<\/pre>/) || $line =~ m/^>/) {
      $in_result_list = 0;
      $in_align = 1;
#      $output .= $line;
#      next;
    }

    # code to add domain color blocks to search score summary
    # edit summary line if -m 9B

    if ($in_result_list) {
    # have a score summary line
    # sp|P20432|GSTT1_DROME ... <font color="darkred">6.4e-104</font> 1.000 1.000  209 <a href="#sp|P20432">align</a> dom1;dom2;G35T;dom3

      my ($const_line, $btop_line, $mod_line, $acc, $s_seqid) = ("","","","","");
      if ($m9B_result) {   # need to reformat line:
	my @res_fields = split(/\t/,$line);
	$const_line = $res_fields[0];
	$btop_line = $res_fields[2];
	$s_seqid = (split(/\s+/,$const_line))[0];
	$const_line =~ s/ {10}\(/(/;
	($acc) = ($const_line =~ m/^(\w+\|\w+)\|/);
	if (scalar(@res_fields) >= 2 ) { # const_line, m9B fields, BTOP, ANNOT_STR
	  my %m9B_fields = ();
	  @m9B_fields{qw(pid psim sw alen)} = split(/\s+/,$res_fields[1]);

	  $const_line .= " " . join(" ",@m9B_fields{qw(pid psim alen)});
	  $const_line .= qq( <a href="#$acc">align</a>);

	  my @annots = ();
	  if ($res_fields[-1] =~ m/\|/) {
	    @annots = split(/\|/,$res_fields[-1]);
	    if (@annots) { shift @annots;}  # skip blank
	  }
	  my @dom_list = ();
	  for $ann (@annots) {
	    my ($dom) = ($ann =~ m/;C=(.+)$/);
	    push @dom_list, $dom;
	  }
	  $mod_line .= join(";",@dom_list) if (@dom_list);
	}
      }
      elsif ($blast_fmt) {
	chomp($line);
	if (! $line) {
	  $output .= "\n";
	  next;
	}
	else {
	  my @bl_out_fields = split(/\s+/,$line);
	  $const_line = $line;
	  if ($bl_out_fields[-1] =~ m/;/) {
	    $mod_line = $bl_out_fields[-1];
	    $const_line =~ s/ \Q$mod_line\E$//;
	  }
	}
      }
      else {
	($const_line, $mod_line) = split(/<\/a> /,$line);
	$const_line .= "</a> ";
      }

      my $box_html = "";
      if ($iter_box) {
	my ($evalue) = ($const_line =~ m/red">([^<]+)</);
	my $check_status = '';

	if ($evalue && $evalue <= $pssm_evalue) {
	  $check_status = 'checked';
	}
	else {
	  if ($submit_cnt == 1) {
	    $output .= "</pre><hr />".qq(<a name='last_sig' />) .$submit_string."  $box_cnt significant matches<hr /><pre>";
	    $submit_cnt++;
	  }
	}
	my $res_name = "sel_accs_$box_cnt";
	$res_name = "sel_accs_n";
	$box_cnt++;
	$box_html = qq(<input type='checkbox' id='sel_accs' name='$res_name' value='$s_seqid' $check_status />);
	unless ($prev_sel_set{$s_seqid}) {
	  $box_html .= "&nbsp;<font color='red'>+</font>&nbsp;"
	}
	else {
	  $box_html .= "&nbsp;&nbsp;&nbsp;"
	}
      }

      my @annots = ();
      if ($mod_line) {
	  @annots = split(/;/,$mod_line);
      }

      my @new_annots = ();
      my @vars = ();
      for $annot ( @annots ) {
	unless ($annot =~ m/^[A-Z]\d+[A-Z]$/) {  # its a variant
	  my $color_num = 0;
	  next if $annot =~ /NODOM/;
	  next if $annot =~ /^v/;
	  # unless (defined($domain_colors{$annot})) {
	  #   push @domains, $annot;
	  #   $domain_colors{$annot} = $color_index++;
	  #   $color_index = 1 if ($color_index > 8);
	  # }
	  my ($tmp_color) = ($annot =~ m/~([X\d]+)v?$/);
	  if ($tmp_color =~ m/X/) {
	    $tmp_color = 'slategrey';
	  }
	  else {
	    $tmp_color = ($tmp_color % scalar(@block_colors));
	  }
	  # $tmp_color = $block_colors[$tmp_color];
	  $annot = qq(<span class='cs_$tmp_color'>&nbsp;&nbsp;&nbsp;&nbsp;</span>);
	  push @new_annots, $annot;
	}
	else {
	  push @vars, $annot;
	}
      }
      if ($const_line) {
	$output .= $box_html . $const_line . "&nbsp;". join(' ',@new_annots);
	if (@vars) {
	  $output .= " ".join(';',@vars);
	}
	if ($btop_line) {
	    $output .= qq(<!-- BTOP="$btop_line" -->);
	}
	$output .= "\n";
      }
      next;
    }

    if ($submit_cnt == 2 ) {    # only happens if $iter_box
      $output .= "<hr />".$submit_string . qq(<a href="#last_sig">Jump back to last significant match</a>);
      $submit_cnt++;
      $output .= qq(</form>\n);
    }

    # here is the SVG that produces the domain diagram
    if ($in_align) {
      if ($line =~ m/^\s*<object/) {
	# extract cgi program name from <object> element into $data_str
	my ($data_str, $width, $height) =
	  ($line =~ m/data="(\S+)"\s+width="(\d+)"\s+height="(\d+)"\s*>/);

	if ($l_descr) {
	  $data_str .= "&amp;l_descr=". uri_escape($l_descr);
	}

	if ($h_descr) {
	  $data_str .= "&amp;hscores=". uri_escape($h_descr);
	  $h_descr = '';
	}

	$mod_cgi_pgm = $data_str;

	# if the argument for the SVG is too long, put it in a file
	if (length($line) + length($l_descr) + length($h_descr) > 2000) {
	  my ($cgi_pgm, $arg_str) = split(/\?/,$data_str);

	  if ($inline_svg) { # it is not clear that $inline_svg is ever non-zero
          # $cgi_pgm = "http://localhost/fasta_www3/" . $cgi_pgm;
	    $cgi_pgm = $cgi_pgm;
	    my $request = HTTP::Request->new( POST => $cgi_pgm);
	    $request->content_type('application/x-www-form-urlencoded');
	    $arg_str =~ s/&amp;/&/g;
	    $arg_str .= '&svg_only=1';
	    $request->content($arg_str);

	    my $svg_obj = $ua->request($request)->content;
	    #      $line .= qq(<object type="image/svg+xml" data="$svg_obj" width="$width" height="$height"></object>\n);
	    $output .= "$svg_obj";
	    my $gff_link = $link_mod_cgi_pgm;
	    $gff_link =~ s/domain7\.pl/domain_gff.pl/;

	    $output .= qq(<a href="$link_mod_cgi_pgm" target='svg_win'>[Domains]</a><a href="$gff_link" target='gff_win'>[GFF]</a>\n);
	    next;
	  }
	  else {		# this is the only branch ever used
	    $tmp_ann_cnt++;
	    $tmpfile_pos = tell($tmp_ann_h);
	    print $tmp_ann_h $tmp_ann_cnt.":::"."$arg_str\n";

	    $mod_cgi_pgm = $cgi_pgm . "?file=$cl_ann_name&amp;offset=$tmpfile_pos&amp;a_cnt=$tmp_ann_cnt";
	    my $link_mod_cgi_pgm = $mod_cgi_pgm . "&amp;mag=1.5&amp;no_embed=1";
	    $output .= qq(<object type="image/svg+xml" data="$mod_cgi_pgm" width="$width" height="$height"></object>);
	    my $gff_link = $link_mod_cgi_pgm;
	    $gff_link =~ s/domain7\.pl/domain_gff.pl/;
	    $gff_link .= '&amp;bed_fmt=1';

	    $output .= qq(<a href="$link_mod_cgi_pgm" target='svg_win'>[Domains]</a><a href="$gff_link" target='svg_win'>[BED]</a>\n);

	    # check here to see if $tmpfile_pos > 1024*1024.  If so,
	    # create a new tmp_file and start writing to it.
	    # do not reset $tmp_ann_cnt

	    # if ($tmp_file_pos > 16*1024*1024) {
	    #   ($tmp_ann_h, $tmp_ann_name) =
	    #     File::Temp::tempfile("ANN_XXXXXX", DIR => $TMP_DIR, SUFFIX => ".arg",
	    # 			   UNLINK => 0);
	    #   ($cl_ann_name) = ($tmp_ann_name =~ m/([\w\.]+)$/);
	    # }

	    next;
	  }
	} else {
	  $line =~ s/\n$//s;
	  my $link_mod_cgi_pgm = $mod_cgi_pgm . '&amp;mag=1.5&amp;no_embed=1';
	  my $gff_link = $link_mod_cgi_pgm;
	  $gff_link =~ s/domain7\.pl/domain_gff.pl/;
	  $gff_link .= '&amp;bed_fmt=1';

	  $line .= qq(<a href="$link_mod_cgi_pgm" target='svg_win'>[Domains]</a><a href="$gff_link" target='svg_win'>[BED]</a>\n);
	}
      }

      if ($line =~ m/^(.*)<!-- ALIGN_START/) {
	$output .= $1;
      }
      if ($line =~ m/<!-- ALIGN_START "([^"]+)" -->/) {
	$curr_id = $1;
	$id_l = $curr_id. "_l";
	$id_a = $curr_id. "_a";
	#      if ($mod_cgi_pgm) {
	#	  $output .= qq(<a href="$mod_cgi_pgm" target='svg_win'>[Domain SVG]</a>);
	#      }
	$output .= qq(<a id="$id_l" href="#$curr_id" onClick="show_hide('$id_a'); return false">[alignment]</a>);
	$output .= qq(\n);
	$output .= qq(<div id="$id_a" class='align_class' style='display:$display_type'>);
	next;
      }
      elsif ($line =~ m/^<!-- ALIGN_STOP -->/) {
	$output .= "</div>";
	$mod_cgi_pgm = "";
	next;
      }

      # no /^/ here because first domain has <pre>..Region...
      if ($line !~ m/\s*q?Region:\s/) {
	# capture library description line
	if ($line =~ m/<a name=/) {
	  $l_descr = $line;
	  $l_descr =~ s/^.*<a name=.*><pre>>>/>>/;
	} elsif ($line =~ m/<!-- ANNOT_STOP -->(.*)$/ ) {
	  $h_descr = "$1\n";
	} elsif ($line =~ m/ score: \d+;\s+\d+\.?\d*% identity \(/ ) {
	  $h_descr .= "$line\n";
	}
	$output .= "$line\n";
      } 
      else {	# in '^ Region: 
	unless ($line =~ m/$color_sep\d+v?$/) {
	  $output .= "$line\n";
	}
	else {		# have ^ Region: ..... :\d+$
	  ## here we choose how to highlight, and can choose not to display
	  # if it's NODOM{0}~0, then need to check for significance
	  my $nodom_color=$color_sep."0";
	  ## only happens for NODOM
	  if ($line =~ m/Q=(\d+\.\d+) :\s+NODOM\{0\}~0$/) {
	    my $qval = $1;
	    if ($qval < 30.0) {
	      $line =~ s/:\s+NODOM\{0\}~0/: NODOM/;
	      $output .= "$line\n";
	    } else {		# significant match, add color
	      $line =~ s/:\s+NODOM\{0\}~0/: <span class="c_0">NODOM<\/span>/;
	      $output .= "$line\n";
	    }
	  }
	  else { # not NODOM, have a domain, color it
	    ## next regexp captures everything before last ' : ' (prefix), domain_info, and color
	    my ($prefix, $domain_info,$color) = ($line =~ m/(.+ :\s+)(.*)$color_sep(\d+v?)$/);

	    my ($qval) = ($prefix =~ m/Q=(\S+)\s/);

	    my $domain_acc = "";
	    ## extract {acc} from $domain_info, could be genome coordinates
	    if ($domain_info =~ m/^(.+)\{(.+)\}/) {
	      $domain_info = $1;
	      $domain_acc = $2;
	    }

	    $domain_acc = $domain_info if ($domain_info =~ m/^PF/);
	    $domain_acc = $domain_info if ($domain_info =~ m/^IPR/);

	    my $color_set="c_";
	    if ($color=~ m/v$/) {
	      $color =~ s/v$//;
	      $color_set="v_";
	    }

	    $color = $color % 9;

	    ## here we should only do this when desired -- skip for exons with good qvalues if asked
	    ##
	    unless ($run_data_hr->{HIDE_EXONS} && $qval > 30.0 && $domain_info =~ m/exon/i) {
	      $output .= "$prefix" . qq(<span class=).$color_set.$color.qq(> $domain_info</span>);
	      if ($domain_acc && $domain_acc =~ m/^v?PF/) {
		$output .= qq(&nbsp;&nbsp;<a href="$PFAM_FAM_URL/$domain_acc" target='domain_win'>Pfam</a>);
	      } elsif ($domain_acc && $domain_acc =~ m/IPR/) {
		$output .= qq(&nbsp;&nbsp;<a href="$IPRO_FAM_URL/$domain_acc" target='domain_win'>InterPro</a>);
	      }
	      $output .= "\n";
	    }
	  }
	}
      }
    }

    # edit ' < ' inside descriptions.
    # $line =~ s/ < / &lt; /g;

    else {
      $output .= "$line\n";
    }
  }

  if ($tmp_ann_h) {
    close $tmp_ann_h;
    chmod 0644, $tmp_ann_name;
  }

  return $output;
}

1;
