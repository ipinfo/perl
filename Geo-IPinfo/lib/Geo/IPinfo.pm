package Geo::IPinfo;

use 5.006;
use strict;
use warnings;
use Cache::LRU;
use LWP::UserAgent;
use HTTP::Headers;
use JSON;
use File::Share ':all';
use Geo::Details;
use Net::CIDR::Lite;

our $VERSION = '2.1.3';
use constant DEFAULT_CACHE_MAX_SIZE        => 4096;
use constant DEFAULT_CACHE_TTL             => 86_400;
use constant DEFAULT_COUNTRY_FILE          => 'countries.json';
use constant DEFAULT_EU_COUNTRY_FILE       => 'eu.json';
use constant DEFAULT_COUNTRY_FLAG_FILE     => 'flags.json';
use constant DEFAULT_COUNTRY_CURRENCY_FILE => 'currency.json';
use constant DEFAULT_CONTINENT_FILE        => 'continent.json';
use constant DEFAULT_TIMEOUT               => 2;
use constant HTTP_TOO_MANY_REQUEST         => 429;

my %valid_fields = (
    ip               => 1,
    hostname         => 1,
    city             => 1,
    region           => 1,
    country          => 1,
    country_name     => 1,
    country_flag_url => 1,
    loc              => 1,
    latitude         => 1,
    longitude        => 1,
    org              => 1,
    postal           => 1,
    is_eu            => 1,
    timezone         => 1,
    geo              => 1,
);
my $base_url         = 'https://ipinfo.io/';
my $country_flag_url = 'https://cdn.ipinfo.io/static/images/countries-flags/';

my $cache_ttl    = 0;
my $custom_cache = 0;

#-------------------------------------------------------------------------------

sub new {
    my ( $pkg, $token, %options ) = @_;

    my $self = {};

    $self->{base_url} = $base_url;
    $self->{ua}       = LWP::UserAgent->new;
    $self->{ua}->ssl_opts( 'verify_hostname' => 0 );
    $self->{ua}->default_headers(
        HTTP::Headers->new(
            Accept        => 'application/json',
            Authorization => 'Bearer ' . $token
        )
    );
    $self->{ua}->agent("IPinfoClient/Perl/$VERSION");

    my $timeout =
      defined $options{timeout} ? $options{timeout} : DEFAULT_TIMEOUT;
    $self->{ua}->timeout($timeout);

    $self->{message} = '';

    bless $self, $pkg;

    my $country_file_path              = undef;
    my $eu_country_file_path           = undef;
    my $countries_flags_file_path      = undef;
    my $countries_currencies_file_path = undef;
    my $continent_file_path            = undef;
    if ( defined $options{countries} ) {
        $country_file_path = $options{countries};
    }
    else {
        $country_file_path = dist_file( 'Geo-IPinfo', DEFAULT_COUNTRY_FILE );
    }
    if ( defined $options{eu_countries} ) {
        $eu_country_file_path = $options{eu_countries};
    }
    else {
        $eu_country_file_path =
          dist_file( 'Geo-IPinfo', DEFAULT_EU_COUNTRY_FILE );
    }
    if ( defined $options{countries_flags} ) {
        $countries_flags_file_path = $options{countries_flags};
    }
    else {
        $countries_flags_file_path =
          dist_file( 'Geo-IPinfo', DEFAULT_COUNTRY_FLAG_FILE );
    }
    if ( defined $options{countries_currencies} ) {
        $countries_currencies_file_path = $options{countries_currencies};
    }
    else {
        $countries_currencies_file_path =
          dist_file( 'Geo-IPinfo', DEFAULT_COUNTRY_CURRENCY_FILE );
    }
    if ( defined $options{continents} ) {
        $continent_file_path = $options{continents};
    }
    else {
        $continent_file_path =
          dist_file( 'Geo-IPinfo', DEFAULT_CONTINENT_FILE );
    }
    $self->{countries}       = $self->_read_json($country_file_path);
    $self->{eu_countries}    = $self->_read_json($eu_country_file_path);
    $self->{countries_flags} = $self->_read_json($countries_flags_file_path);
    $self->{countries_currencies} =
      $self->_read_json($countries_currencies_file_path);
    $self->{continents} = $self->_read_json($continent_file_path);
    $self->{cache}      = $self->_build_cache(%options);

    return $self;
}

#-------------------------------------------------------------------------------

sub info {
    my ( $self, $ip ) = @_;

    return $self->_get_info( $ip, '' );
}

#-------------------------------------------------------------------------------

sub geo {
    my ( $self, $ip ) = @_;

    return $self->_get_info( $ip, 'geo' );
}

#-------------------------------------------------------------------------------

sub field {
    my ( $self, $ip, $field ) = @_;

    if ( not defined $field ) {
        $self->{message} = 'Field must be defined.';
        return;
    }

    if ( not defined $valid_fields{$field} ) {
        $self->{message} = "Invalid field: $field";
        return;
    }

    return $self->_get_info( $ip, $field );
}

#-------------------------------------------------------------------------------

sub error_msg {
    my $self = shift;

    return $self->{message};
}

#-------------------------------------------------------------------------------
#-- private method(s) below , don't call them directly -------------------------

sub _get_info {
    my ( $self, $ip, $field ) = @_;

    $ip    = defined $ip    ? $ip    : '';
    $field = defined $field ? $field : '';

    my ( $info, $message ) = $self->_lookup_info( $ip, $field );
    $self->{message} = $message;

    return defined $info ? Geo::Details->new( $info, $field ) : undef;
}

sub _lookup_info {
    my ( $self, $ip, $field ) = @_;

    # checking bogon IP and returning response locally.
    if ( _is_bogon($ip) ) {
        my $details = {};
        $details->{ip}    = $ip;
        $details->{bogon} = "True";
        return ( $details, '' );
    }

    my $key         = $ip . '/' . $field;
    my $cached_info = $self->_lookup_info_from_cache($key);

    if ( defined $cached_info ) {
        return ( $cached_info, '' );
    }

    my ( $source_info, $message ) = $self->_lookup_info_from_source($key);
    if ( not defined $source_info ) {
        return ( $source_info, $message );
    }

    if ( ref($source_info) eq '' ) {
        return ( $source_info, $message );
    }

    my $country = $source_info->{country};
    if ( defined $country ) {
        $source_info->{country_name} = $self->{countries}->{$country};
        $source_info->{country_flag} = $self->{countries_flags}->{$country};
        $source_info->{country_flag_url} =
          $country_flag_url . $country . ".svg";
        $source_info->{country_currency} =
          $self->{countries_currencies}->{$country};
        $source_info->{continent} = $self->{continents}->{$country};
        if ( grep { $_ eq $country } @{ $self->{eu_countries} } ) {
            $source_info->{is_eu} = "True";
        }
        else {
            $source_info->{is_eu} = undef;
        }
    }

    if ( defined $source_info->{'loc'} ) {
        my ( $lat, $lon ) = split /,/, $source_info->{loc};
        $source_info->{latitude}  = $lat;
        $source_info->{longitude} = $lon;
    }

    $source_info->{meta} = { time => time(), from_cache => 0 };
    $self->{cache}->set( $key, $source_info );

    return ( $source_info, $message );
}

sub _lookup_info_from_cache {
    my ( $self, $cache_key ) = @_;

    my $cached_info = $self->{cache}->get($cache_key);
    if ( defined $cached_info ) {
        my $timedelta = time() - $cached_info->{meta}->{time};
        if ( $timedelta <= $cache_ttl || $custom_cache == 1 ) {
            $cached_info->{meta}->{from_cache} = 1;

            return $cached_info;
        }
    }

    return;
}

sub _lookup_info_from_source {
    my ( $self, $key ) = @_;

    my $url      = $self->{base_url} . $key;
    my $response = $self->{ua}->get($url);

    if ( $response->is_success ) {

        my $content_type = $response->header('Content-Type') || '';
        my $info;

        if ( $content_type =~ m{application/json}i ) {
            eval { $info = from_json( $response->decoded_content ); };
            if ($@) {
                return ( undef, 'Error parsing JSON response.' );
            }
        }
        else {
            $info = $response->decoded_content;
            chomp($info);
        }

        return ( $info, '' );
    }
    if ( $response->code == HTTP_TOO_MANY_REQUEST ) {
        return ( undef, 'Your monthly request quota has been exceeded.' );
    }

    return ( undef, $response->status_line );
}

sub _read_json {
    my ( $pkg, $file ) = @_;

    my $json_text = do {
        open my $fh, '<', $file or die "Could not open file: $file $!\n";
        local $/;
        <$fh>;
    };

    return decode_json($json_text);
}

sub _build_cache {
    my ( $pkg, %options ) = @_;

    if ( defined $options{cache} ) {
        $custom_cache = 1;

        return $options{cache};
    }

    $cache_ttl = DEFAULT_CACHE_TTL;
    if ( defined $options{cache_ttl} ) {
        $cache_ttl = $options{cache_ttl};
    }

    return Cache::LRU->new(
        size => defined $options{cache_max_size}
        ? $options{cache_max_size}
        : DEFAULT_CACHE_MAX_SIZE
    );
}

# List of bogon CIDRs.
my @bogon_networks = (
    "0.0.0.0/8",             "10.0.0.0/8",
    "100.64.0.0/10",         "127.0.0.0/8",
    "169.254.0.0/16",        "172.16.0.0/12",
    "192.0.0.0/24",          "192.0.2.0/24",
    "192.168.0.0/16",        "198.18.0.0/15",
    "198.51.100.0/24",       "203.0.113.0/24",
    "224.0.0.0/4",           "240.0.0.0/4",
    "255.255.255.255/32",    "0:0:0:0:0:0:0:0/128",
    "0:0:0:0:0:0:0:1/128",   "0:0:0:0:0:ffff:0:0/96",
    "0:0:0:0:0:0:0:0/96",    "100::/64",
    "2001:10::/28",          "2001:db8::/32",
    "fc00::/7",              "fe80::/10",
    "fec0::/10",             "ff00::/8",
    "2002::/24",             "2002:a00::/24",
    "2002:7f00::/24",        "2002:a9fe::/32",
    "2002:ac10::/28",        "2002:c000::/40",
    "2002:c000:200::/40",    "2002:c0a8::/32",
    "2002:c612::/31",        "2002:c633:6400::/40",
    "2002:cb00:7100::/40",   "2002:e000::/20",
    "2002:f000::/20",        "2002:ffff:ffff::/48",
    "2001::/40",             "2001:0:a00::/40",
    "2001:0:7f00::/40",      "2001:0:a9fe::/48",
    "2001:0:ac10::/44",      "2001:0:c000::/56",
    "2001:0:c000:200::/56",  "2001:0:c0a8::/48",
    "2001:0:c612::/47",      "2001:0:c633:6400::/56",
    "2001:0:cb00:7100::/56", "2001:0:e000::/36",
    "2001:0:f000::/36",      "2001:0:ffff:ffff::/64"
);

# Check if an IP address is a bogon.
sub _is_bogon {

    my $ip             = shift;
    my $bogon_cidr_set = Net::CIDR::Lite->new;
    $bogon_cidr_set->add(@bogon_networks);

    return $bogon_cidr_set->find($ip);
}

#-------------------------------------------------------------------------------

1;
__END__


=head1 NAME

Geo::IPinfo -  The official Perl library for IPinfo.

=head1 VERSION

Version 2.1.3
  - Enabled JSON encoding

=cut

=head1 SYNOPSIS

Geo::IP The official Perl library for IPinfo. IPinfo prides itself on being the most reliable, accurate, and in-depth source of IP address data available anywhere. We process terabytes of data to produce our custom IP geolocation, company, carrier and IP type data sets. You can visit our developer docs at https://ipinfo.io/developers.

A quick usage example:

    use Geo::IPinfo;

    $access_token = '123456789abc';
    $ipinfo = Geo::IPinfo->new($access_token);

    $ip_address = '216.239.36.21';
    $details = $ipinfo->info($ip_address);
    $city = $details->city; # Emeryville
    $loc = $details->loc; # 37.8342,-122.2900

=head1 SUBROUTINES/METHODS

=head2 new([token], [options])

Create an ipinfo object. The 'token' (string value) and 'options' (hash value) arguments are optional.

If 'token' is specified, then it's used to overcome the default
non-commercial limitation of 1,000 request/day (For more details, see L<https://ipinfo.io/pricing>)

if 'options' is specfied, the included values will allow control over cache policies and country name localization (For more details, see L<https://github.com/ipinfo/perl>).

=cut

=head2 info(ip_address)

Returns a reference to a Details object containing all information related to the IP address. In case
of errors, returns undef, the error message can be retrieved with the function 'error_msg()'

The values can be accessed with the named methods: ip, org, domains, privacy, abuse, timezone, hostname, city, country, country_name, country_flag,
country_flag_url, country_currency, continent, is_eu, loc, latitude, longitude, postal, asn, company, meta, carrier, and all.

=head2 geo(ip_address)

Returns a reference to an object containing only the geolocation related data. Returns undef
in case of errors, the error message can be retrieved with the function 'error_msg'

It's usually faster than getting the full response using 'info()'

The values returned are: ip, city, org, loc, latitude, longitude, hostname, is_eu, country, country_name, country_flag,
country_flag_url, country_currency, meta, continent, postal, region, and timezone.

=head2 field(ip_address, field_name)

Returns a reference to an object containing only the field related data. Returns undef
if the field is invalid

The possible values of 'field_name' are: ip, hostname, city, region, country, country_name, country_flag_url,
loc, latitude, longitude, org, postal, is_eu, and timezone.

=head2 error_msg( )

Returns a string containing the error message of the last operation, it returns an empty
string if the last operation was successful

=cut

=head1 AUTHOR

Ben Dowling, C<< <ben at ipinfo dot io> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-ipinfo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-IPinfo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::IPinfo


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-IPinfo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-IPinfo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-IPinfo>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-IPinfo/>

=item * GitHub

L<https://github.com/ipinfo/perl>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 ipinfo.io.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


=cut

# End of Geo::IPinfo
