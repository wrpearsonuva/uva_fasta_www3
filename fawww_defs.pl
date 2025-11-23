################  fawww_defs.pl ================
# configuration parameters for the fasta_www2 web scripts
#
# $Id: fawww_defs.pl 35 2009-10-28 18:29:25Z wrp $
# $Revision: 181 $
#

# This should be the only file you need to edit to produce running scripts.
# The file has three sections:
# (1) some global defines that change often, used for debugging, but not site-specific
# (2) site-specific file locations
# (3) some definitions used for searching on remote hosts
#

################
# (1) debugging global defines
$DEF_UNLINK = 0;  # tmp files created in functions cannot be unlinked
$USE_REMOTE = 0;
$DEBUG = 0;

################
# (1a) timeout parameters
$BACK_TIMEOUT = 2400; # 40 min CPU time (5 min elapsed)
$RUN_TIMEOUT = 120; # 2 min for IPC::Run in foreground

####
# string used for sanitizing file names
#$OK_CHARS='\"\+\-a-zA-Z0-9_.@ \/%:';
$OK_CHARS='\'"=!\+\-\w\.@\s\\\\/%\:';

################
# (2) Site-specific file locations
#
####
# FASTA/BLAST binaries
$BIN_ROOT = "/app";

####
# DocumentRoot for WWW server if not defined
#$DEF_ROOT = "/var/www/html";	# MAC OSX
$DEF_ROOT = "/home/www";	# ex01
#$DEF_ROOT = "/Library/WebServer/Documents";	# MAC OSX
#$DEF_ROOT = "/home/wrp/public_html/fasta_www"; # xs00
#$DEF_ROOT = "/export/home/www";		# sun3

my $DOC_ROOT=$ENV{DOCUMENT_ROOT};
$DOC_ROOT = $DEF_ROOT unless($DOC_ROOT);

$SQL_DB_HOST="wrpa48.bioch.virginia.edu";

$ENV{SQL_DB_HOST}=$SQL_DB_HOST;

####
# variables/script used to set temporary file directory
#
$DOC_ROOT =~ s/[^$OK_CHARS]/_/go;
($DOC_ROOT) = $DOC_ROOT =~ m/^\s*(.*)/;  # de-taint and remove leading spaces
#print STDERR "ENV_DOC_ROOT: $ENV{DOCUMENT_ROOT} - DOCUMENT_ROOT: $DOC_ROOT\n";

my @TMP_ROOTL = split(/\//,$DOC_ROOT);
my $TMP_ROOT = "/".join("/",@TMP_ROOTL[1 .. ($#TMP_ROOTL-1)])."/tmp/www";

unless ($TMP_ROOT) {
##    print STDERR "TMP_ROOT not defined: " .__FILE__ . "::" . __LINE__ . "\n";    
    $TMP_ROOT = "/var/tmp/www";
}
## else {
##    print STDERR "TMP_ROOT defined: " .__FILE__ . "::" .  __LINE__ . ":: $TMP_ROOT\n";
## }

## $TMP_ROOT = "/var/tmp/www" unless ($TMP_ROOT);

####
$LOG_DIR="$TMP_ROOT/logs";	# log directory
$LOG_FILE= "$TMP_ROOT/logs/errors.log";	# error log
$TMP_DIR="$TMP_ROOT/files";	# location for temp files
$ENV{TMP_DIR} = $TMP_DIR;

## print STDERR "TMP_DIR: $TMP_DIR\n";

################
# (2) site-specific locations for program binaries
$BIN_DIR="$BIN_ROOT/bin";	# for FASTA programs
$BL_BIN_DIR="$BIN_ROOT/bin";	# for BLAST programs
$BL_DATA_DIR="$BIN_ROOT/data";	# for BLAST data
$GS_BIN="/usr/bin/gs";	# location of gs (ghostscript) binary

################
# (2) site-specific locations for blast database files
#     (FASTA database files are specified by FASTLIBS)
#
$BL_DB_DIR="/slib2/bl_dbs";
#$BL_DB_NT_DIR="/ecg/slib2/ncbi";
$BL_DB_NT_DIR="/slib2/ncbi";
$BL_DUMMY_DB="pir1";

$UP_DB_DIR="/slib2/up_dbs";

################
# (2) site-specific location/environment variables for FASTLIBS file
# default FASTLIBS location for general databases
$FAST_LIBS="/slib2/info/fast_libs_e.www";
#$ENV{'SLIB2'} = "/slib2";
#$ENV{'SLIBT'} = "/slib2/info";
#$ENV{'RDLIB2'} = "/rdlib2";
$ENV{'SLIB2'} = "/slib2";
$ENV{'SLIBT'} = "/slib2/info";
$ENV{'RDLIB2'} = "/rdlib2";
$ENV{'SLIB3'} = "/l_rdlib2";
$ENV{'DB_HOST'} = 'a48';

# FASTLIBS location for genome searches
$FAST_GNMS="/slib2/info/fast_gnms_e.www";

####
# abbreviation for default library if none specified
$DEF_LIB_AA="a";  # PIR1 - a small library for demos
$DEF_LIB_NT="m";  # Genbank mammals
# abbreviation for default library for re-search -
$DEF_RELIB_AA="q";  # on my system, "q" is swissprot.

################ end of site-specific defines for most cases ================

################
# (3) Information for distributing jobs to other nodes
####
# if present, used for distributing web jobs
$NODE_STATUS_FILE="$TMP_ROOT/logs/node_status.log";
# location of scripts on node
$NODE_RUN_DIR="/fasta_www3";
$NODE_RUN_CGI="/fasta_www3/fasta_www.cgi";
####
# list of hosts to distribute across
#@NODE_HOSTS = qw( ex01 ex01 ex02 ex02);
@NODE_HOSTS = qw( http://ex02 http://ex02 https://fasta.bioch.virginia.edu https://fasta.bioch.virginia.edu );

$NODE_EXT="";   # domain for $NODE_HOSTS, $node = $NODE_HOSTS[0] . $NODE_EXT

####
# other web sites (pfam, interpro) for links
#
## $PFAM_FAM_URL="https://pfam.xfam.org/family";
$PFAM_FAM_URL="https://www.ebi.ac.uk/interpro/entry/pfam";
$IPRO_FAM_URL="https://www.ebi.ac.uk/interpro/entry";

####  these definitions are rarely used
# additional definitions for CGI locations
# used in case things are in different places, normally empty
# the name of your FASTA WWW server
# location of fasta.htm directory
# location of fasta CGI scripts
$ALT_HOST_CGI = 0;
$HOST_NAME = "";
# $HOST_NAME = "http://wrp-rpi5.local:8080/";	# use the same host
# $HOST_NAME = "https://fastademo.bioch.virginia.edu/";	# use the same host
# $HOST_NAME = "http://localhost/";	# use the same host
## $CGI_DIR = "fasta_www3/";	# use the same directory
$CGI_DIR = "";

#$RUN_URL="fasta_www.cgi";	# fasta_www.cgi -- should not be needed,
                                # FASTA_WWW.pm has $ENV{SCRIPT_NAME}
$RUN_URL = $ENV{SCRIPT_NAME} unless ($RUN_URL);
$RUN_URL = "fasta_ws.cgi" unless($RUN_URL);

$DOMAIN_PLOT_URL = "plot_domain7.cgi";
$ENV{PLOT_PGM} = "plot_domain7.cgi";

####
# allow some searches on other hosts.  Disabled by default
$SS_ALT_HOST_CGI = 0;
$SS_HOST_NAME=$HOST_NAME;
$SS_CGI_DIR="fasta_www3/";
$SS_RUN_URL="fasta_www.cgi";
$WS_RUN_URL="fasta_ws.cgi";

# machines to do searches on (can be several ALT_HOSTS running seach_run.pl
#@ALT_HOSTS = qw( fasta.bioch.virginia.edu );
#@SS_ALT_HOSTS = qw( localhost wrpmg5c.achs.virginia.edu )

################
# end of site specific definitions
#

# message for denying access
$msg1 = <<EOF1 ;
<html>
<head>
<title>FASTA Sequence Comparison</title></head>
<p>
&nbsp;
<h3> Sorry - some FASTA programs/databases are not available to: </h3>

EOF1


################
# location for downloading code
$msg2 = <<EOF2 ;
<p>
<font size=+1>
The FASTA package can be downloaded from <A href="https://github.com/wrpearson/fasta36">
github.com/wrpearson/fasta36</a></font>
<p>
<A href="mailto:wrp\@virginia.edu">wrp\@virginia.edu</a>
<p>

EOF2

################
# log searches
sub Do_log
{
    my ($r_host, $pgm_log) = @_;

    $date = `/bin/date`;
    chop($date);
    my $log_file= $LOG_DIR . "/fasta_www.log";

    ## print STDERR "opening fasta_www.log: $log_file\n";
    ## print STDERR "log::: $date\t$r_host\t$0\t$pgm_log\n";

    open(LOG,">> $log_file") || return;
    print LOG "$date\t$r_host\t$0\t$pgm_log\n";
    close(LOG);
}


sub get_hosts {
  my $self = shift;

  my $r_host = $self->query->remote_host || "[unknown]";

  my $c_host = $self->query->server_name || `/bin/hostname`;

  chomp($c_host);
  ($c_host) = ($c_host =~ m/([^\.]+)\./);

  return ($r_host, $c_host);
}
