#!/bin/sh
# fasta search
fasta_www.cgi rm=search pgm=fa query=gstm1_human q_type=acc p_lib=a > fa1_res.html
# lalign
fasta_www.cgi rm=lalign_r pgm=lal query=calm_human q_type=acc query2=calm_human q2_type=acc > lal_res.html
# test seg
fasta_www.cgi rm=misc1_rx pgm=seg query=gstm1_human q_type=acc seg_domain=1 >seg1_res.html
fasta_www.cgi rm=misc1_rx pgm=seg query=gstm1_human q_type=acc seg_domain=2 >seg2_res.html
# test cho
fasta_www.cgi rm=misc1_rx pgm=cho query=gstm1_human q_type=acc > cho_res.html
# test gor
fasta_www.cgi rm=misc1_rx pgm=gor query=gstm1_human q_type=acc > gor_res.html
