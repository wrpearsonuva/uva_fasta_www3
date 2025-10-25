#!/usr/bin/perl -w

use strict;

use lib qw(.);

use Data::Dumper;

use vars qw(%form_list);

## print(Data::Dumper->Dump([\@ARGV]));

if (defined($ARGV[0])) {
    print("require $ARGV[0]\n");
    require $ARGV[0];
}
else {
    require "./fawww_pgms.pl";
}

my $missing='OPTION1';
if (defined($ARGV[1])) {
    $missing=$ARGV[1];
}

print("$0 checking $ARGV[0] for $missing\n");

for my $form (keys(%form_list)) {

    my $output = Data::Dumper->Dump([$form_list{$form}->{'outputs'}]);

##    print("$form ::: $output\n");

    if (defined($form_list{$form}->{'outputs'})) {
    	if (!defined($form_list{$form}->{'outputs'}{$missing})) {
    	    print("$form missing $missing\n");
    	}
    }
}
