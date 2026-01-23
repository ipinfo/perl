#!perl -T

use strict;
use warnings;
use Test::More;

if ( $ENV{RELEASE_TESTING} ) {
    plan tests => 10;
}
else {
    plan( skip_all => "Basic usage tests not required for installation" );
}

use_ok('Geo::IPinfo');
use Test::Mock::LWP::Dispatch;
use HTTP::Response;

my $ip;

# Set up mock responses
$mock_ua->map(
    qr{https://ipinfo\.io/resproxy/175\.107\.211\.204},
    sub {
        my $response = HTTP::Response->new(200);
        $response->header('Content-Type' => 'application/json');
        $response->content('{"ip":"175.107.211.204","last_seen":"2025-01-20","percent_days_seen":0.85,"service":"example_service"}');
        return $response;
    }
);

$mock_ua->map(
    qr{https://ipinfo\.io/resproxy/8\.8\.8\.8},
    sub {
        my $response = HTTP::Response->new(200);
        $response->header('Content-Type' => 'application/json');
        $response->content('{}');
        return $response;
    }
);

$ip = Geo::IPinfo->new("test_token");
isa_ok( $ip, "Geo::IPinfo", '$ip' );

# Test resproxy with known residential proxy IP
my $resproxy = $ip->resproxy("175.107.211.204");
ok( $resproxy, "resproxy() returns data for known residential proxy IP" );
is( $resproxy->{ip}, "175.107.211.204", "IP field is correct" );
is( $resproxy->{last_seen}, "2025-01-20", "last_seen field is correct" );
is( $resproxy->{percent_days_seen}, 0.85, "percent_days_seen field is correct" );
is( $resproxy->{service}, "example_service", "service field is correct" );

# Test resproxy with IP that returns empty response
my $empty_resproxy = $ip->resproxy("8.8.8.8");
ok( $empty_resproxy, "resproxy() returns data for 8.8.8.8" );
ok( !exists $empty_resproxy->{ip}, "ip field does not exist for 8.8.8.8" );

# Test resproxy with invalid IP
is( $ip->resproxy("1000.1000.1.1"),
    undef, "resproxy() returns undef for invalid IP" );
