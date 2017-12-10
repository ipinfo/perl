#!perl -T

use strict;
use warnings;

use Test::More;

if ( $ENV{RELEASE_TESTING} ) 
{
  plan tests => 7;
}
else
{
  plan( skip_all => "Basic usage tests not required for installation" );
}

use_ok( 'Geo::IPinfo' ); 

my $ip;

$ip = Geo::IPinfo->new();
isa_ok($ip, "Geo::IPinfo", '$ip');

ok($ip->info("8.8.8.8"), "info() return a hash when querying a valid IP");

is($ip->info("1000.1000.1.1"), undef, "info() return undef when querying an invalid IP");

is($ip->field("8.8.8.8"), undef, "field() return undef if 'field' is missing");

is($ip->field("8.8.8.8", "city"), "Mountain View",
                          "field() return a valid string when querying a valid IP");
is($ip->field("192.168.0.1", "city"), undef,
              "field() return 'undef' when getting fields of private IPs");
