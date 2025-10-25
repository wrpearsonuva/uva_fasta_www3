#!/bin/csh

cp fawww_defs.pl fawww_defs.tmp
cp fasta_www.cgi fasta_www.cgi.tmp
svn update
mv fawww_defs.pl fawww_defs.svn
mv fawww_defs.tmp fawww_defs.pl
mv fasta_www.cgi fasta_www.cgi.svn
mv fasta_www.cgi.tmp fasta_www.cgi

