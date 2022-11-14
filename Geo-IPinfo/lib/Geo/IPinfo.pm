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

our $VERSION = '1.0';
use constant DEFAULT_CACHE_MAX_SIZE => 4096;
use constant DEFAULT_CACHE_TTL => 86_400;
use constant DEFAULT_COUNTRY_FILE => 'countries.json';
use constant DEFAULT_EU_COUNTRY_FILE => 'eu.json';
use constant DEFAULT_COUNTRY_FLAG_FILE => 'flags.json';
use constant DEFAULT_COUNTRY_CURRENCY_FILE => 'currency.json';
use constant DEFAULT_CONTINENT_FILE => 'continent.json';
use constant DEFAULT_TIMEOUT => 2;
use constant HTTP_TOO_MANY_REQUEST => 429;

my %valid_fields = (
                    ip => 1,
                    hostname => 1,
                    city => 1,
                    region => 1,
                    country => 1,
                    loc => 1,
                    org => 1,
                    postal => 1,
                    phone => 1,
                    geo => 1,
                );
my $base_url = 'https://ipinfo.io/';

my $cache_ttl = 0;
my $custom_cache = 0;

#-------------------------------------------------------------------------------

sub new
{
  my ($pkg, $token, %options) = @_;

  my $self = {};

  $self->{base_url} = $base_url;
  $self->{ua} = LWP::UserAgent->new;
  $self->{ua}->ssl_opts('verify_hostname' => 0);
  $self->{ua}->default_headers(HTTP::Headers->new(
    Accept => 'application/json',
    Authorization =>  'Bearer ' . $token
  ));
  $self->{ua}->agent("IPinfoClient/Perl/$VERSION");

  my $timeout = defined $options{timeout} ? $options{timeout} : DEFAULT_TIMEOUT;
  $self->{ua}->timeout($timeout);

  $self->{message} = '';

  bless $self, $pkg;
  
  my $country_file_path = undef;
  my $eu_country_file_path = undef;
  my $countries_flags_file_path = undef;
  my $countries_currencies_file_path = undef;
  my $continent_file_path = undef;
  if (defined $options{countries}){
    $country_file_path = $options{countries};
  }else{
    $country_file_path = dist_file('Geo-IPinfo', DEFAULT_COUNTRY_FILE);
  }
  if (defined $options{eu_countries}){
    $eu_country_file_path = $options{eu_countries};
  }else{
    $eu_country_file_path = dist_file('Geo-IPinfo', DEFAULT_EU_COUNTRY_FILE);
  }
  if (defined $options{countries_flags}){
    $countries_flags_file_path = $options{countries_flags};
  }else{
    $countries_flags_file_path = dist_file('Geo-IPinfo', DEFAULT_COUNTRY_FLAG_FILE);
  }
  if (defined $options{countries_currencies}){
    $countries_currencies_file_path = $options{countries_currencies};
  }else{
    $countries_currencies_file_path = dist_file('Geo-IPinfo', DEFAULT_COUNTRY_CURRENCY_FILE);
  }
  if (defined $options{continents}){
    $continent_file_path = $options{continents};
  }else{
    $continent_file_path = dist_file('Geo-IPinfo', DEFAULT_CONTINENT_FILE);
  }
  $self->{countries} = $self->_read_json($country_file_path);
  $self->{eu_countries} = $self->_read_json($eu_country_file_path);
  $self->{countries_flags} = $self->_read_json($countries_flags_file_path);
  $self->{countries_currencies} = $self->_read_json($countries_currencies_file_path);
  $self->{continents} = $self->_read_json($continent_file_path);
  $self->{cache} = $self->_build_cache(%options);

  return $self;
}

#-------------------------------------------------------------------------------

sub info
{
  my ($self, $ip) = @_;

  return $self->_get_info($ip, '');
}

#-------------------------------------------------------------------------------

sub geo
{
  my ($self, $ip) = @_;

  return $self->_get_info($ip, 'geo');
}

#-------------------------------------------------------------------------------

sub field
{
  my ($self, $ip, $field) = @_;

  if (not defined $field)
  {
    $self->{message} = 'Field must be defined.';
    return;
  }

  if (not defined $valid_fields{$field})
  {
    $self->{message} = "Invalid field: $field";
    return;
  }

  return $self->_get_info($ip, $field);
}

#-------------------------------------------------------------------------------

sub error_msg
{
  my $self = shift;

  return $self->{message};
}

#-------------------------------------------------------------------------------
#-- private method(s) below , don't call them directly -------------------------

sub _get_info
{
  my ($self, $ip, $field) = @_;

  $ip = defined $ip ? $ip : '';
  $field = defined $field ? $field : '';

  my ($info, $message) = $self->_lookup_info($ip, $field);
  $self->{message} = $message;

  return defined $info ? Geo::Details->new($info) : undef;
}

sub _lookup_info
{
  my ($self, $ip, $field) = @_;

  my $key = $ip . '/' . $field;
  my $cached_info = $self->_lookup_info_from_cache($key);

  if (defined $cached_info)
  {
    return ($cached_info, '');
  }

  my ($source_info, $message) = $self->_lookup_info_from_source($key);
  if (not defined $source_info)
  {
    return ($source_info, $message);
  }

  my $country = $source_info->{country};
  if (defined $country)
  {
    $source_info->{country_name} = $self->{countries}->{$country};
    $source_info->{country_flag} = $self->{countries_flags}->{$country};
    $source_info->{country_currency} = $self->{countries_currencies}->{$country};
    $source_info->{continent} = $self->{continents}->{$country};
    if ( $country ~~ $self->{eu_countries} ){
      $source_info->{is_eu} = "True";
    }else {
      $source_info->{is_eu} = undef;
    }
  }

  if (defined $source_info->{'loc'})
  {
    my ($lat, $lon) = split /,/, $source_info->{loc};
    $source_info->{latitude} = $lat;
    $source_info->{longitude} = $lon;
  }

  $source_info->{meta} = {time => time(), from_cache => 0};
  $self->{cache}->set($key, $source_info);

  return ($source_info, $message);
}

sub _lookup_info_from_cache
{
  my ($self, $cache_key) = @_;

  my $cached_info = $self->{cache}->get($cache_key);
  if (defined $cached_info)
  {
    my $timedelta = time() - $cached_info->{meta}->{time};
    if ($timedelta <= $cache_ttl || $custom_cache == 1)
    {
      $cached_info->{meta}->{from_cache} = 1;

      return $cached_info;
    }
  }

  return;
}

sub _lookup_info_from_source
{
  my ($self, $key) = @_;

  my $url = $self->{base_url} . $key;
  my $response = $self->{ua}->get($url);

  if ($response->is_success)
  {
   
    my $info = from_json($response->decoded_content);

    return ($info, '');
  }
  if ($response->code == HTTP_TOO_MANY_REQUEST)
  {
    return (undef, 'Your monthly request quota has been exceeded.');
  }

  return (undef, $response->status_line);
}

sub _read_json
{
  my ($pkg, $file) = @_;

  my $json_text = do {
    open my $fh, '<', $file or die "Could not open file: $file $!\n";
    local $/;
    <$fh>;
  };

  return decode_json($json_text);
}

sub _build_cache
{
  my ($pkg, %options) = @_;

  if (defined $options{cache})
  {
    $custom_cache = 1;

    return $options{cache};
  }

  $cache_ttl = DEFAULT_CACHE_TTL;
  if (defined $options{cache_ttl})
  {
      $cache_ttl = $options{cache_ttl};
  }

  return Cache::LRU->new(
    size => defined $options{cache_max_size} ?
      $options{cache_max_size} : DEFAULT_CACHE_MAX_SIZE
  );
}
#-------------------------------------------------------------------------------

1;
__END__


=head1 NAME

Geo::IPinfo -  The official Perl library for IPinfo.

=head1 VERSION

Version 2.0.0
  - Included support for country names and caching.

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

The values can be accessed with the named methods: ip, hostname, city, region, country, country_name, loc, latitude, longitude, postal, asn, company, carrier, and all.

=head2 geo(ip_address)

Returns a reference to an object containing only the geolocation related data. Returns undef
in case of errors, the error message can be retrieved with the function 'error_msg'

It's usually faster than getting the full response using 'info()'

The values returned are: ip, loc, city, region, country

=head2 field(ip_address, field_name)

Returns a reference to an object containing only the field related data. Returns undef
if the field is invalid

The possible values of 'field_name' are: ip, hostname, city, region, country, loc, org

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
