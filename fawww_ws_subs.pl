
# Base URL for service
my $baseUrl = 'http://wwwdev.ebi.ac.uk/Tools/services/rest/fasta';

my $scriptName = "fasta_ws.cgi";

sub rest_request {
	my $requestUrl = shift;

	# Create a user agent
	my $ua = LWP::UserAgent->new();
	'$Revision: 1779 $' =~ m/(\d+)/;
	$ua->agent( "EBI-Sample-Client/$1 ($scriptName; $OSNAME) " . $ua->agent() );
	$ua->env_proxy;

	# Perform the request
	my $response = $ua->get($requestUrl);

	# Check for HTTP error codes
	if ( $response->is_error ) {
		$response->content() =~ m/<h1>([^<]+)<\/h1>/;
		die 'http status: '
		  . $response->code . ' '
		  . $response->message . '  '
		  . $1;
	}
	# Return the response data
	return $response->content();
}

sub rest_run {
	my $email  = shift;
	my $title  = shift;
	my $params = shift;

	# User agent to perform http requests
	my $ua = LWP::UserAgent->new();
	$ua->env_proxy;

	# Clean up parameters
	my (%tmp_params) = %{$params};
	$tmp_params{'email'} = $email;
	$tmp_params{'title'} = $title;
	foreach my $param_name ( keys(%tmp_params) ) {
		if ( !defined( $tmp_params{$param_name} ) ) {
			delete $tmp_params{$param_name};
		}
	}

	# Submit the job as a POST
	my $url = $baseUrl . '/run';
	my $response = $ua->post( $url, \%tmp_params );

	# Check for HTTP error codes
	if ( $response->is_error ) {
	    warn "response error -- query is: $tmp_params{'sequence'}\n";
	    $response->content() =~ m/<h1>([^<]+)<\/h1>/;
	    die 'http status: '
		. $response->code . ' '
		. $response->message . '  '
		. $1;
	}

	# The job id is returned
	my $job_id = $response->content();
	return $job_id;
}

sub rest_get_status {
	my $job_id = shift;
	my $status_str = 'UNKNOWN';
	my $url        = $baseUrl . '/status/' . $job_id;
	$status_str = &rest_request($url);
	return $status_str;
}

sub rest_get_result {
	my $job_id = shift;
	my $type   = shift;
	my $url    = $baseUrl . '/result/' . $job_id . '/' . $type;
	my $result = &rest_request($url);
	return $result;
}

1;
