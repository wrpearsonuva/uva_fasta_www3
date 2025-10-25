#!/bin/csh
#
# show menus:
#
foreach m ( select compare shuffle lalign blast misc1 )
fasta_www.cgi rm=$m query=gstm1_human > ${m}_menu.html
end
echo "test fasta search"
# test fasta search
fasta_www.cgi rm=search pgm=fa query=gstm1_human q_type=acc p_lib=a > fa1_res.html
fasta_www.cgi rm=search pgm=sw query=gstm1_human q_type=acc p_lib=a > sw1_res.html
#
echo "test blast search"
# test blast search
#
fasta_www.cgi rm=blast_r pgm=bp query=gstm1_human q_type=acc p_lib=a > bp_res.html
fasta_www.cgi rm=blast_r pgm=bp query=gstm1_human q_type=acc p_lib=a  smatrix=4 open=16 ext=2 > bp2_res.html
# compare two sequences
#
echo "test compare2 sequences"
fasta_www.cgi rm=compare_r pgm=sw query=gstt1_drome q_type=acc query2=gsta1_human q2_type=acc > comp2_res.html
#
# shuffle
#
echo "test shuffle"
fasta_www.cgi rm=shuffle_r pgm=rss query=gstt1_drome q_type=acc query2=gsta1_human q2_type=acc > prss_res.html
# lalign
#
echo "test lalign"
fasta_www.cgi rm=lalign_r pgm=lal query=calm_human q_type=acc query2=calm_human q2_type=acc > lal_res.html
# test seg
echo "test seg"
fasta_www.cgi rm=misc1_rx pgm=seg query=gstm1_human q_type=acc seg_domain=1 >seg1_res.html
fasta_www.cgi rm=misc1_rx pgm=seg query=gstm1_human q_type=acc seg_domain=2 >seg2_res.html
# test cho
echo "test cho"
fasta_www.cgi rm=misc1_rx pgm=cho query=gstm1_human q_type=acc > cho_res.html
# test gor
echo "test gor"
fasta_www.cgi rm=misc1_rx pgm=gor query=gstm1_human q_type=acc > gor_res.html
