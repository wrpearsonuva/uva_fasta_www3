#
# $Id: fawww_libs.pl 36 -q -H 2009-10-28 18:29:25Z wrp $
# $Revision: 181 $

# comparison programs:
#
# "fasta" programs, "blast" programs, hmmer programs
# descriptions in the list below MUST be followed by a ":",
# so the :trailing string can be removed

# all of the program lists have 6 values:
# 0: pgm abbreviation (pgm_val)
# 1: program description, provided in select drop down
# 2: actual program binary
# 3: query type (0->protein, 1->DNA)
# 4: library type (")
# 5: title for output page

@pgm_fslist = ({pgm=>"fap", label=>"FASTA: protein:protein", binary=>"fasta36 -p -T 16", q_sq=>0, l_sq=>0, title=>"FASTA",
	       ws_name =>"fasta",ws_opt => {stype => 'protein'}},
	       {pgm=>"sw", label=>"SSEARCH: local protein:protein", binary=>"ssearch36 -p -T 16", q_sq=>0, l_sq=>0, title=>"SSEARCH",
	       ws_name=>'ssearch', ws_opt => {stype => 'protein'}},
	      {pgm=>"gnw", label=>"GGSEARCH: global protein:protein", binary=>"ggsearch36 -p -T 16", q_sq=>0, l_sq=>0, title=>"GGSEARCH",
	       ws_name=>'ggsearch', ws_opt => {stype => 'protein'}},
	      {pgm=>"lnw", label=>"GLSEARCH: global/local protein:protein", binary=>"glsearch36 -p -T 16", q_sq=>0, l_sq=>0, title=>"GLSEARCH",
	       ws_name=>'glsearch', ws_opt => {stype => 'protein'}},
	      {pgm=>"fx", label=>"FASTX: DNA vs protein", binary=>"fastx36 -T 16", q_sq=>1, l_sq=>0, title=>"FASTX",
	       ws_name=>'fastx', ws_opt => {stype => 'dna'}},
	      {pgm=>"fy", label=>"FASTY: DNA vs protein", binary=>"fasty36 -T 16", q_sq=>1 , l_sq=>0, title=>"FASTY",
	       ws_name=>'fasty', ws_opt => {stype => 'dna'}},
	      {pgm=>"fad", label=>"FASTA: DNA:DNA", binary=>"fasta36 -n -T 16", q_sq=>1, l_sq=>1, title => "FASTA",
	       ws_name=>'fasta', ws_opt => {stype => 'dna'}},
	      {pgm=>"tfx", label=>"TFASTX: protein vs DNA", binary=>"tfastx36 -T 16", q_sq=>0, l_sq=>1, title=>"TFASTX",
	       ws_name=>'tfastx', ws_opt => {stype => 'protein'}},
	      {pgm=>"tfy", label=>"TFASTY: protein vs DNA", binary=>"tfasty36 -T 16", q_sq=>0, l_sq=>1, title=>"TFASTY",
	       ws_name=>'tfasty', ws_opt => {stype => 'protein'}},
	      {pgm=>"fs", label=>"FASTS: unordered peptides vs protein", binary=>"fasts36 -T 16", q_sq=>0, l_sq=>0, title=>"FASTS"},
	      {pgm=>"tfs", label=>"TFASTS: unordered peptides vs DNA", binary=>"tfasts36 -T 16", q_sq=>0, l_sq=>1, title=>"TFASTS"},
	      {pgm=>"ff", label=>"FASTF: mixed peptides vs protein", binary=>"fastf36 -T 16", q_sq=>0, l_sq=>0, title=>"FASTF"},
	      {pgm=>"tff", label=>"TFASTF: mixed peptides vs DNA ", binary=>"tfastf36 -T 16", q_sq=>0, l_sq=>1, title=>"TFASTF"},
	      {pgm=>"fmd", label=>"FASTM: ordered oligonucleotides vs DNA", binary=>"fastm36 -n -T 16", q_sq=>1, l_sq=>1, title=>"FASTA"},
	      {pgm=>"fsd", label=>"FASTS: unordered oligonucleotides vs :DNA", binary=>"fasts36 -n -T 16", q_sq=>1, l_sq=>1, title=>"FASTA"}
	      );



@pgm_flist = ({pgm=>"fap", label=>"FASTA: protein:protein", binary=>"fasta36 -p -T 16", q_sq=>0, l_sq=>0, title=>"FASTA",
	       ws_name =>"fasta",ws_opt => {stype => 'protein'}},
	      {pgm=>"fad", label=>"FASTA: DNA:DNA", binary=>"fasta36 -n -T 16", q_sq=>1, l_sq=>1, title => "FASTA",
	       ws_name=>'fasta', ws_opt => {stype => 'dna'}},
	      {pgm=>"fx", label=>"FASTX: DNA vs protein", binary=>"fastx36 -T 16", q_sq=>1, l_sq=>0, title=>"FASTX",
	       ws_name=>'fastx', ws_opt => {stype => 'dna'}},
	      {pgm=>"fy", label=>"FASTY: DNA vs protein", binary=>"fasty36 -T 16", q_sq=>1 , l_sq=>0, title=>"FASTY",
	       ws_name=>'fasty', ws_opt => {stype => 'dna'}},
	      {pgm=>"tfx", label=>"TFASTX: protein vs DNA", binary=>"tfastx36 -T 16", q_sq=>0, l_sq=>1, title=>"TFASTX",
	       ws_name=>'tfastx', ws_opt => {stype => 'protein'}},
	      {pgm=>"tfy", label=>"TFASTY: protein vs DNA", binary=>"tfasty36 -T 16", q_sq=>0, l_sq=>1, title=>"TFASTY",
	       ws_name=>'tfasty', ws_opt => {stype => 'protein'}},
	      {pgm=>"fs", label=>"FASTS: unordered peptides vs protein", binary=>"fasts36 -T 16", q_sq=>0, l_sq=>0, title=>"FASTS"},
	      {pgm=>"tfs", label=>"TFASTS: unordered peptides vs DNA", binary=>"tfasts36 -T 16", q_sq=>0, l_sq=>1, title=>"TFASTS"},
	      {pgm=>"ff", label=>"FASTF: mixed peptides vs protein", binary=>"fastf36 -T 16", q_sq=>0, l_sq=>0, title=>"FASTF"},
	      {pgm=>"tff", label=>"TFASTF: mixed peptides vs DNA ", binary=>"tfastf36 -T 16", q_sq=>0, l_sq=>1, title=>"TFASTF"},
	      {pgm=>"fmd", label=>"FASTM: ordered oligonucleotides vs DNA", binary=>"fastm36 -n -T 16", q_sq=>1, l_sq=>1, title=>"FASTA"},
	      {pgm=>"fsd", label=>"FASTS: unordered oligonucleotides vs :DNA", binary=>"fasts36 -n -T 16", q_sq=>1, l_sq=>1, title=>"FASTA"}
	      );

@pgm_slist = ({pgm=>"sw", label=>"SSEARCH: local protein:protein", binary=>"ssearch36 -p -T 16", q_sq=>0, l_sq=>0, title=>"SSEARCH",
	       ws_name=>'ssearch', ws_opt => {stype => 'protein'}},
	      {pgm=>"gnw", label=>"GGSEARCH: global protein:protein", binary=>"ggsearch36 -p -T 16", q_sq=>0, l_sq=>0, title=>"GGSEARCH",
	       ws_name=>'ggsearch', ws_opt => {stype => 'protein'}},
	      {pgm=>"lnw", label=>"GLSEARCH: global/local protein:protein", binary=>"glsearch36 -p -T 16", q_sq=>0, l_sq=>0, title=>"GLSEARCH",
	       ws_name=>'glsearch', ws_opt => {stype => 'protein'}},
	      );

@pgm_pssmlist = ({pgm=>"psi2sw", label=>"PSI-SEARCH2: protein:protein", binary=>"psisearch2_msa.pl", q_sq=>0, l_sq=>0, title=>"PSI-SSEARCH2"},
		 {pgm=>"pbp", label=>"PSI-BLAST(old): protein:protein", binary=>"blastpgp", q_sq=>0, l_sq=>0, title=>"PSI-BLAST"},
		 {pgm=>"pbp2", label=>"PSI-BLAST2: protein:protein", binary=>"psiblast", q_sq=>0, l_sq=>0, title=>"PSI-BLAST2"},
		 {pgm=>"jkhs", label=>"JACK-HMMER: protein:protein", binary=>"jackhmmer", q_sq=>0, l_sq=>0, title=>"JACK-HMMER"},
		 {pgm=>"pbp2", label=>"PSI-BLAST+: protein:protein", binary=>"psiblast", q_sq=>0, l_sq=>0, title=>"PSI-BLAST2"},
#		 {pgm=>"pgg", label=>"PSI-GGSEARCH: protein:protein", binary=>\&build_run_pssm, q_sq=>0, l_sq=>0, title=>"PSI-GGSEARCH"},
#		 {pgm=>"pgl", label=>"PSI-GLSEARCH: protein:protein", binary=>\&build_run_pssm, q_sq=>0, l_sq=>0, title=>"PSI-GLSEARCH"},
		 );

@pgm_pssmlist2 = (
    {pgm=>"pbp2", label=>"PSI-BLAST2: protein:protein", binary=>"psiblast", q_sq=>0, l_sq=>0, title=>"PSI-BLAST2"},
    );

@pgm_psi2list = (
		 {pgm=>"psi2sw", label=>"PSI-SEARCH2: protein:protein", binary=>"psisearch2_msa.pl", q_sq=>0, l_sq=>0, title=>"PSI-SEARCH2"},
		);

%pgm_pssm_br = ( psw => 'ssearch36',
		 pgg => 'ggsearch36',
		 pgl => 'glsearch36',
	       );

@pgm_shuff_list = ({pgm=>"rss", label=>"PRSS: protein:protein", binary=>"ssearch36 -p -T 16", q_sq=>0, l_sq=>0, title=>"PRSS"},
		   {pgm=>"rssd", label=>"PRSS: DNA:DNA", binary=>"ssearch36 -n -T 16", q_sq=>1, l_sq=>1, title=>"PRSS"},
		   {pgm=>"rfx", label=>"PRFX: DNA:protein", binary=>"fastx36 -T 16", q_sq=>1, l_sq=>0, title=>"PRFX"},
		   );

@pgm_lalign_list = (
    {pgm=>"lpal", label=>"LALIGN/PLALIGN: protein:protein", binary=>"lalign36 -T 16", q_sq=>0, l_sq=>0, title=>"LALIGN/PLALIGN"},
    {pgm=>"lal", label=>"LALIGN: protein:protein", binary=>"lalign36 -T 16", q_sq=>0, l_sq=>0, title=>"LALIGN"},
    {pgm=>"pal", label=>"PLALIGN: plot protein:protein", binary=>"lalign36 -T 16", q_sq=>0, l_sq=>0, title=>"PLALIGN"},
    {pgm=>"", label=>"---", binary=>"lalign36 -T 16", q_sq=>0, l_sq=>0, title=>"PLALIGN"},
    {pgm=>"lpald", label=>"LALIGN/PLALIGN: DNA:DNA", binary=>"lalign36 -T 16", q_sq=>1, l_sq=>1, title=>"LALIGN/PLALIGN"},
    {pgm=>"lald", label=>"LALIGN: DNA:DNA", binary=>"lalign36 -T 16", q_sq=>1, l_sq=>1, title=>"LALIGN"},
    {pgm=>"pald", label=>"PLALIGN: plot DNA:DNA", binary=>"lalign36 -T 16", q_sq=>1, l_sq=>1, title=>"PLALIGN"},
    );

@pgm_mlist =
  (
   {pgm=>"pkd", label=>"Kyte-Doolittle Hydropathy plot", binary=>"psgrease", q_sq=>0, l_sq=>0, title=>"K-D Hydropathy"},
   {pgm=>"gor", label=>"Garnier Secondary Structure prediction", binary=>"garnier", q_sq=>0, l_sq=>0, title=>"GARNIER"},
   {pgm=>"cho", label=>"Chou-Fasman Secondary Structure prediction", binary=>"chofas", q_sq=>0, l_sq=>0, title=>"CHOU-FASMAN"},
   {pgm=>"seg", label=>"Pseg low-complexity filter", binary=>"pseg", q_sq=>0, l_sq=>0, title=>"SEG LOW-COMPLEXITY"},
  );

@pgm_hlist = ({pgm=>"fa", label=>"", binary=>'fasta36', q_sq=>0, l_sq=>0, title=>"FASTA"});

@pgm_blist =
  (
   {pgm=>"bp", label=>"BLASTP: protein vs protein", binary=>"blastp_annot_cmd.sh --html=1", q_sq=>0, l_sq=>0, title=>"BLASTP"},
   # {pgm=>"bn", label=>"BLASTN: DNA vs DNA", binary=>"blastall -p blastn", q_sq=>1, l_sq=>1, title=>"BLASTN"},
   {pgm=>"bx", label=>"BLASTX: DNA vs protein", binary=>"blastp_annot_cmd.sh --html=1 --pgm=blastx", q_sq=>0, l_sq=>0, title=>"BLASTX"},
   # {pgm=>"tn", label=>"TBLASTN: protein vs DNA", binary=>"blastall -p tblastn", q_sq=>0, l_sq=>1, title=>"TBLASTN"},
  );

@pgm_phlist =
  (
   ["phmm", "PHMMER: protein vs protein", "phmmer --F1 0.2 --F2 0.01 --F3 0.001", 0, 0, "PHMMER"],
   ["jkhs", "JACK-HMMER: protein:protein", "jackhmmer", 0, 0, "JACK-HMMER"],
  );

@pgm_hmmlist = (
	      {pgm=>"hmms", label=>"HMMSEARCH: hmm:protein", binary=>"hmmsearch", q_sq=>0, l_sq=>0, title=>"HMMSEARCH"},
	      {pgm=>"jkhs", label=>"JACK-HMMER: protein:protein", binary=>"jackhmmer", q_sq=>0, l_sq=>0, title=>"JACK-HMMER"},
	     );

@blp_list = (
	     ["a","PIR1 Annotated (rel. 66)","pir1_bl"],
             ["p","QFO20 (150K)","qfo20_bl"],
	     ["q","QFO78 (0.9M)","pfam34_qfo78_bl"],
	     ["s","Swissprot (550K)","uniprot_sprot_bl"],
	     ["d","PDBaa (structures)","pdbaa"],
	     ["t","Shuffled Swissprot","random_sprot"],
    	     ["l","Arabidopsis (Uniprot)", "a_thaliana_sp"],
    	     ["c","Cassava (JGI)", "m_esculenta"],
	     );

@hmmp_list = (
	      ["a","PIR1 Annotated (rel. 66)","pir1"],
              ["p","QFO20 (150K)","qfo20"],
	      ["q","QFO78 (0.9M)","pfam34_qfo78"],
	      ["s","Swissprot (Uniprot)","uniprot_sprot"],
	      ["d","PDB Structures (NCBI)","pdbaa_pdb"],
#	      ["s","NCBI Refseq Proteins","refseq_protein"],
#	      ["n","NCBI nr","nr"],
	      ["w","Wormpep","wormpep"],
	     );

@ws_libs = (
#	    {abbr=>'p',desc=>"PIR1",val=>"pir1"},
	    {abbr=>'h',desc=>"UniprotKB Human",val=>"uniprotkb_human"},
	    {abbr=>'s',desc=>"UniprotKB SwissProt",val=>"uniprotkb_swissprot"},
	    {abbr=>'m',desc=>"MACie",val=>"macie_annot.pub"},
	    {abbr=>'u',desc=>"UniprotKB (all)",val=>"uniprotkb"},
	   );

%smatrix_vals = ( 0 => "BL50",
		  1 => "P250",
		  2 => "VT200",
		  3 => "OPT5",
		  4 => "BP62",
		  5 => "VT160",
		  6 => "VT120",
		  7 => "BL80",
		  8 => "VT80",
		  9 => "VT40",
		  10 => "MD40",
		  11 => "VT20",
		  12 => "MD20-MS",
		  13 => "VT10",
		  14 => "MD10-MS",

		  21 => "+5/-4",
		  22 => "+4/-12",
		  23 => "+4/-4",
		  24 => "+4/-8");

%bmatrix_vals = ( 1 => "BLOSUM62",
		  2 => "BLOSUM80",
		  3 => "PAM70",
		  4 => "PAM30",
		  5 => "BLOSUM45",
		   );

$test_aa = <<EOF;
>GTT1_DROME GLUTATHIONE S-TRANSFERASE 1-1 (EC 2.5.1.18) (CLASS-THETA). - DROS
MVDFYYLPGSSPCRSVIMTAKAVGVELNKKLLNLQAGEHLKPEFLKINPQHTIPTLVDNGFALWESRAIQVYLVEKYG
KTDSLYPKCPKKRAVINQRLYFDMGTLYQSFANYYYPQVFAKAPADPEAFKKIEAAFEFLNTFLEGQDYAAGDSLTVA
DIALVATVSTFEVAKFEISKYANVNRWYENAKKVTPGWEENWAGCLEFKKYFE 
EOF

1;
