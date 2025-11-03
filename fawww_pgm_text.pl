#
# $Id: fawww_pgm_text.pl 35 2009-10-28 18:29:25Z wrp $

$select_text = <<EOS
This page provides searches against comprehensive databases, like
<b>SwissProt</b> and <b>NCBI RefSeq</b>.  The <b>PIR1 Annotated</b> database can be used
for small, demonstration searches.  The <b>NCBI nr</b> database is
also provided, but should be your last choice for searching, because
its size greatly reduces sensitivity.  The best first choice for
searching is a genome database from a closely related organism
(e.g. <b>RefSeq Human</b> for vertebrates).
<p>
The <a href="fasta_www.cgi?rm=selectg">Individual
Proteomes/Genomes</a> page provides searches against selected prokaryotes.
</p>
<p>
<!--#include virtual="fasta_page_inc.html" -->
</p>
EOS
    ;

$select_opt1 = <<EOS ;
<td align="center">
Compare your own sequences:<br />
<input type="submit" name="compare2" value="Compare sequences" onclick="this.form.rm.value='compare'; this.form.action='fasta_www.cgi'; this.form.target='_self';" />
</td>
EOS

$psi2_select_opt1 = "<td>&nbsp;</td>";

$psi2_select_opt2 = <<EOS ;
<td align="center">
Query seeding options:<br />
End residues: <select name="end_mask">
 <option value="none">None</option>
 <option value="query" selected='selected'>Query seeded</option>
 <option value="random">Random seeded</option>
</select>
<br />
Internal residues: <select name="int_mask">
 <option value="none">None</option>
 <option value="query" selected='selected'>Query seeded</option>
 <option value="random">Random seeded</option>
</select>
</td>
<td>
<b>Inclusion E():</b><br />
<select name="pssm_eval">
  <option value="1e-4">1e-4</option>
  <option value="2e-4">2e-4</option>
  <option value="5e-4">5e-4</option>
  <option value="0.001" selected="selected">0.001</option>
  <option value="0.002">0.002</option>
  <option value="0.005">0.005</option>
  <option value="0.010">0.010</option>
  <option value="0.020">0.020</option>
  <option value="0.050">0.050</option>
</select>
<br />&nbsp;<br />
</td>
EOS


$select_opt2 = <<EOS
<td>
<b>Statistical&nbsp;estimates</b><br />
<select name = "zstat">
<option value="DEFAULT" selected="selected"> Default</option>
<option value="1"> Regress</option>
<option value="2"> MLE</option>
<option value="3"> Altshul-Gish</option>
<option value="11"> Regress/shuf.</option>
<option value="12"> MLE/shuf.</option>
<option value="21"> Best Regress/shuf2</option>
<option value="22"> Best MLE/shuf2</option>
</select>
</td>
EOS
    ;

$lib_opt = <<EOS
<input type="checkbox" name="segflag" value="1" checked="checked" />Exclude low complexity (seg)
<input type="checkbox" name="exp_iso" value="1" />Include isoforms
EOS
  ;

$selectg_text = <<EOS
This page provides a selection of prokaryotic and fungal genomes, as well as
<i>C. elegans</i> and <i>Drosophila</i>.  Complete mammalian genomes
are available on the <a href="fasta_www.cgi?rm=select">Comprehensive
Database</a> FASTA search page.
<p>
<!--#include virtual="fasta_page_inc.html" -->
</p>
EOS
    ;

$misc_text = <<EOS
The Kyte-Doolittle, Garnier-Osguthorpe-Robson, and
Chou-Fasman programs are available for teaching purposes;
much better transmembrane prediction and secondary prediction programs are available.
<p>
<a href="http://bioinf.cs.ucl.ac.uk/psipred/" target="pred_win">memstat</a> and <a href="http://www.ch.embnet.org/software/TMPRED_form.html">TMpred</a> are more accurate transmembrane predictors
</p>
<p>
<a href="http://bioinf.cs.ucl.ac.uk/psipred/" target="pred_win">psipred</a> and <a href="http://cubic.bioc.columbia.edu/predictprotein/">PredictProtein</a> produce much more accurate secondary structure predictions.
</p>
EOS
    ;

$comp_text = <<EOS
<b>Compare two sequences</b> aligns two sequences using the indicated algorithm, and calculates the statistical significance using shuffled sequences.
<!--
<p>
<a href="https://fasta.bioch.virginia.edu/noptalign/start.cgi" target="nopt">Near-optimal global alignments</a> are also available <a href="https://fasta.bioch.virginia.edu/noptalign/start.cgi" target="nopt">here</a>.
</p>
-->
<p>
<!--#include virtual="fasta_page_inc.html" -->
</p>
EOS
    ;

$comp_opt1 = <<EOS
<td align="center">
<input type="checkbox" name="annot_seq1" value="2"/>Annotate Sequence 1 / <a target='help_win' href="annot_file_fmt.html">Upload&nbsp;File:</a>&nbsp;<input type="file" name="annot_seq1_file"/><br />
<input type="checkbox" name="annot_seq2" value="2"/>Annotate Sequence 2 / Upload&nbsp;File:&nbsp;<input type="file" name="annot_seq2_file"/> <br /><br />
<input type="checkbox" name="posttrans" value="1" />
Query post-trans modifications<br />
<tt>"*@?#^~+="</tt> included for annotation
</td>
EOS
    ;

$comp_opt2 = <<EOS
<td>
<b>Ktup:</b><br />
<select name="ktup">
  <option value="2" selected="selected">ktup = 2</option>
  <option value="1">ktup = 1</option>
</select>
</td>
EOS
    ;

$comp_opt3 = <<EOS
<td>
<table>
<tr>
<th colspan="2" align="left">Output&nbsp;limits:</th>
</tr>
<tr>
<td align="left"><b>E():</b><br /><select name="ev_lim" />
<option value='1e-10'>1E-10</option>
<option value='1e-6'>1E-6</option>
<option value='1e-3'>0.001</option>
<option value='1e-2'>0.01</option>
<option value='1e-1'>0.1</option>
<option value='1.0' >1.0</option>
<option value='2.0'>2.0</option>
<option value='5.0'>5.0</option>
<option value='10' selected>10.</option>
<option value='20' >20.</option>
<option value='100'>100</option>
</select></td>
</tr>
<!--
<tr>
<td align="left">
Highlight <input type="radio" name="aln_type" value="1" checked="checked" /> similarities</input> <input type="radio" name="aln_type" value="2" /> differences.
</td>
</tr>
-->
</table>
</td>
EOS
    ;

$select_opt3 = <<EOS
<td>
<table>
<tr>
<th colspan="2" align="left">Output&nbsp;limits:</th><th align="center">Max</th><td><input type="checkbox" name='show_hist' value='1' />Show Histogram</td>
</tr>
<tr>
<td><b>E():</b><br /><select name="ev_lim">
<option value='1e-10'>1E-10</option>
<option value='1e-6'>1E-6</option>
<option value='1e-3'>0.001</option>
<option value='1e-2'>0.01</option>
<option value='1e-1'>0.1</option>
<option value='1.0'>1.0</option>
<option value='2.0' selected>2.0</option>
<option value='5.0'>5.0</option>
<option value='5.0' selected>5.0</option>
<option value='10'>10</option>
<option value='20'>20</option>
<option value='100'>100</option>
</select>
<!-- <input type="text" name="eval" maxlength="8" size="5" /> -->
</td>
<td><b>Best&nbsp;E():</b><br /><input type="text" name="etop" maxlength="8" size="5" /></td>
<td><b>aligns:</b><br /><input type="text" name="max_align" maxlength="6" size="4" /></td>
<td>&nbsp;<br /><input type="checkbox" name="hide_align" value='1' />Hide Alignments</td>
</tr>
</table>
</td>
</tr>
EOS
;

$select_opt3_rmch = <<EOS
<td>
<table>
<tr>
<th colspan="2" align="left">Output&nbsp;limits:</th><th align="center">Max</th><td><input type="checkbox" name='show_hist' value='1' />Show Histogram</td>
</tr>
<tr>
<td><b>E():</b><br /><select name="ev_lim">
<option value='1e-10'>1E-10</option>
<option value='1e-6'>1E-6</option>
<option value='1e-3'>0.001</option>
<option value='1e-2'>0.01</option>
<option value='1e-1'>0.1</option>
<option value='1.0'>1.0</option>
<option value='2.0' selected>2.0</option>
<option value='5.0'>5.0</option>
<option value='10'>10</option>
<option value='100'>100</option>
</select>
<!-- <input type="text" name="eval" maxlength="8" size="5" /> -->
</td>
<td><b>Best&nbsp;E():</b><br /><input type="text" name="etop" maxlength="8" size="5" /></td>
<td><b>aligns:</b><br /><input type="text" name="max_align" maxlength="6" size="4" /></td>
<td>&nbsp;<br /><input type="checkbox" name="hide_align" value='1' checked />Hide Alignments</td>
</tr>
</table>
</td>
</tr>
EOS
;

$select_opt4 = <<EOF
<tr><td colspan="2"><hr /></td></tr>
<tr>
<td colspan="2"><b>Alignment Options:</b> Highlight
<input type="radio" name="aln_type" value="0" checked="checked" /> similarities
<input type="radio" name="aln_type" value="1" /> differences
<input type="radio" name="aln_type" value="2" /> compact differences.
&nbsp;&nbsp;&nbsp;&nbsp;
Output format:<select name="tab_format">
<option value="1" selected>FASTA</option>
<option value="2">FASTA tabular</option>
<option value="3">Blast-style aligment</option>
<option value="4">Blast tabular</option>
<option value="5">FASTA tab CIGAR</option>
<option value="6">Blast tab CIGAR</option>
</select>

</td>
</tr>
EOF
;

$shuff_text = <<EOS
<b>PRSS/PRFX</b> compute the statistical significance of an alignment
by aligning the two sequences, and then shuffling the second sequence
200 - 1000 times, and estimating the statistical significance from the
distribution of shuffled alignment scores.
<p>
Window shuffles are used to preserve local sequence composition, e.g. for transmembrane proteins.
</p>
<p>
<!--#include virtual="fasta_page_inc.html" -->
</p>
EOS
    ;

$shuff_opt1 = <<EOS
<td align="center">
<b><font color="#990000">(B) Number of shuffles:</font></b>
<select name="shuff_cnt">
<option>100</option>
<option selected="selected">200</option>
<option>500</option>
<option>1000</option>
</select>
<br />
<input type="radio" name="shuff_w" value='0' checked="checked" />Uniform
<input type="radio" name="shuff_w" value='1' />Window
</td>
EOS
    ;

$shuff_opt2 = $comp_opt2;

$shuff_msa_opt = <<EOS
<div id='asn_file'>
<table align="left">
<tr><td align="left">Upload PSSM ASN.1 file:</td>
<td align='center' rowspan="2"><a href="pssm_help.html" target="help">Help with PSSMs</a></td>
<!--
<td>Get PSSM from NCBI Blast RID:</td>
-->
</tr>
<tr>
<td><input type="file" name="msa_asn_file" /></td>
<!--
<td><input type="text" name="msa_asn_rid" size="25" /></td>
-->
</tr>
</table>
</div>
EOS
    ;

$lalign_text = <<EOS
<b>LALIGN/PLALIGN</b> find internal duplications by calculating
non-intersecting local alignments of protein or DNA
sequences. <b>LALIGN</b> shows the alignments and similarity scores,
while <b>PLALIGN</b> presents a "dot-plot" like graph.
<p>
<!--#include virtual="fasta_page_inc.html" -->
</p>
EOS
    ;

# $lalign_opt1 = <<EOS
# <td><input type="checkbox" name="show_ident" value="1" />Show identity alignment<br />
# <input type="checkbox" name="annot_seq1" value="2"/>Annotate Sequence 1 domains<br />
# <input type="checkbox" name="annot_seq2" value="2"/>Annotate Sequence 2 domains<br />
# </td>
# EOS
#     ;

$lalign_opt2 = <<EOS
<td>&nbsp;&nbsp;&nbsp;</td><td width="33%">&nbsp;</td><td><b>Output&nbsp;limits:</b><br />
<b>E():</b><input type="text" name="eval" maxlength="8" size="5" /></td>
EOS
    ;

$lalign_opt3 = <<EOS
<td><br /><input type="checkbox" name="hide_align" value='1' />Hide Alignments</td>
EOS
;

$blast_text = <<EOS
This <b>BLAST</b> website is for demonstration purposes; it provides
the same protein databases as the <a href="fasta_www.cgi">FASTA</a>
WWW site.
<p>
For reliable <b>BLAST</b> searches, use the <a
href="https://www.ncbi.nlm.nih.gov/blast/Blast.cgi">NCBI Blast</a> web
site.
</p>
<p>
<!--#include virtual="fasta_page_inc.html" -->
</p>
EOS
    ;

$blast_opt1 = <<EOS
<td align="center"><input type="checkbox" name="comp_stat" value="1" checked="checked" />Composition Statistics<br />
<input type="checkbox" name="segflag" value="1" checked="checked" />Filter (seg) low-complexity</td>
EOS
    ;

$blast_opt2 = <<EOS
<td align="left"><div id='bp_opt'>
<input type="radio" name="segflag" value="1"/>No Filter<br />
<input type="radio" name="segflag" value="2" checked="checked" />Filter out Low Complexity<br />
<input type="radio" name="segflag" value="3" />Filter low complexity in initial mask<br />
<br />
<input type="checkbox" name="comp_stat" value="1"/>Composition Statistics<br /></div>
EOS
    ;

$psiblast_text = <<EOS
This <b>PSI-BLAST</b> website is for demonstration purposes; it provides
the same protein databases as the <a href="fasta_www.cgi">FASTA</a>
WWW site, and allows one to search with either PSI-BLAST or PSI-SEARCH.
<p>
For reliable <b>BLAST</b> searches, use the <a
href="https://www.ncbi.nlm.nih.gov/blast/Blast.cgi">NCBI Blast</a> web
site.
</p>
<p>
<!--#include virtual="fasta_page_inc.html" -->
</p>
EOS
    ;

$phmmer_text = <<EOS
This <b>PHMMER</b> provides the same search libraries as <a href="fasta_www.cgi?rm=select">FASTA</a> and <a href="fasta_www.cgi?rm=blast">BLAST</a>.
</p>
<p>
<!--#include virtual="fasta_page_inc.html" -->
</p>
EOS
    ;

$hmm_select_text = <<EOS
This page provides searches of <b>HMMER</b> Hidden Markov Models
against comprehensive databases, like
<b>SwissProt</b> and <b>NCBI RefSeq</b>.  The <b>PIR1 Annotated</b> database can be used
for small, demonstration searches.  The <b>NCBI nr</b> database is
also provided, but should be your last choice for searching, because
its size greatly reduces sensitivity.  The best first choice for
searching is a genome database from a closely related organism
(e.g. <b>RefSeq Human</b> for vertebrates).
<p>
<!--#include virtual="fasta_page_inc.html" -->
</p>
EOS
    ;

$hmm_compare_text = <<EOS
Use this page to scan a <b>HMMER</b> Hidden Markov Model
against a single sequence, or a set of sequences.  Accurate statistical estimates
require HMMs calibrated with <b>hmmcalibrate</b>.
EOS
    ;

$mselect_opt1 = <<EOS
<td align="center"><div id='pbp_opt'>&nbsp;<br />
Iterations: <input type="text" name="iter" value="1" maxlength="3" size="3"/><br />
E()-threshold: <select name="pssm_eval">
  <option value="1e-4">1e-4</option>
  <option value="2e-4">2e-4</option>
  <option value="5e-4">5e-4</option>
  <option value="0.001" selected="selected">0.001</option>
  <option value="0.002">0.002</option>
  <option value="0.005">0.005</option>
  <option value="0.010">0.010</option>
  <option value="0.020">0.020</option>
  <option value="0.050">0.050</option>
</select>
</div></td>
EOS
    ;

$fa_footer_s = <<EOS ;
<center>
<a href="$RUN_URL">Search Databases with FASTA</a> |
<a href="fasta_www.cgi?rm=lalign">Find Duplications</a> |
<a href="fasta_www.cgi?rm=status">Search Status</a>
</center>
EOS


$fa_footer = <<EOS ;
<hr />
<center>
<a href="$RUN_URL">Search Databases with FASTA</a> |
<a href="fasta_www.cgi?rm=lalign">Find Duplications</a> |
<a href="fasta_www.cgi?rm=status">Search Status</a>
</center>
<hr />
EOS

$psi2_footer = <<EOS ;
<hr />
<center>
<a href="fasta_www.cgi?rm=psi2_select">Search Databases with PSI-SEARCH2</a> |
<a href="fasta_www.cgi?rm=select">Search Databases with FASTA/SSEARCH</a> |
<a href="fasta_www.cgi?rm=status">Search Status</a>
</center>
<hr />
EOS


$rmch_footer = <<EOS
<hr />
<center>
<a href="fasta_www.cgi?rm=rmch_select">Search RPD2 Database with FASTA</a> |
<a href="fasta_www.cgi?rm=lalign">Find Duplications</a> |
<a href="fasta_www.cgi?rm=status">Search Status</a>
</center>
<hr />
EOS
    ;

$fa_footer_s = <<EOS
<center>
<a href="$RUN_URL">Search Databases with FASTA</a> |
<a href="fasta_www.cgi?rm=lalign">Find Duplications</a> |
<a href="fasta_www.cgi?rm=status">Search Status</a>
</center>
EOS
    ;

$hmm_footer = <<EOS
<hr />
<center>
<a href="chaps.cgi">Run CHAPS/Build HMM</a> |
<a href="fasta_www.cgi?rm=hmm_select">Search with HMM</a> |
<a href="fasta_www.cgi?rm=hmm_select2">Scan sequences with HMM</a> |
<a href="fasta_www.cgi?rm=status">Search Status</a>
</center>
<hr />
EOS
    ;

$bl_footer = <<EOS
<hr />
<center>
<a href="fasta_www.cgi?rm=blast">Search Databases with BLAST</a> |
<a href="fasta_www.cgi?rm=mselect">Search Databases with PSI-BLAST</a> |
<a href="fasta_www.cgi?rm=select">Search Databases with FASTA </a> |
<a href="fasta_www.cgi?rm=status">Search Status</a>
</center>
<hr />
EOS
    ;

1;
