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

my $ip;

$ip = Geo::IPinfo->new( $ENV{IPINFO_TOKEN} );
isa_ok( $ip, "Geo::IPinfo", '$ip' );

ok( $ip->info("8.8.8.8"), "info() return a hash when querying a valid IP" );

is( $ip->info("1000.1000.1.1"),
    undef, "info() return undef when querying an invalid IP" );

is( $ip->field("8.8.8.8"),
    undef, "field() return undef if 'field' is missing" );

my $details = $ip->field( '8.8.8.8', 'city' );
my $city    = $details->city;
is(
    $city,
    "Mountain View",
    "field() return a valid string when querying a valid IP"
);
is( $ip->field( "192.168.0.1", "city" ),
    undef, "field() return 'undef' when getting fields of private IPs" );

ok($ip->info( '2001:4860:4860::8888', 'city' ), "info() works with compressed IPv6");
ok($ip->info( '2001:4860:4860:0:0:0:0:8888', 'city' ), "info() works with short expanded IPv6");
ok($ip->info( '2001:4860:4860:0000:0000:0000:0000:8888', 'city' ), "info() works with long expanded IPv6");
