#!/usr/bin/perl -w

use strict;
use LWP::Simple;

use vars qw( $DEF_UNLINK $OK_CHARS $ALT_HOST_CGI $HOST_NAME $CGI_DIR
	     $RUN_URL $SS_ALT_HOST_CGI $SS_HOST_NAME $SS_CGI_DIR
	     $SS_RUN_URL $BIN_DIR @NODE_HOSTS $NODE_EXT $NODE_RUN_CGI
	     $NODE_STATUS_FILE $NODE_RUN_DIR
	     $USE_REMOTE $DEBUG $FAST_LIBS $FAST_GNMS $TMP_DIR
	     $GS_BIN $BL_BIN_DIR $BL_DB_DIR $BL_DB_NT_DIR $BL_DATA_DIR
	     $fa_footer);

require "fawww_defs.pl";

#open(FH, ">$NODE_STATUS_FILE") || die "Cannot open $NODE_STATUS_FILE";

for my $nodes ( @NODE_HOSTS ) {

  my $n_host = $nodes . $NODE_EXT;

  print get("http://$n_host/$NODE_RUN_DIR/load.cgi");
}

#close(FH);
