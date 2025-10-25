#!/bin/csh
#
# run a series of tests on remote host
# usage test_rm.sh http://fasta.bioch.virginia.edu/fasta_www2

set rem_host=$1
if ( ! -d results) mkdir results
pushd results

foreach m ( select compare shuffle lalign blast misc1 )
curl "${rem_host}/fasta_www.cgi?rm=${m}&query=gstm1_human" > ${m}_menu.html
end
echo "test fasta search - protein"
# test fasta search
curl "${rem_host}/fasta_www.cgi?rm=search&pgm=fa&query=gstm1_human&q_type=acc&p_lib=a" > fa1_res.html
echo "test Smith-Waterman search - protein"
curl "${rem_host}/fasta_www.cgi?rm=search&pgm=sw&query=gstm1_human&q_type=acc&p_lib=a" > sw1_res.html
echo "test fasta search - DNA - fa2_res.html"
curl "${rem_host}/fasta_www.cgi?rm=search&pgm=fad&query=musgst&sq_type=2&q_type=acc&n_lib=m" > fa2_res.html
echo "test tfastx search - fa3_res.html"
curl "${rem_host}/fasta_www.cgi?rm=search&pgm=tfx&query=gstm1_human&sq_type=1&q_type=acc&n_lib=m" > tfx_res.html
#
echo "test blast search"
# test blast search
#
curl "${rem_host}/fasta_www.cgi?rm=blast_r&pgm=bp&query=gstm1_human&q_type=acc&p_lib=a" > bp_res.html
curl "${rem_host}/fasta_www.cgi?rm=blast_r&pgm=bp&query=gstm1_human&q_type=acc&p_lib=a&&smatrix=4&open=16&ext=2" > bp2_res.html
# compare two sequences
#
echo "test compare2 sequences"
curl "${rem_host}/fasta_www.cgi?rm=compare_r&pgm=sw&query=gstt1_drome&q_type=acc&query2=gsta1_human&q2_type=acc" > comp2_res.html
#
# shuffle
#
echo "test shuffle"
curl "${rem_host}/fasta_www.cgi?rm=shuffle_r&pgm=rss&query=gstt1_drome&q_type=acc&query2=gsta1_human&q2_type=acc" > prss_res.html
# lalign
#
echo "test lalign"
curl "${rem_host}/fasta_www.cgi?rm=lalign_r&pgm=lal&query=calm_human&q_type=acc&query2=calm_human&q2_type=acc" > lal_res.html
#
curl "${rem_host}/fasta_www.cgi?rm=lalign_r&pgm=pal&query=calm_human&q_type=acc&query2=calm_human&q2_type=acc" > pal_res.html
# test seg
echo "test seg"
curl "${rem_host}/fasta_www.cgi?rm=misc1_rx&pgm=seg&query=gstm1_human&q_type=acc&seg_domain=1" >seg1_res.html
curl "${rem_host}/fasta_www.cgi?rm=misc1_rx&pgm=seg&query=gstm1_human&q_type=acc&seg_domain=2" >seg2_res.html
# test cho
echo "test cho"
curl "${rem_host}/fasta_www.cgi?rm=misc1_rx&pgm=cho&query=gstm1_human&q_type=acc" > cho_res.html
# test gor
echo "test gor"
curl "${rem_host}/fasta_www.cgi?rm=misc1_rx&pgm=gor&query=gstm1_human&q_type=acc" > gor_res.html
popd
