use strict;
use warnings;

use Test::More;

my $class = 'Geo::IPinfo';

use_ok $class;
can_ok $class, '_lookup_info';

my $ipinfo = $class->new;
isa_ok $ipinfo, $class;

my $ip = '1.1.1.1';

for (1..2) {
	my $info = $ipinfo->info($ip);
	isa_ok $info, 'Geo::Details';
	ok exists $info->{ip}, "iteration $_: value has `ip` key";
}

done_testing();

=head1 NAME

t/cache-hit.t - test that a cache hit will return the same thing as a cache miss

=head1 SYNOPSIS

Run as part of the test suite:

	perl Makefile.PL
	make test

Try it individually:

	perl -Ilib t/cache-hit.t

=head1 DESCRIPTION

In v3.0.1, calling C<info> twice on the same IP address would correctly
cache the result, but the second time, C<_lookup_info> would reprocess
the cache result and use that result as a value for a new L<Geo::Details>
object. You get something like this:

	$VAR1 = bless( {
					 '' => bless( {
									'region' => 'California',
									'is_eu' => undef,
									'longitude' => '-122.3971',
									'country' => 'US',
									'latitude' => '37.7621',
									'loc' => '37.7621,-122.3971',
									'org' => 'AS54113 Fastly, Inc.',
									'ip' => '151.101.130.132',
									'postal' => '94107',
									'continent' => {
													 'code' => 'NA',
													 'name' => 'North America'
												   },
									'country_name' => 'United States',
									'meta' => {
												'time' => 1741409047,
												'from_cache' => 1
											  },
									'timezone' => 'America/Los_Angeles',
									'country_flag_url' => 'https://cdn.ipinfo.io/static/images/countries-flags/US.svg',
									'anycast' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
									'city' => 'San Francisco',
									'country_flag' => {
														'unicode' => 'U+1F1FA U+1F1F8',
														'emoji' => '🇺🇸'
													  },
									'country_currency' => {
															'symbol' => '$',
															'code' => 'USD'
														  }
								  }, 'Geo::Details' )
				   }, 'Geo::Details' );

Instead of processing the result again, immediately return it if it
is already a L<Geo::Details> object. This test checks that it happens.

=head1 AUTHOR

brian d foy, I<briandfoy@pobox.com>

=head1 LICENSE

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

