#!/usr/bin/perl
#
use strict;
use warnings;

use lib 'Geo-IPinfo/lib';

use Geo::IPinfo;
use Data::Dumper;
use JSON;

my $token = '1234567';
my %custom_countries = (
    "US" => "Custom United States",
    "DE" => "Custom Germany"
);
my @custom_eu_countries = ( "FR", "DE" );

# if you have a valid token, use it
my $ipinfo = Geo::IPinfo->new($token);

# or, if you don't have a token, use this:
# my $ipinfo = Geo::IPinfo->new();

# provide your own countries and eu countries
my $ipinfo = Geo::IPinfo->new($token, countries => \%custom_countries, eu_countries => \@custom_eu_countries);

# return a hash reference containing all IP related information
my $data = $ipinfo->info('8.8.8.8');

if ( defined $data )    # valid data returned
{
# use Data::Dumper to see the contents of the hash reference (useful for debugging)
    print Dumper($data);

    # loop and print key-value paris
    print "\nInformation about IP 8.8.8.8:\n";
    for my $key ( sort keys %{$data} ) {
        printf "%10s : %s\n", $key,
          defined $data->{$key} ? $data->{$key} : "N/A";
    }
    print "\n";

    # print JSON string
    my $json        = JSON->new->allow_blessed->convert_blessed;
    my $json_string = $json->utf8->pretty->encode($data);
    print $json_string . "\n";
}
else    # invalid data obtained, show error message
{
    print $ipinfo->error_msg . "\n";
}

# retrieve only city information of the IP address
my $details = $ipinfo->field( '8.8.8.8', 'city' );

print "The city of 8.8.8.8 is " . $details->city . "\n";

