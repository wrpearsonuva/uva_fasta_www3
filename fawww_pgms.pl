#
# $Id: fawww_pgms.pl 35 2009-10-28 18:29:25Z wrp $
# $Revision: 187 $
#

# this set of lists and hashes defines most of the behavior of the
# different run modes.  There are two major functions in
# fasta_www.cgi/FASTA_WWW.pm, do_form() and do_search().
#
# The pages presented by do_form() are defined by %form_list{},
# %page_links{}, and %page_link_list;
#
# The pages produced by do_search() are defined by %run_list{} with help
# from %fa_opt_params{} and %pgm_dev{}
#

#
# in-line text for %form_list and $pgm_link_list;
#
require "./fawww_defs.pl";
require "./fawww_pgm_text.pl";
require "./process_domain_colors.pl";

# %form_list{form_name} provides the information required by do_form()
# to produce an input/selection form from a template.
#
# form_list->{form_name} = {
#      tmpl => template_file,
#      pgm_ref => [list of programs to be selected from],
#      pgm_def => "default_program",
#      "inputs" sets template vars in form from input parameters
#      inputs => { arg1 => {TMP_VAR1 => value, TMP_VAR2 => \&value_func, ...},
#
#      inp_dep_list => [ array of required parameters with dependencies]
#      e.g. in mselect, the query can be derived from the msa_query
#      inp_deps => { param_name => { "alt_param_name", \&trans_func()},...}
#      outputs => { TMPL_VAR1 => value, ...}
#      every template should get a RUN_MODE
#

my $pfam_qfo_db="pfam37_qfo";
my $pfam_db="pfam37";
my $db_host= $SQL_DB_HOST;
my $neg_opt='';
my $vdom_opt='';

@annot_seq1_arr = ("", "",
	 qq(-V 'q\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment'), 		#2
	 qq(-V 'q\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment+--no_mod'), 	#3
	 qq(-V 'q\!./annot/ann_upfeats_pfam_www_e.pl+--host=$db_host+$neg_opt$vdom_opt--acc_comment'),	#4
	 qq(-V 'q\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment+--no-feats'),	#5
	 qq(-V 'q\!./annot/ann_pfam_www2.pl+$neg_opt$vdom_opt--acc_comment'),			#6
	 qq(-V 'q\!./annot/ann_pfam_www2.pl+$neg_opt--pfacc$vdom_opt--acc_comment'),		#7
	 qq(-V 'q\!./annot/ann_pdb_cath.pl+--host=$db_host+--neg'),				#8
	 qq(-V 'q\!./annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),			#9
	 qq(-V 'q\!./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc+--db=RPD3+--vdoms'),	#11
	 qq(-V 'q\!./annot/ann_pdb_vast.pl+--host=$db_host+--neg'),				#11
	 qq(-V 'q\!./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc+--db=RPD3+--vdoms'),	#12  RPD3
	 qq(-V 'q\!./annot/ann_exons_ncbi.pl+--host=$db_host'),				#13  ncbi_exons
	 qq(-V 'q\!./annot/ann_exons_up_www.pl'),				#14
	);

@annot_seq2_arr =
	("", "",
	 qq(-V '\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment'), 		#2
	 qq(-V '\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment+--no_mod'), 	#3
	 qq(-V '\!./annot/ann_upfeats_pfam_www_e.pl+--host=$db_host+$neg_opt$vdom_opt--acc_comment'),	#4
	 qq(-V '\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment+--no-feats'),	#5
##	 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+--db=$pfam_qfo_db+$neg_opt$vdom_opt--acc_comment'),			#6
##	 qq(-V '\!./annot/ann_pfam_www2.pl+$neg_opt$vdom_opt--acc_comment'),			#6
	 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+--db=$pfam_qfo_db+$neg_opt$vdom_opt--acc_comment'),		#6
	 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+--db=$pfam_qfo_db+$neg_opt$vdom_opt--acc_comment'),		#7
	 qq(-V '\!./annot/ann_pdb_cath.pl+--host=$db_host+--neg'),				#8
	 qq(-V '\!./annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),			#9
	 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc+--db=RPD3+--vdoms'),	#11
	 qq(-V '\!./annot/ann_pdb_vast.pl+--host=$db_host+--neg'),				#11
	 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc+--db=RPD3+--vdoms'),	#12  RPD3
	 qq(-V '\!./annot/ann_exons_ncbi.pl+--host=$db_host'),				#13  ncbi_exons
	 qq(-V '\!./annot/ann_exons_up_sql.pl+--host=$db_host'),				#14
	);

@bl_annot_seq2_arr =
	("", "",
	 qq(--ann_script='/annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment'), 		#2
	 qq(--ann_script='/annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment+--no_mod'), 	#3
	 qq(--ann_script='/annot/ann_upfeats_pfam_www_e.pl+--host=$db_host+$neg_opt$vdom_opt--acc_comment'),	#4
	 qq(--ann_script='/annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment+--no-feats'),	#5
	 qq(--ann_script='/annot/ann_pfam_sql.pl+--host=$db_host+--db=$pfam_qfo_db+$neg_opt$vdom_opt--acc_comment'),			#6
	 qq(--ann_script='/annot/ann_pfam_sql.pl+--host=$db_host+--db=$pfam_qfo_db+$neg_opt--pfacc+$vdom_opt--acc_comment'),		#7
	 qq(--ann_script='/annot/ann_pdb_cath.pl+--host=$db_host+--neg'),				#8
	 qq(--ann_script='/annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),			#9
	 qq(--ann_script='/annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc+--db=RPD3+--vdoms'),	#11
	 qq(--ann_script='/annot/ann_pdb_vast.pl+--host=$db_host+--neg'),				#11
	 qq(--ann_script='/annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc+--db=RPD3+--vdoms'),	#12  RPD3
	 qq(--ann_script='/annot/ann_exons_ncbi.pl+--host=$db_host'),				#13  ncbi_exons
	 qq(--ann_script='/annot/ann_exons_up_sql.pl+--host=$db_host'),				#14
	);

@psi2_annot_seq2_arr = ("","","--annot_db=pfam","--annot_db=rpd3","--annot_db=pfam","--annot_db=pfam","--annot_db=pfam","--annot_db=pfam",);

@blp_annot_seq1_arr = ("","",
	 qq(--q_ann_script='./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment'), 		#2
	 qq(--q_ann_script='./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment+--no_mod'), 	#3
	 qq(--q_ann_script='./annot/ann_upfeats_pfam_www_e.pl+--host=$db_host+$neg_opt$vdom_opt--acc_comment'),	#4
	 qq(--q_ann_script='./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment+--no-feats'),	#5
	 qq(--q_ann_script='./annot/ann_pfam_sql.pl+--host=$db_host+--db=$pfam_db+$neg_opt$vdom_opt--acc_comment'),			#6
	 qq(--q_ann_script='./annot/ann_pfam_sql.pl+--host=$db_host+--db=$pfam_db+$neg_opt--pfacc+$vdom_opt--acc_comment'),		#7
	 qq(--q_ann_script='./annot/ann_pdb_cath.pl+--host=$db_host+--neg'),				#8
	 qq(--q_ann_script='./annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),			#9
	 qq(--q_ann_script='./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc+--db=RPD3+--vdoms'),	#11
	 qq(--q_ann_script='./annot/ann_pdb_vast.pl+--host=$db_host+--neg'),				#11
	 qq(--q_ann_script='./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc+--db=RPD3+--vdoms'),	#12  RPD3
	 qq(--q_ann_script='./annot/ann_exons_ncbi.pl+--host=$db_host'),				#13  ncbi_exons
	 qq(--q_ann_script='./annot/ann_exons_up_www.pl'),				#14
	);

@blp_annot_seq2_arr = ("","",
	 qq(--ann_script='./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment'), 		#2
	 qq(--ann_script='./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment+--no_mod'), 	#3
	 qq(--ann_script='./annot/ann_upfeats_pfam_www_e.pl+--host=$db_host+$neg_opt$vdom_opt--acc_comment'),	#4
	 qq(--ann_script='./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment+--no-feats'),	#5
	 qq(--ann_script='./annot/ann_pfam_sql.pl+--host=$db_host+--db=$pfam_qfo_db+$neg_opt$vdom_opt--acc_comment'),			#6
	 qq(--ann_script='./annot/ann_pfam_sql.pl+--host=$db_host+--db=$pfam_qfo_db+$neg_opt--pfacc+$vdom_opt--acc_comment'),		#7
	 qq(--ann_script='./annot/ann_pdb_cath.pl+--host=$db_host+--neg'),				#8
	 qq(--ann_script='./annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),			#9
	 qq(--ann_script='./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc+--db=RPD3+--vdoms'),	#11
	 qq(--ann_script='./annot/ann_pdb_vast.pl+--host=$db_host+--neg'),				#11
	 qq(--ann_script='./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc+--db=RPD3+--vdoms'),	#12  RPD3
	 qq(--ann_script='./annot/ann_exons_ncbi.pl+--host=$db_host'),				#13  ncbi_exons
	 qq(--ann_script='./annot/ann_exons_up_sql.pl+--host=$db_host'),				#14
	);

%form_list =
  (
###
   'misc1'=>
   {tmpl=>"misc1.tmpl",
    pgm_ref=>\@pgm_mlist,
    pgm_def=>"pkd",
    inputs =>
    { query => {SEARCH_QUERY => "this", SEARCH_FRM_ACC => "selected"}
    },
    outputs =>
    { TITLE => qq(Misc. Protein Analysis),
      RUN_MODE=>'misc1_rx',
    }
   },
###
   'shuffle' =>
   {tmpl=>"compare.tmpl", pgm_ref=>\@pgm_shuff_list,
    pgm_def=>"rss",
    inputs =>
    {query => {SEARCH_QUERY => "this", SEARCH_FRM_ACC => "selected",
	       SSR => \&get_query_range},
     query2 => {SEARCH_QUERY2 => "this", SEARCH_FRM_ACC2 => "selected"}
    },
    outputs =>
    {SUBMIT => "Shuffle Sequence",
     SSR_FLAG => '1',
     Q2_FILE_UP => 1,
     HAVE_SSR2 => '1',
     SEG_FLAG => '1',
     TITLE => qq(PRSS/PRFX Sequence Shuffling),
     OPTION1 => $shuff_opt1,
     OPTION2 => $shuff_opt2,
     MSA_PSSM_FILE => $shuff_msa_opt,
     RUN_MODE=>'shuffle_r',
    },
   },
###
   'compare' =>
   { tmpl=>"compare.tmpl",
     pgm_ref=>[@pgm_flist, @pgm_slist],
     pgm_def=>"fap",
     CAN_REMOTE => 1,
     inputs =>
    { query => {SEARCH_QUERY => "this", SEARCH_FRM_ACC => "selected",
		},
      query2 => {SEARCH_QUERY2 => "this", SEARCH_FRM_ACC2 => "selected",
      		SSR => \&get_query_range,
		SSR2 => \&get_query_range,
      		},
      annot_seq1 => {ANNOT1_SEQ => "this"},
      annot_seq2 => {ANNOT2_SEQ => "this"},
    },
    outputs =>
    { SUBMIT => 'Compare Sequences',
      Q2_FILE_UP => 1,
      SSR_FLAG => '1',
      HAVE_SSR2 => '1',
      MSA_PSSM_FILE => $shuff_msa_opt,
      TITLE => qq(FASTA Sequence Comparison),
      OPTION1 => '',
      OPTION2 => $comp_opt2,
      OPTION3 => $comp_opt3,
      OPTION4 => $select_opt4,
      SEG_FLAG => 1,
      RUN_MODE => 'compare_r',
      REM_RUN_MODE=>'compare_r',
    },
   },
###
   'lalign' =>
   { tmpl=>"compare.tmpl", pgm_ref=>\@pgm_lalign_list,
     pgm_def=>"lal",
     inputs =>
     { query => {SEARCH_QUERY => "this", SEARCH_FRM_ACC => "selected",
		 SSR => \&get_query_range},
       query2 => {SEARCH_QUERY2 => "this", SEARCH_FRM_ACC2 => "selected",
		  SSR2 => \&get_query_range,},
     },
     outputs =>
     { SUBMIT => 'Align Sequences',
       TITLE => qq(LALIGN/PLALIGN local alignments),
       # OPTION1 => $lalign_opt1,
       OPTION1 => " ",
       OPTION2 => $lalign_opt2,
       OPTION3 => $lalign_opt3,
       RUN_MODE => 'lalign_x',
       Q2_FILE_UP => 1,
       SSR_FLAG => '1',
       HAVE_SSR2 => '1',
       SSR_FLAG => '1',
     },
   },
###
   'lplalign' =>
   { tmpl=>"compare.tmpl", pgm_ref=>\@pgm_lalign_list,
     pgm_def=>"lplal",
     inputs =>
     { query => {SEARCH_QUERY => "this", SEARCH_FRM_ACC => "selected",
		 SSR => \&get_query_range},
       query2 => {SEARCH_QUERY2 => "this", SEARCH_FRM_ACC2 => "selected",
		  SSR2 => \&get_query_range,},
       annot_seq1 => {ANNOT1_SEQ => "this"},
       annot_seq2 => {ANNOT2_SEQ => "this"},
     },
     outputs =>
     { SUBMIT => 'Align Sequences',
       TITLE => qq(LALIGN/PLALIGN local alignments),
       OPTION1 => $lalign_opt1,
       OPTION2 => $lalign_opt2,
       OPTION3 => $lalign_opt3,
       RUN_MODE => 'lalign_x',
       Q2_FILE_UP => 1,
       SSR_FLAG => '1',
       HAVE_SSR2 => '1',
       SSR_FLAG => '1',
       MSA_PSSM_FILE => '',
     },
   },
###
   'blast' =>
   { tmpl=>"select.tmpl", pgm_ref=>\@pgm_blist, pgm_def=>"bp",
     lib_ref=> \@blp_list,
     CAN_REMOTE => 1,
     inputs =>
     { query => {SEARCH_QUERY => "this", SEARCH_FRM_ACC => "selected"},
       remote => {SHOW_REMOTE => "this", RUNMODE => 'remote'},
       annot_seq1 => {ANNOT1_SEQ => "this"},
       annot_seq2 => {ANNOT2_SEQ => "this"},
     },
     outputs =>
     { TITLE => qq(BLAST Sequence Comparison),
       RUN_MODE=>'blast_r',
       REM_RUN_MODE => 'blast_r',
       OPTION1 => $blast_opt1,
       MSA_PSSM_FILE => '',
     },
   },
###
   'phmmer' =>
   { tmpl=>"select.tmpl", pgm_ref=>\@pgm_phlist, pgm_def=>"phmm",
     lib_ref=> \@hmmp_list,
     CAN_REMOTE => 1,
     inputs =>
     { query => {SEARCH_QUERY => "this", SEARCH_FRM_ACC => "selected"},
       remote => {SHOW_REMOTE => "this", RUNMODE => 'remote'},
     },
     outputs =>
     { TITLE => qq(HMMER3 Sequence Comparison),
       RUN_MODE=>'phmm_r',
       REM_RUN_MODE => 'phmm_r',
       OPTION1 => ' ',
       OPTION2 => $lalign_opt2,
       MSA_PSSM_FILE => '',
     },
   },
###
   'select' =>
   { tmpl=>"select.tmpl",
     pgm_ref=>[@pgm_fslist], pgm_def=>"fap",
     ws_lib_list => \@ws_libs,
     lib_env=> $FAST_LIBS,
     CAN_REMOTE => 1,
     inputs =>
     { query => {SEARCH_QUERY => "this", SEARCH_FRM_ACC => "selected",
		 SSR => \&get_query_range},
       remote => {SHOW_REMOTE => "this", RUNMODE => 'remote'},
       acc => {SEARCH_FRM_ACC=>"selected"},
       annot_seq1 => {ANNOT1_SEQ => "this"},
       annot_seq2 => {ANNOT2_SEQ => "this"},
     },
     www_opts => {
        hide_align => { arg => \$HIDE_ALIGN, val => \&get_option, cmd_arg=>1},
     },
     outputs =>
     { RUN_MODE=>'search',
       REM_RUN_MODE=>'search',
       TITLE => qq(FASTA Sequence Comparison),
       OPTION1 => $select_opt1,
       LIB_OPT => $lib_opt,
       OPTION2 => $select_opt2,
       OPTION3 => $select_opt3,
       OPTION4 => $select_opt4,
       MSA_PSSM_FILE => $shuff_msa_opt,
     },
   },
###
   'psi2_select' =>
   { tmpl=>"psi2_select.tmpl",
     pgm_ref=>[@pgm_psi2list], pgm_def=>"psi2sw",
     lib_env=> $FAST_LIBS,
     CAN_REMOTE => 1,
     inputs =>
     { query => {SEARCH_QUERY => "this", SEARCH_FRM_FA => "selected",
		 SSR => \&get_query_range},
       msa_query => {MSA_QUERY => "this"},
       remote => {SHOW_REMOTE => "this", RUNMODE => 'remote'},
       acc => {SEARCH_FRM_ACC=>"selected"},
       annot_seq1 => {ANNOT1_SEQ => "this"},
       annot_seq2 => {ANNOT2_SEQ => "this"},
       pssm_eval => {PSSM_EVAL => "this"},
     },
     www_opts => {
        hide_align => { arg => \$HIDE_ALIGN, val => \&get_option, cmd_arg=>1},
     },
     outputs =>
     { RUN_MODE=>'psi2_search',
       REM_RUN_MODE=>'psi2_search',
       TITLE => qq(PSI-SEARCH2 Sequence Comparison),
       OPTION1 => $psi2_select_opt1,
       LIB_OPT => $lib_opt,
       OPTION2 => $psi2_select_opt2,
       OPTION3 => $select_opt3,
       OPTION4 => $select_opt4,
       MSA_PSSM_FILE => "",
     },
   },
###
   'rmch_select' =>
   { tmpl=>"select_rmch.tmpl",
     pgm_ref=>[@pgm_fslist], pgm_def=>"sw",
     lib_p_def => 'B',
     ws_lib_list => \@ws_libs,
     lib_env=> $FAST_LIBS,
     CAN_REMOTE => 1,
     inputs =>
     { query => {SEARCH_QUERY => "this", SEARCH_FRM_ACC => "selected",
		 SSR => \&get_query_range},
       remote => {SHOW_REMOTE => "this", RUNMODE => 'remote'},
       acc => {SEARCH_FRM_ACC=>"selected"},
       annot_seq1 => {ANNOT1_SEQ => "this"},
       annot_seq2 => {ANNOT2_SEQ => "this"},
     },
     www_opts => {
        hide_align => { arg => \$HIDE_ALIGN, val => \&get_option, cmd_arg=>1},
     },
     outputs =>
     { RUN_MODE=>'rmch_search',
       REM_RUN_MODE=>'rmch_search',
       TITLE => qq(RDP2 Sequence Comparison),
       OPTION1 => $select_opt1,
       LIB_OPT => $lib_opt,
       OPTION2 => $select_opt2,
       OPTION3 => $select_opt3_rmch,
       OPTION4 => $select_opt4,
       MSA_PSSM_FILE => $shuff_msa_opt,
     },
   },
###
   'selectg' =>
   { tmpl=>"select.tmpl",
     pgm_ref=>[@pgm_flist, @pgm_slist], pgm_def=>"fap",
     lib_env=> $FAST_GNMS,
     inputs =>
     { query => {SEARCH_QUERY => "this", SEARCH_FRM_ACC => "selected",
		 SSR => \&get_query_range},
       remote => {SHOW_REMOTE => "this"},
       acc => {SEARCH_FRM_ACC=>"selected"},
       annot_seq1 => {ANNOT1_SEQ => "this"},
       annot_seq2 => {ANNOT2_SEQ => "this"},
     },
     www_opts => {
        hide_align => { arg => \$HIDE_ALIGN, val => \&get_option, cmd_arg=>1},
     },
     outputs =>
     { RUN_MODE=>'searchg',
       REM_RUN_MODE=>'searchg',
       TITLE => qq(FASTA Sequence Comparison),
       OPTION1 => $select_opt1,
       LIB_OPT => $lib_opt,
       OPTION2 => $select_opt2,
       OPTION3 => $select_opt3,
       OPTION4 => $select_opt4,
       MSA_PSSM_FILE => $shuff_msa_opt,
     },
   },
###
   'mselect' =>
   { tmpl=>"mselect.tmpl",
     pgm_ref=>\@pgm_pssmlist, pgm_def=>"psi2sw",
     lib_ref=> \@blp_list,
     inputs =>
     { query => {SEARCH_QUERY => "this", SEARCH_FRM_FA => "selected"},
       msa_query => {MSA_QUERY => "this"},
       annot_seq1 => {ANNOT1_SEQ => "this"},
       annot_seq2 => {ANNOT2_SEQ => "this"},
     },
     inp_dep_list => [qw(msa_query query)],
     inp_deps => {msa_query => ["msa_query", \&clean_mquery],
		  query => ["msa_query", \&query_from_mquery],
		  },
     outputs =>
     { TITLE => qq(PSSM Sequence Comparison),
       MSA_FILE_UP => 1,
       RUN_MODE=>'msearch_x',
       OPTION1 => $mselect_opt1,
       MSA_PSSM_FILE => $shuff_msa_opt,
     },
   },

   'hmm_select' =>
   { tmpl=>"hmm_select.tmpl",
     pgm_ref=>\@pgm_hmmlist, pgm_def=>"hmms",
     lib_ref=> \@hmmp_list,
##     inputs =>
##     { hmm_query => {HMM_QUERY => "this"}
##     },
     outputs =>
     { TITLE => qq(HMM Sequence Comparison),
       HMM_FILE_UP => 1,
       RUN_MODE=>'hmm_search',
       OPTION1 => ' ',
       MSA_PSSM_FILE => '',
     },
   },

   'hmm_select2' =>
   { tmpl=>"hmm_select2.tmpl",
     pgm_ref=>\@pgm_hmmlist, pgm_def=>"hmms",
     lib_ref=> \@hmmp_list,
##     inputs =>
##     { hmm_query => {HMM_QUERY => "this"}
##     },
     outputs =>
     { TITLE => qq(HMM Sequence Comparison),
       HMM_FILE_UP => 1,
       RUN_MODE=>'hmm_search',
       SUBMIT => 'Scan HMM',
       Q2_FILE_UP => 1,
       MSA_PSSM_FILE => $shuff_msa_opt,
       TITLE => qq(FASTA Sequence Comparison),
       OPTION1 => " ",
       OPTION2 => $comp_opt2,
       OPTION3 => $comp_opt3,
       RUN_MODE => 'hmm_search',
       REM_RUN_MODE=>'hmm_search',
    },
   },
  );

#
# lots of programs have gap penalties and scoring matrices
#
%fa_opt_params =
    (
     gap => { cmd_arg => "-f %d", val=> \&get_safe_number, ws_arg => 'gapopen'},
     ext => { cmd_arg => "-g %d", val=> \&get_safe_number, ws_arg => 'gapext'},
     smatrix => { cmd_arg => "", val=> \&get_smatrix, ws_arg => 'matrix'},
     segflag => { cmd_arg => "-S", val=> \&get_option, ws_arg => 'filter' },
     );

# %run_list{run_name} provides the information required by do_search()
# to run a program, given the input query an parameters
#
# run_list->{run_name} = {
#      pgm_ref => [list of programs to be selected from],
#      n_q => number of queries (n_q = 1 for searches, 2 for comparison)
#      use_query1 => 1 (put the @ in the command line)
#      have_ssr => get ssr for query1
#      query2_type => tmp -> temporary file, q2 for \@, lib for lib selection
#      get_lib_sub => get a library from lib_p or lib_n
#      lib_env => FAST_LIBS environment
#      remote => 1 -> can remote
#      pgm_args => "default string after program before other options"
#   opts and post_opts are both parsed by the same code
#      opts => { param1 => [ "option_str1", \&get_func, default],
#		 param2 => [ "option_str2", \&get_func, default],
#	  default is the value provided if the param1 is not given
#

%run_list = (
     'misc1_rx'=> {
	 indirect => {
	     seg => misc1_seg,
	     cho => misc1_rss,
	     gor => misc1_rss,
	     pkd => misc1_pkd,
	     tkd => misc1_tkd,
	     }
     },
     'misc1_pkd'=> {
	 pgm_ref=>\@pgm_mlist, n_q => 1, sq_type => 1,
	 q_arg => "query",
	 qt_arg => "q_type",
	 qf_arg => "query_file",
	 use_query1 => 1, no_html => 1,
	 err2out => 1,
	 post_opts => {
	     kd_window => {cmd_arg=>" %d", val=>\&get_safe_number},
	     },
     },
     'misc1_tkd'=> {
	 pgm_ref=>\@pgm_mlist, n_q => 1, sq_type => 1,
	 q_arg => "query",
	 qt_arg => "q_type",
	 qf_arg => "query_file",
	 use_query1 => 1, no_html => 1,
	 err2out => 1,
	 post_opts => {
	     kd_window => [cmd_arg=>" %d", val=>\&get_safe_number]
	     },
     },
# 'misc1_seg' does not use use_query1 (no \@)
     'misc1_seg'=> {
	 pgm_ref=>\@pgm_mlist, n_q => 1, sq_type => 1,
	 q_arg => "query",
	 qt_arg => "q_type",
	 qf_arg => "query_file",
	 no_html => 1,
	 post_opts => {
	     seg_domain => {cmd_arg=>["","- -q -z 1", "- -p"],
			    val => \&put_indexed_args, default_arg =>"- -q -z 1"}
	     },
     },
     'misc1_rss'=> {	# used for "gor", "cho"
	 pgm_ref=>\@pgm_mlist, n_q => 1, sq_type => 1,
	 q_arg => "query",
	 qt_arg => "q_type",
	 qf_arg => "query_file",
	 use_query1 => 1, no_html => 1,
	 err2out => 1,
     },
####
     'shuffle_r'=> {
	 pgm_ref=> \@pgm_shuff_list, n_q => 2,
	 pgm_args => "-q -w 80 -m 6 -Z 10000 -E 1000.0",
	 use_query1 => 1, query2_type => 'tmp',
	 have_ssr => 1, have_ssr2 => 1,
	 have_url_ref =>"", use_ktup => 1,
	 link_url_ref => "",
	 opts =>
	 { %fa_opt_params,
	   shuff_cnt => { cmd_arg => "-k %d", val=>\&get_safe_number, default_arg=>"-k 200"},
	   shuff_w => { cmd_arg => "-v 20", val=> \&get_option},
	   msa_asn_file => { cmd_arg => "-P \"%s 2\"", val=> \&get_file2file},
	   msa_asn_rid => { cmd_arg => "-P \"%s 2\"", val=> \&get_rid2file},
         },
	 post_opts => {
		       ktup => { cmd_arg => " %d", val=> \&get_safe_number}
		      },
	 rem_files => {
	     msa_asn_file => [\&get_file2file, 'msa_asn_file'],
	     msa_asn_rid => [\&get_rid2file, 'msa_asn_file']
	 },
	 header => $rmch_footer,
	 footer => $rmch_footer,
     },
####
     'compare_r'=> {
	 pgm_ref=>[@pgm_flist, @pgm_slist, @pgm_hlist],
	 run_bkgd => 1,
	 n_q => 2, have_ssr => 1, have_ssr2 => 1,
	 have_url_ref =>"",
	 pgm_args => "-q -w 80 -m 6 -m 9I -Z 10000",
#	 use_query1 => 1,
         query1_type => 'tmp',
	 query1_opt => "",
	 query2_type => 'tmp',
	 use_ktup => 1,
	 link_url_ref => "",

	 opts => { %fa_opt_params,
		   ev_lim => { cmd_arg => "-E %g",val=> \&get_safe_number},
		   msa_asn_file => { cmd_arg => "-P \"%s 2\"", val=> \&get_pssm2file},
		   exp_iso => { cmd_arg=>"-e ./annot/expand_up_isoforms.pl",val=>\&get_option, default_arg=>""
		   },

#		   msa_asn_rid => { cmd_arg => "-P \"%s 2\"", val=> \&get_rid2file},
#		   annot_seq1 => { cmd_arg => qq(-V "q\!ann_feats2ipr.pl"), val=>\&get_option },
#		   annot_seq1_file => { cmd_arg => qq(-V "q\<%s"), val=>\&get_file2file },

		   annot_seq1 => { cmd_arg => \@annot_seq1_arr,
				   val=>\&put_indexed_args },
		   annot_seq1_file => { cmd_arg => qq(-V "q\<%s"), val=>\&get_file2file },

#		   annot_seq2 => { cmd_arg => qq(-V "\!ann_feats2ipr_e.pl+--neg"), val=>\&get_option },
		   annot_seq2 => { cmd_arg => \@annot_seq2_arr,
				   val=>\&put_indexed_args },
		   annot_seq2_file => { cmd_arg => qq(-V "\<%s"), val=>\&get_file2file },
	     tab_format => { cmd_arg => [ "-m 9I -m 6",
					  "-m 9I -m 6",
					  "-m 9B -m 6",
					  "-m B -m 9I -m6",
					  "-m 8 -d 0",
					  "-m 9c -d 0",
					  "-m 8CC -d 0"],
			     default_arg=>"-m 9I -m 6",
			     val => \&put_indexed_args},
	       },
	 post_opts => {
		       ktup => { cmd_arg => " %d", val=> \&get_safe_number},
		       },
         domain_color => \&process_domain_colors,
	 rem_files => {
	     msa_asn_file => [\&get_file2file, 'msa_asn_file'],
	     msa_asn_rid => [\&get_rid2file, 'msa_asn_file']
	 },
	 header => $fa_footer,
	 footer => $fa_footer,
     },

     'lalign_x'=> {
	 indirect => {
	    lpal => lplalign_r,
            lpald => lplalign_r,
            lal => lalign_r,
	    lald => lalign_r,
	    pal => plalign_r,
            pald => plalign_r,
	 }
      },

     'lalign_r'=> {
	 pgm_ref=>\@pgm_lalign_list, n_q => 2,
	 pdfdev => 1, have_ssr => 1, have_ssr2 => 1,
	 use_query1 => 1, query2_type => 'tmp',
	 pgm_args => '-q -w 80 -m 6',
	 link_url_ref => "",
         domain_color => \&process_domain_colors,
	 opts => {
	     annot_seq1 => { cmd_arg => ["", "",
					 qq(-V 'q\!./annot/ann_feats2ipr_e.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_feats_up_sql.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--no-feats'),
					 qq(-V 'q\!./annot/ann_pfam_sql.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc'),
					 qq(-V 'q\!./annot/ann_pdb_cath.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),
				 ],
			     val=>\&put_indexed_args },

	     annot_seq2 => { cmd_arg => ["", "",
					 qq(-V '\!./annot/ann_feats2ipr_e.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_feats_up_sql.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--no-feats'),
					 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc'),
					 qq(-V '\!./annot/ann_pdb_cath.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),
				 ],
			     val=>\&put_indexed_args },
	     annot_seq1_file => { cmd_arg => qq(-V "q\<%s"), val=>\&get_file2file },
	     annot_seq2_file => { cmd_arg => qq(-V "\<%s"), val=>\&get_file2file },

#	     annot_seq1 => { cmd_arg => qq(-V "q\!ann_feats_up_sql.pl+--no-feats"), val=>\&get_option },
#	     annot_seq2 => { cmd_arg => qq(-V "\!ann_feats_up_sql.pl+--no-feats"), val=>\&get_option },

	     show_ident => { cmd_arg => "-I", val=> \&get_option},
	     gap => { cmd_arg => "-f %d", val=> \&get_safe_number},
	     ext => { cmd_arg => "-g %d", val=> \&get_safe_number},
	     smatrix => { cmd_arg => "", val=> \&get_smatrix},
	     ev_lim => { cmd_arg => "-E %g", val=> \&get_safe_number, ws_arg => "expupperlim"},
	 },
	 www_opts => {
		      hide_align => { arg => \$HIDE_ALIGN, val => \&get_option, cmd_arg=>1},
		     },
	 header => $fa_footer,
	 footer => $fa_footer,
     },

     'plalign_r'=> {
	 pgm_ref=>\@pgm_lalign_list, n_q => 2,
	 pdfdev => 1, have_ssr => 1, have_ssr2 => 1,
	 use_query1 => 1, query2_type => 'tmp', no_html => 1,
	 pgm_args => q(-q -m 11),
	 opts => {
	     annot_seq1 => { cmd_arg => ["", "",
					 qq(-V 'q\!./annot/ann_feats2ipr_e.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_feats_up_sql.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--no-feats'),
					 qq(-V 'q\!./annot/ann_pfam_sql.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc'),
					 qq(-V 'q\!./annot/ann_pdb_cath.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),
				 ],
			     val=>\&put_indexed_args },

	     annot_seq1_file => { cmd_arg => qq(-V "q\<%s"), val=>\&get_file2file },

	     annot_seq2 => { cmd_arg => ["", "",
					 qq(-V '\!./annot/ann_feats2ipr_e.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_feats_up_sql.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--no-feats'),
					 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc'),
					 qq(-V '\!./annot/ann_pdb_cath.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),
				 ],
			     val=>\&put_indexed_args },
	     annot_seq2_file => { cmd_arg => qq(-V "\<%s"), val=>\&get_file2file },
	     show_ident => { cmd_arg => "-I", val=>\&get_option},
	     gap => { cmd_arg => "-f %d", val=> \&get_safe_number},
	     ext => { cmd_arg => "-g %d", val=> \&get_safe_number},
	     smatrix => { cmd_arg => "", val=> \&get_smatrix},
	     ev_lim => { cmd_arg => "-E %g", val=> \&get_safe_number, ws_arg => "expupperlim"},
	 },
	 dev_opts => {
	     annot_seq1 => { cmd_arg => "xA=%d", val=>\&get_safe_number },
	     annot_seq2 => { cmd_arg => "yA=%d", val=>\&get_safe_number },
	 },
	 header => $fa_footer,
	 footer => $fa_footer,
     },

     'lplalign_r'=> {
	 pgm_ref=>\@pgm_lalign_list, n_q => 2,
	 pdfdev => 1, have_ssr => 1, have_ssr2 => 1,
	 use_query1 => 1, query2_type => 'tmp', no_html => 1,
	 pgm_args => q(-q -m 11),
         pgm_results => {
	     aln_output => {cmd_arg => "-m \"F0H %s\"", res => \&put_res2file,  suff => '.aln'},
	 },
	 opts => {
	     annot_seq1 => { cmd_arg => ["", "",
					 qq(-V 'q\!./annot/ann_feats2ipr_e.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_feats_up_sql.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--no-feats'),
					 qq(-V 'q\!./annot/ann_pfam_sql.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc'),
					 qq(-V 'q\!./annot/ann_pdb_cath.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),
				 ],
			     val=>\&put_indexed_args },

	     annot_seq1_file => { cmd_arg => qq(-V "q\<%s"), val=>\&get_file2file },

	     annot_seq2 => { cmd_arg => ["", "",
					 qq(-V '\!./annot/ann_feats2ipr_e.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_feats_up_sql.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--no-feats'),
					 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+$neg_opt--pfacc'),
					 qq(-V '\!./annot/ann_pdb_cath.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),
				 ],
			     val=>\&put_indexed_args },
	     annot_seq2_file => { cmd_arg => qq(-V "\<%s"), val=>\&get_file2file },
 	     show_ident => { cmd_arg => "-I", val=>\&get_option},
	     gap => { cmd_arg => "-f %d", val=> \&get_safe_number},
	     ext => { cmd_arg => "-g %d", val=> \&get_safe_number},
	     smatrix => { cmd_arg => "", val=> \&get_smatrix},
	     ev_lim => { cmd_arg => "-E %g", val=> \&get_safe_number, ws_arg => "expupperlim"},
	 },
         domain_color => \&process_domain_colors,
	 dev_opts => {
	     annot_seq1 => { cmd_arg => "xA=%d", val=>\&get_safe_number },
	     annot_seq2 => { cmd_arg => "yA=%d", val=>\&get_safe_number },
	 },
	 www_opts => {
		      hide_align => { arg => \$HIDE_ALIGN, val => \&get_option, cmd_arg=>1},
		     },
	 link_url_ref => "",
	 header => $fa_footer_s,
	 footer => $fa_footer,
     },

     'search' => {
	 pgm_ref=>[@pgm_flist, @pgm_slist, @pgm_hlist],
	 ws_lib_ref => \@ws_libs,
	 n_q => 1, 
	 lib_env=> $FAST_LIBS,
         remote=>1,
         have_ssr=>1,
	 run_bkgd => 1,
	 run_ws => 1,
	 pgm_args => "-q -w 80",
	 q_arg => "query",
	 qt_arg => "q_type",
	 qf_arg => "query_file",
#	 use_query1 => 1,
         query1_type => 'tmp',
         query1_opt => '',
	 query2_type => 'lib',
	 get_lib_sub => \&get_lib,
	 ws_get_lib_sub => \&ws_get_lib,
	 use_ktup => 1,
	 link_url_ref => "",
#	 no_html => 1,
	 ws_no_html => 1,
	 opts => {
	     %fa_opt_params,
	     db_range =>{ cmd_arg => "-M", val=> \&get_safe_range, ws_arg =>"dbrange"},
	     ev_lim => { cmd_arg => "-E %g", val=> \&get_safe_number, ws_arg => "expupperlim"},
	     ev_top => { cmd_arg => "-F %g", val=> \&get_safe_number, ws_arg => "explowlim"},
	     aln_type => { cmd_arg => ["","-m 1","-m 2"], val=>\&put_indexed_args, default_arg=>""},
	     show_hist => { cmd_arg => ["","-H"],val=> \&put_indexed_args, ws_arg => "histogram", default_arg=>""},
#	     annot_seq1 => { cmd_arg => "-Vq\!ann_feats2ipr_e.pl+--host=$db_host+", val=>\&get_option },
	     annot_seq1 => { cmd_arg => \@annot_seq1_arr,
			     val=>\&put_indexed_args, ws_flag => 'annotfeats' },
	     annot_seq1_file => { cmd_arg => qq(-V "q\<%s"), val=>\&get_file2file },
	     annot_seq2 => { cmd_arg => \@annot_seq2_arr,
			     val=>\&put_indexed_args, ws_flag => 'annotfeats' },
	     sq_type => { cmd_arg=> ["","","","-3","-i"], val=>\&put_indexed_args,default_arg=>""},
	     exp_iso => { cmd_arg=>"-e ./annot/expand_up_isoforms.pl",val=>\&get_option, default_arg=>""},
	     tab_format => { cmd_arg => [ "-m 9I -m 6",
					  "-m 9I -m 6",
					  "-m 9B -m 6",
					  "-m B -m 9I -m6",
					  "-m 8 -d 0",
					  "-m 9c -d 0",
					  "-m 8CC -d 0"],
			     default_arg=>"-m 9I -m 6",
			     val => \&put_indexed_args},

	     zstat => { cmd_arg => "-z %d",val=> \&get_safe_number},
	     max_align => { cmd_arg => "-d %d", val=>\&get_safe_number, default_arg=>""},
	     msa_asn_file => { cmd_arg => "-P \"%s 2\"", val=> \&get_pssm2file},
#	     msa_asn_rid => { cmd_arg => "-P \"%s 2\"", val=> \&get_rid2file},
#	     rem_asn_text => { cmd_arg => "-P \"%s 2\"", val=> \&get_text2file},
	 },
	 post_opts => {
		       ktup => { cmd_arg => " %d", val=> \&get_safe_number},
		      },
	 rem_files => {
	     msa_asn_file => [\&get_file2file, 'msa_asn_file'],
#	     msa_asn_rid => [\&get_rid2file, 'msa_asn_file']
	 },
	 www_opts => {
		      hide_align => { arg => \$HIDE_ALIGN, val => \&get_option, cmd_arg=>1},
		     },
	 domain_color => \&process_domain_colors,
	 header => $fa_footer,
	 footer => $fa_footer,
     },

     'rmch_search'=> {
	 pgm_ref=>[@pgm_flist, @pgm_slist, @pgm_hlist],
	 ws_lib_ref => \@ws_libs,
	 n_q => 1, lib_env=> $FAST_LIBS, remote=>1, have_ssr=>1,
	 run_bkgd => 1,
	 run_ws => 1,
	 pgm_args => "-q -w 80",
	 q_arg => "query",
	 qt_arg => "q_type",
	 qf_arg => "query_file",
#	 use_query1 => 1,
         query1_type => 'tmp',
         query1_opt => '',
	 query2_type => 'lib',
	 get_lib_sub => \&get_lib,
	 ws_get_lib_sub => \&ws_get_lib,
	 use_ktup => 1,
	 link_url_ref => "",
#	 no_html => 1,
	 ws_no_html => 1,
	 opts => {
	     %fa_opt_params,
	     db_range =>{ cmd_arg => "-M", val=> \&get_safe_range, ws_arg =>"dbrange"},
	     ev_lim => { cmd_arg => "-E %g", val=> \&get_safe_number, ws_arg => "expupperlim"},
	     ev_top => { cmd_arg => "-F %g", val=> \&get_safe_number, ws_arg => "explowlim"},
	     aln_type => { cmd_arg => ["","-m 1","-m 2"], val=>\&put_indexed_args, default_arg=>""},
	     show_hist => { cmd_arg => ["","-H"],val=> \&put_indexed_args, ws_arg => "histogram", default_arg=>""},
#	     annot_seq1 => { cmd_arg => "-Vq\!ann_feats2ipr_e.pl", val=>\&get_option },
	     annot_seq1 => { cmd_arg => \@annot_seq1_arr,
			     val=>\&put_indexed_args, ws_flag => 'annotfeats' },
	     annot_seq1_file => { cmd_arg => qq(-V "q\<%s"), val=>\&get_file2file },
	     annot_seq2 => { cmd_arg => \@annot_seq2_arr,
			     val=>\&put_indexed_args, ws_flag => 'annotfeats' },
	     tab_format => { cmd_arg => [ "-m 9I -m6",
					  "-m 9I -m 6",
					  "-m 9 -d 0",
					  "-m B -m 9I -m6",
					  "-m 8",
					  "-m 9c -d 0",
					  "-m 8CC"],
			     val => \&put_indexed_args, default_arg=>"-m 9I -m 6" },

	     zstat => { cmd_arg => "-z %d",val=> \&get_safe_number},
	     max_align => { cmd_arg => "-d %d", val=>\&get_safe_number, default_arg=>""},
	     msa_asn_file => { cmd_arg => "-P \"%s 2\"", val=> \&get_pssm2file},
#	     msa_asn_rid => { cmd_arg => "-P \"%s 2\"", val=> \&get_rid2file},
#	     rem_asn_text => { cmd_arg => "-P \"%s 2\"", val=> \&get_text2file},
	 },
	 post_opts => {
		       ktup => { cmd_arg => " %d", val=> \&get_safe_number},
		      },
	 rem_files => {
	     msa_asn_file => [\&get_file2file, 'msa_asn_file'],
#	     msa_asn_rid => [\&get_rid2file, 'msa_asn_file']
	 },
	 www_opts => {
		      hide_align => { arg => \$HIDE_ALIGN, val => \&get_option, cmd_arg=>1},
		     },
	 domain_color => \&process_domain_colors,
	 header => $rmch_footer,
	 footer => $rmch_footer,
     },

     'searchg'=> {
	 pgm_ref=>[@pgm_flist, @pgm_slist, @pgm_hlist],
	 n_q => 1, lib_env=> $FAST_GNMS, remote=>1, have_ssr =>1,
	 run_bkgd => 1,
	 pgm_args => "-q -w 80",
#	 use_query1 => 1,
         query1_type => 'tmp',
         query1_opt => '',
	 query2_type => 'lib',
	 get_lib_sub => \&get_lib,
	 use_ktup => 1,
	 link_url_ref =>"g",
	 opts => {
	     %fa_opt_params,
	     db_range =>{ cmd_arg => "-M", val=> \&get_safe_range},
	     ev_lim => { cmd_arg => "-E %g",val=> \&get_safe_number},
	     ev_top => { cmd_arg => "-F %g",val=> \&get_safe_number},
	     zstat => { cmd_arg => "-z %d",val=> \&get_safe_number},
	     max_align => { cmd_arg => "-d %d", val=>\&get_safe_number, default_arg=>""},
	     msa_asn_file => { cmd_arg => "-P \"%s 2\"", val=> \&get_file2file},
	     msa_asn_rid => { cmd_arg => "-P \"%s 2\"", val=> \&get_rid2file},
	     annot_seq1 => { cmd_arg => ["", "",
					 qq(-V 'q\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment'),
					 qq(-V 'q\!./annot/ann_feats_up_sql.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment+--no-feats'),
					 qq(-V 'q\!./annot/ann_pfam_sql.pl+--host=$db_host+--no-over+$neg_opt--acc_comment'),
					 qq(-V 'q\!./annot/ann_pfam_sql.pl+--host=$db_host+--no-over+$neg_opt--acc_comment+--pfacc'),
					 qq(-V 'q\!./annot/ann_pdb_cath.pl+--host=$db_host+--neg'),
					 qq(-V 'q\!./annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),
					 qq(-V 'q\!./annot/ann_pfam_sql.pl+--host=$db_host+--no-over+$neg_opt--pfacc+--db=RPD2_pfam28u'),
				 ],
			     val=>\&put_indexed_args },
	     annot_seq1_file => { cmd_arg => qq(-V "q\<%s"), val=>\&get_file2file },
	     annot_seq2 => { cmd_arg => ["", "",
					 qq(-V '\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment'),
					 qq(-V '\!./annot/ann_feats_up_sql.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_feats2ipr_e.pl+--host=$db_host+$neg_opt--acc_comment+--no-feats'),
					 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+--no-over+$neg_opt--acc_comment'),
					 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+--no-over+$neg_opt--pfacc'),
					 qq(-V '\!./annot/ann_pdb_cath.pl+--host=$db_host+--neg'),
					 qq(-V '\!./annot/ann_pdb_cath.pl+--host=$db_host+--class+--neg'),
					 qq(-V '\!./annot/ann_pfam_sql.pl+--host=$db_host+--no-over+$neg_opt--pfacc+--db=RPD2_pfam28u'),
				 ],
			     val=>\&put_indexed_args },
	     tab_format => { cmd_arg => [ "",
					  "-m 9I -m 6",
					  "-m 9 -d 0",
					  "-m B -m 9I -m6",
					  "-m 8 -d 0",
					  "-m 9c -d 0",
					  "-m 8CC -d 0"],
			     val => \&put_indexed_args},
	 },
	 post_opts => {
		       ktup => { cmd_arg => " %d", val=> \&get_safe_number},
		      },
	 rem_files => {
	     msa_asn_file => [\&get_file2file, 'msa_asn_file'],
	     msa_asn_rid => [\&get_rid2file, 'msa_asn_file']
	 },
	 header => $fa_footer,
	 footer => $fa_footer,
     },

     'blast_r'=> {
	 pgm_ref=>\@pgm_blist, lib_ref => \@blp_list,
	 n_q => 1, remote=>1,
	 q_arg => 'query',
	 qt_arg => 'q_type',
	 query1_type => 'tmp',
	 query1_opt => '-q=',
	 run_bkgd => 1,
	 pgm_args => "",
	 opts => {
	     p_lib => { cmd_arg => "-db", val=> \&get_blib},
	     annot_seq1 => { cmd_arg => \@blp_annot_seq1_arr, val=>\&put_indexed_args},
	     annot_seq2 => { cmd_arg => \@blp_annot_seq2_arr, val=>\&put_indexed_args},
	     ev_lim => { cmd_arg => "-evalue %g", val=> \&get_safe_number},
	     gap => { cmd_arg => "-gapopen %d", val=> \&get_safe_number},
	     ext => { cmd_arg => "-gapextend %d", val=> \&get_safe_number},
	     smatrix => { cmd_arg => "-matrix %s", val=> \&get_bmatrix},
	 },
	 www_opts => {
		      hide_align => { arg => \$HIDE_ALIGN, val => \&get_option, cmd_arg=>1},
		     },
	 domain_color => \&process_domain_colors,
	 header => $bl_footer,
	 footer => $bl_footer,
     },

     'msearch_x'=> {
	 indirect => {
	     pbp => msearch_pbp,
	     pbp2 => msearch_pbp2,
	     jkhs => jkhs_search,
	     psi2sw => psi2_search,
	     pgg => msearch_psw,
	     pgl => msearch_psw,
	 }
     },

     'msearch_pbp'=> {
	 pgm_ref=>\@pgm_pssmlist,
	 lib_ref => \@blp_list,
	 run_bkgd => 1,
	 n_q => 1,
	 q_arg => 'query',
	 qt_arg => 'q_type',
	 query1_type => 'tmp',
	 query1_opt => '-i ',
	 pgm_args => "-T T",
	 opts => {
	     query => { cmd_arg => "-i %s", val=> \&get_query2file},
	     msa_query => { cmd_arg => "-B %s", val=> \&get_text2file },
	     iter => { cmd_arg => "-j %d", val=> \&get_safe_number, default_arg => "-j 3"},
	     ev_lim => { cmd_arg => "-h %g", val=> \&get_safe_number, default_arg => "-h 0.001"},
	     comp_stat => { cmd_arg => "-t %s", val=> \&get_safe_string},
	     p_lib => { cmd_arg => "-d", val=> \&get_blib},
	     msa_asn_file => { cmd_arg => qq(-q 2 -R %s), val=> \&get_file2file},
	     msa_asn_rid => { cmd_arg => qq(-q 2 -R %s), val=> \&get_rid2file},
	 },
	 header => $fa_footer,
	 footer => $bl_footer,
     },

     'msearch_pbp2'=> {
	 pgm_ref=>\@pgm_pssmlist2,
	 lib_ref => \@blp_list,
	 run_bkgd => 1,
	 n_q => 1,
#	 q_arg => 'query',
#	 qt_arg => 'q_type',
#	 query1_type => 'tmp',
#	 query1_opt => '-query ',
	 pgm_args => "-html",
	 opts => {
#	     query => { cmd_arg => "-query %s", val=> \&get_query2file},
	     msa_query => { cmd_arg => "-in_msa %s", val=> \&get_text2file },
	     iter => { cmd_arg => "-num_iterations %d", val=> \&get_safe_number, default_arg => "-num_iterations 3"},
	     ev_lim => { cmd_arg => "-inclusion_ethresh %g", val=> \&get_safe_number, default_arg => "-inclusion_ethresh 0.001"},
#	     comp_stat => { cmd_arg => "-t %s", val=> \&get_safe_string},
	     p_lib => { cmd_arg => "-db", val=> \&get_blib},
#	     msa_asn_file => { cmd_arg => qq(-q 2 -R %s), val=> \&get_file2file},
#	     msa_asn_rid => { cmd_arg => qq(-q 2 -R %s), val=> \&get_rid2file},
	 },
	 header => $fa_footer,
	 footer => $bl_footer,
     },

     'msearch_psw'=> {
	 pgm_ref=>\@pgm_pssmlist, lib_ref => \@blp_list,
	 n_q => 1, msa_q => 1,
	 run_bkgd => 1,
	 lib_env=> $FAST_GNMS, remote=>1, have_ssr =>1,
	 pgm_args => "-q -w 80 -m 6 -b 500 -d 250",
	 use_query1 => 1, query2_type => 'lib',
	 get_lib_sub => \&get_lib,
	 link_url_ref =>"",
	 opts => {
	     %fa_opt_params,
	     ev_lim => { cmd_arg => "-E %g",val=> \&get_safe_number},
	     ev_top => { cmd_arg => "-F %g",val=> \&get_safe_number},
	     zstat => { cmd_arg => "-z %d",val=> \&get_safe_number},
	 },
     },

     'psi2_search'=> {
	 pgm_ref=>\@pgm_psi2list, lib_env => $FAST_LIBS,
	 n_q => 1,
	 run_bkgd => 0,
	 remote=>1,
	 have_ssr =>1,
	 pgm_args => "--num_iter=1 --dir $TMP_DIR --use_stdout --m_format=m9B+-m6 --save_all",
	 use_query1 => 1,
	 query1_type => 'tmp',
	 query1_opt => '--query=',
	 query2_type => 'lib',
	 query2_opt => '--db=',
	 get_lib_sub => \&get_lib,
	 link_url_ref =>"",
	 save_res_file => 1,
	 iter_box => 1,
	 iter_parms => ['this_iter', 'pssm_evalue'],
	 opts => {
		  msa_query => { cmd_arg => "--in_msa %s", val=> \&get_text2file },
		  result_file => {cmd_arg =>"--prev_m89res %s", val=>\&get_local_file},
		  sel_accs_list => { cmd_arg =>"--sel_accs %s", val=>\&get_string2file},
		  annot_seq2 => { cmd_arg => \@psi2_annot_seq2_arr, val=>\&put_indexed_args},
		  int_mask => { cmd_arg => "--int_mask %s", val => \&get_safe_string},
		  end_mask => { cmd_arg => "--end_mask %s", val => \&get_safe_string},
		  this_iter => { cmd_arg => "--num_iter %s", val => \&get_safe_string},
		  pssm_eval => { cmd_arg => "--pssm_evalue %g", val => \&get_safe_number, default_arg=>"--pssm_evalue 1e-3"},
		  lib_abbr => { cmd_arg => "--db=%s", val => \&get_safe_string},
	 },
	 embed_params => 1,
	 www_opts => {
		      hide_align => { arg => \$HIDE_ALIGN, val => \&get_option, cmd_arg=>1},
		     },
	 submit_dest => "fasta_www.cgi",
	 domain_color => \&process_domain_colors,
	 header => $psi2_footer,
	 footer => $psi2_footer,
     },

     'hmm_search'=> {
	 pgm_ref=> \@pgm_hmmlist,
	 lib_env => $FAST_LIBS,
	 n_q => 1,
	 run_bkgd => 1,
	 no_html => 1,
	 q_arg => 'hmm_query',
	 qt_arg => 'hmm_qtype',
	 qf_arg => 'hmm_query_file',
	 query1_type => 'tmp',
	 query1_opt => '',
	 query2_type => 'tmp|lib',
	 get_lib_sub => \&get_lib_full,
	 opts => {
	     ev_lim => { cmd_arg => "-E %g",val=> \&get_safe_number},
	 },
	 header => $hmm_footer,
	 footer => $hmm_footer,
     },

     'jkhs_search'=> {
	 pgm_ref=> \@pgm_hmmlist,
	 lib_env => $FAST_LIBS,
	 n_q => 1,
	 run_bkgd => 1,
	 no_html => 1,
	 q_arg => "query",
	 qt_arg => "q_type",
	 query1_type => 'tmp',
	 query1_opt => '',
	 query2_type => 'lib',
	 get_lib_sub => \&get_lib_full,
	 opts => {
	     iter => { cmd_arg => "-N %d", val=> \&get_safe_number, default_arg =>"-N 2"},
	     ev_lim => { cmd_arg => "--incE %g", val=> \&get_safe_number, default_arg => "-incE 0.001"},
	 },
	 get_lib_sub => \&get_lib_full,
	 header => $hmm_footer,
	 footer => $hmm_footer,
     },
     'phmm_r'=> {
	 pgm_ref=> \@pgm_phlist,
	 lib_env => $FAST_LIBS,
	 n_q => 1,
	 run_bkgd => 1,
	 no_html => 1,
	 q_arg => "query",
	 qt_arg => "q_type",
	 query1_type => 'tmp',
	 query1_opt => '',
	 query2_type => 'lib',
	 get_lib_sub => \&get_lib_full,
	 opts => {
	     ev_lim => ["-E %g", \&get_safe_number, ""],
	 },
	 get_lib_sub => \&get_lib_full,
	 header => $hmm_footer,
	 footer => $hmm_footer,
     },
 );

# %page_links and %page_link_list are used for the list of links
# at the top of each page.

%page_links =
  (
   select => { desc => qq(Search Databases with FASTA),
	       link => qq(fasta_www.cgi?rm=select),
	     },

   psi2_select => { desc => qq(Search Databases with PSI-SEARCH2),
	       link => qq(fasta_www.cgi?rm=psi2_select),
	     },

   rmch_select => { desc => qq(Search RPD3 with FASTA),
	       link => qq(fasta_www.cgi?rm=rmch_select),
	     },
   selectg => { desc => qq(Search Proteomes/Genomes),
		link => qq(fasta_www.cgi?rm=selectg)},
   blast => { desc => qq(Search Databases with BLAST),
	      link => qq(fasta_www.cgi?rm=blast)},
   phmmer => { desc => qq(Search Databases with HMMER3),
	      link => qq(fasta_www.cgi?rm=phmmer)},
   mselect => { desc => qq(Search Databases with PSSMs),
		 link => qq(fasta_www.cgi?rm=mselect)},
   hmm_select => { desc => qq(Search Databases with HMMs),
		 link => qq(fasta_www.cgi?rm=hmm_select)},
   hmm_select2 => { desc => qq(Scan Sequences with HMMs),
		 link => qq(fasta_www.cgi?rm=hmm_select2)},
   compare => { desc => qq(Compare Two Sequences ),
		link => qq(fasta_www.cgi?rm=compare)
	      },
   shuffle => { desc => "Statistical Significance from Shuffles",
		link => "fasta_www.cgi?rm=shuffle"},
   lalign => { desc => "Find Internal Duplications (<b>lalign/plalign</b>)",
	       link => "fasta_www.cgi?rm=lalign"},
   lplalign => { desc => "Find Internal Duplications (<b>lalign/plalign</b>)",
	       link => "fasta_www.cgi?rm=lplalign"},
   misc1 =>  { desc => "Hydropathy/Secondary-Structure/<tt>seg</tt>",
	       link => "fasta_www.cgi?rm=misc1"}
  );

%page_link_list =
  (
   select => [[qw(this blast psi2_select shuffle lplalign misc1)],$select_text],
   rmch_select => [[qw(this selectg shuffle lplalign misc1)],$select_text],
   selectg =>[[qw(this select shuffle lplalign misc1)],$selectg_text],
   psi2_select => [[qw(this select shuffle lplalign misc1)],$select_text],
   blast =>[[qw(this select psi2_select lplalign)], $blast_text],
   phmmer =>[[qw(this select blast psi2_select)], $phmmer_text],
   mselect =>[[qw(this blast select shuffle lplalign)], $psiblast_text],
   hmm_select =>[[qw(this hmm_select2 select shuffle)], $hmm_select_text],
   hmm_select2 =>[[qw(this hmm_select select shuffle) ], $hmm_compare_text],
   shuffle =>[[qw(this select lplalign)], $shuff_text],
   lplalign =>[[qw(this select shuffle)], $lalign_text],
   lalign =>[[qw(this select shuffle)], $lalign_text],
   compare =>[[qw(this select shuffle lplalign)], $comp_text],
   misc1 =>[[qw(this select shuffle lplalign)], $misc_text],
  );

sub query_from_mquery {
    my ($mquery) = @_;

    my ($title) = ($mquery =~ m/^(\S+)\s/);
    $title = "query" unless ($title);

    my $query = ">$title\n" .
	join("",
	     map { s/\W//g; "$_\n" }
	     $mquery =~ m/(?:\A|\n\s*\n)\S+\s*([^\n]+)/sg #A. Mackey's secret code
	     );
}

sub clean_mquery {
    my ($mquery) = @_;

    unless ($mquery) { return "";}

    $mquery =~ s/\r\n/\n/sg;	# strip \r\n from Windows
    $mquery =~ s/\A(\s*\n)*//s;	# remove blank lines??
    $mquery =~ s/(\s*\n)*\Z//s;	#
    $mquery =~ s/^CLUSTAL .*$//m;
    $mquery =~ s/^MUSCLE .*$//m;
    return $mquery;
}

sub get_bl_filter {
    my ($opt, $p_arg) = @_;
    if ($p_arg) {return $opt;}
    else {return "";}
}

%pgm_dev = (
    pkd => {dev => "ps"},
    pal => {dev => "SVG",
	    pgm_svg => qq(lav2plt.pl --dev svg -Z 1 %xANNOT% %yANNOT%),
	    pgm_ps => qq(lav2plt.pl --dev ps -Z 1 %xANNOT% %yANNOT%),
	   },
    lpal => {dev => "SVG",
	     pgm_svg => qq(lav2plt.pl --dev svg -Z 1 %xANNOT% %yANNOT%),
	     pgm_ps => qq(lav2plt.pl --dev ps -Z 1 %xANNOT% %yANNOT%),
    },
    pald => {dev => "SVG",
	     pgm_svg => "lav2plt.pl --dev svg  -Z 1",
	     pgm_ps => "lav2plt.pl --dev ps -Z 1"},
    lpald => {dev => "SVG",
	      pgm_svg => "lav2plt.pl --dev svg  -Z 1",
	      pgm_ps => "lav2plt.pl --dev ps -Z 1"},
	     );


1;
