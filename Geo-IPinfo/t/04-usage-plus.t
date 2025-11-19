#!perl -T

use strict;
use warnings;
use Test::More;

if ( $ENV{RELEASE_TESTING} ) {
    plan tests => 37;
}
else {
    plan( skip_all => "Basic usage tests not required for installation" );
}

use_ok('Geo::IPinfoPlus');

my $ip;

$ip = Geo::IPinfoPlus->new( token => $ENV{IPINFO_TOKEN} );
isa_ok( $ip, "Geo::IPinfoPlus", '$ip' );

ok($ip->info(), "info() works with no IP");

ok( $ip->info("8.8.8.8"), "info() return an object when querying a valid IP" );

is( $ip->info("1000.1000.1.1"),
    undef, "info() return undef when querying an invalid IP" );

# Test 8.8.8.8
my $details = $ip->info( '8.8.8.8' );
ok( $details, "Got details for 8.8.8.8" );
is( $details->ip, "8.8.8.8", "IP field is correct" );
is( $details->hostname, "dns.google", "Hostname is correct" );

# Test geo fields
ok( $details->geo, "geo object exists" );
is( $details->geo->city, "Mountain View", "City is correct" );
is( $details->geo->region, "California", "Region is correct" );
is( $details->geo->region_code, "CA", "Region code is correct" );
is( $details->geo->country, "United States", "Country is correct" );
is( $details->geo->country_code, "US", "Country code is correct" );
is( $details->geo->continent, "North America", "Continent is correct" );
is( $details->geo->continent_code, "NA", "Continent code is correct" );
ok( defined $details->geo->latitude, "Latitude is defined" );
ok( defined $details->geo->longitude, "Longitude is defined" );
is( $details->geo->timezone, "America/Los_Angeles", "Timezone is correct" );
is( $details->geo->postal_code, "94043", "Postal code is correct" );

# Test AS fields
ok( $details->as, "as object exists" );
is( $details->as->asn, "AS15169", "ASN is correct" );
is( $details->as->name, "Google LLC", "AS name is correct" );
is( $details->as->domain, "google.com", "AS domain is correct" );
is( $details->as->type, "hosting", "AS type is correct" );

# Test network flags
ok( defined $details->is_anonymous, "is_anonymous is defined" );
ok( defined $details->is_anycast, "is_anycast is defined" );
ok( defined $details->is_hosting, "is_hosting is defined" );
ok( defined $details->is_mobile, "is_mobile is defined" );
ok( defined $details->is_satellite, "is_satellite is defined" );

# Test anonymous object
ok( $details->anonymous, "anonymous object exists" );
ok( defined $details->anonymous->is_proxy, "anonymous is_proxy is defined" );
ok( defined $details->anonymous->is_relay, "anonymous is_relay is defined" );
ok( defined $details->anonymous->is_tor, "anonymous is_tor is defined" );
ok( defined $details->anonymous->is_vpn, "anonymous is_vpn is defined" );

# Test mobile object
ok( defined $details->mobile, "mobile object is defined" );


# Test bogon
my $bogon_details = $ip->info( '127.0.0.1' );
ok( $bogon_details->bogon, "Bogon IP detected" );
