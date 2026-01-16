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

# Test resproxy with known residential proxy IP
my $resproxy = $ip->resproxy("175.107.211.204");
ok( $resproxy, "resproxy() returns data for known residential proxy IP" );
is( $resproxy->{ip}, "175.107.211.204", "IP field is correct" );
ok( defined $resproxy->{last_seen}, "last_seen field is defined" );
ok( defined $resproxy->{percent_days_seen}, "percent_days_seen field is defined" );
ok( defined $resproxy->{service}, "service field is defined" );

# Test resproxy with IP that returns empty response
my $empty_resproxy = $ip->resproxy("8.8.8.8");
ok( $empty_resproxy, "resproxy() returns data for 8.8.8.8" );
ok( !exists $empty_resproxy->{ip}, "ip field does not exist for 8.8.8.8" );

# Test resproxy with invalid IP
is( $ip->resproxy("1000.1000.1.1"),
    undef, "resproxy() returns undef for invalid IP" );
