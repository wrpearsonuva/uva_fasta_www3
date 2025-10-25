#
# $Id: chaps_pgms.pl 35 2009-10-28 18:29:25Z wrp $
# $Revision$
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
%form_list =
  (
###
   'start'=> {
       tmpl=>"chaps3.tmpl",
       inputs => {
	   exp_name => {EXP_NAME => "this" },
	   msa_query => {MSA_QUERY => "this" },
	   msa_status => {MSA_STATUS => "this" },
	   fa_sel => {FA_SEL => "this"},
	   profile => {PROFILE => "this"},
	   hmm => {HMM => "this"},
	   gen_msa_stat => {GEN_MSA_STAT => "this"},
	   DEBUG => {DEBUG => "this"},
       },
       outputs => {
		   DEBUG => $DEBUG,
		  }
   },
###
   'gen_msa'=> {
       tmpl=>"chaps3.tmpl",
       inputs => {
	   exp_name => {EXP_NAME => "this" },
	   msa_query => {MSA_QUERY => "this" },
	   msa_status => {MSA_STATUS => "this" },
	   profile => {PROFILE => "this"},
	   hmm => {HMM => "this"},
	   gen_msa_stat => {GEN_MSA_STAT => "this"},
	   DEBUG => {DEBUG => "this"},
       },
       outputs => {
		   DEBUG => $DEBUG,
		  }
   },

   'gen_pssm'=> {
       tmpl=>"chaps3.tmpl",
       inputs => {
	   exp_name => {EXP_NAME => "this" },
	   msa_query => {MSA_QUERY => "this" },
	   msa_status => {MSA_STATUS => "this" },
	   profile => {PROFILE => "this"},
	   hmm => {HMM => "this"},
	   gen_msa_stat => {GEN_MSA_STAT => "this"},
	   DEBUG => {DEBUG => "this"},
       },
       outputs => {
		   DEBUG => $DEBUG,
		  }
   },
###
   'gen_hmm'=> {
       tmpl=>"chaps3.tmpl",
       inputs => {
	   exp_name => {EXP_NAME => "this" },
	   msa_query => {MSA_QUERY => "this" },
	   msa_status => {MSA_STATUS => "this" },
	   profile => {PROFILE => "this"},
	   hmm => {HMM => "this"},
	   gen_msa_stat => {GEN_MSA_STAT => "this"},
	   DEBUG => {DEBUG => "this"},
       }
   },

   'cal_hmm'=> 
   {
    tmpl=>"chaps3.tmpl",
    inputs =>
    {
     exp_name => {EXP_NAME => "this" },
     msa_query => {MSA_QUERY => "this" },
	   msa_status => {MSA_STATUS => "this" },
	   profile => {PROFILE => "this"},
	   hmm => {HMM => "this"},
	   gen_msa_stat => {GEN_MSA_STAT => "this"},
	   DEBUG => {DEBUG => "this"},
    },
    outputs => 
    {
     DEBUG => $DEBUG,
    }
   },

   'load_hmm'=>
   {
    tmpl=>"chaps3.tmpl",
    inputs =>
    {
     exp_name => {EXP_NAME => "this" },
     msa_query => {MSA_QUERY => "this" },
     msa_status => {MSA_STATUS => "this" },
     profile => {PROFILE => "this"},
     hmm => {HMM => "this"},
     gen_msa_stat => {GEN_MSA_STAT => "this"},
     DEBUG => {DEBUG => "this"},
    },
    outputs =>
    {
     DEBUG => $DEBUG,
    }
   },

   'load_msa'=>
   {
    tmpl=>"chaps3.tmpl",
    inputs =>
    {
     exp_name => {EXP_NAME => "this" },
     msa_query => {MSA_QUERY => "this" },
     msa_status => {MSA_STATUS => "this" },
     profile => {PROFILE => "this"},
     hmm => {HMM => "this"},
     gen_msa_stat => {GEN_MSA_STAT => "this"},
     DEBUG => {DEBUG => "this"},
    },
    outputs =>
    {
     DEBUG => $DEBUG,
    }
   }
  );

%run_subs = ( 'gen_pssm' => \&gen_pssm,
	      'gen_hmm' => \&gen_hmm,
	      'cal_hmm' => \&cal_hmm,
	      'load_hmm' => \&load_hmm,
	      'load_msa' => \&load_msa,
	      'gen_msa' => \&gen_msa,
	      );

1;
