#!perl -T

use strict;
use warnings;
use Test::More;

if ( $ENV{RELEASE_TESTING} ) {
    plan tests => 9;
}
else {
    plan( skip_all => "Basic usage tests not required for installation" );
}

use_ok('Geo::IPinfoLite');

my $ip;

$ip = Geo::IPinfoLite->new( $ENV{IPINFO_TOKEN} );
isa_ok( $ip, "Geo::IPinfoLite", '$ip' );


ok($ip->info(), "info() works with no IP");

ok( $ip->info("8.8.8.8"), "info() return a hash when querying a valid IP" );

is( $ip->info("1000.1000.1.1"),
    undef, "info() return undef when querying an invalid IP" );

my $details = $ip->info( '8.8.8.8' );
my $country    = $details->country;
is(
    $country,
    "United States",
    "field() return a valid string when querying a valid IP"
);

ok($ip->info( '2001:4860:4860::8888' ), "info() works with compressed IPv6");
ok($ip->info( '2001:4860:4860:0:0:0:0:8888' ), "info() works with short expanded IPv6");
ok($ip->info( '2001:4860:4860:0000:0000:0000:0000:8888' ), "info() works with long expanded IPv6");
