package Geo::IPinfo;

use 5.006;
use strict;
use warnings;
use Cache::LRU;
use LWP::UserAgent;
use HTTP::Headers;
use JSON;
use File::Share ':all';
use Geo::Response;

our $VERSION = '1.0';
my $DEFAULT_CACHE_MAX_SIZE = 4096;
my $DEFAULT_CACHE_TTL = 86400;
my $DEFAULT_COUNTRY_FILE = 'countries.json';
my $DEFAULT_TIMEOUT = 2;

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
                    geo => 1
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
  $self->{ua}->ssl_opts("verify_hostname" => 0);
  $self->{ua}->default_headers(HTTP::Headers->new(
    Accept => "application/json",
    Authorization =>  "Bearer " . $token
  ));
  $self->{ua}->agent("IPinfoClient/Perl/$VERSION");

  my $timeout = defined $options{"timeout"} ? $options{"timeout"} : $DEFAULT_TIMEOUT;
  $self->{ua}->timeout($timeout);

  $self->{message} = "";

  bless($self, $pkg);

  $self->{countries} = $self->_get_countries(%options);
  $self->{cache} = $self->_build_cache(%options);

  return $self;
}

#-------------------------------------------------------------------------------

sub info
{
  my ($self, $ip) = @_;

  return $self->_get_info($ip, "");
}

#-------------------------------------------------------------------------------

sub geo
{
  my ($self, $ip) = @_;

  return $self->_get_info($ip, "geo");
}

#-------------------------------------------------------------------------------

sub field
{
  my ($self, $ip, $field) = @_;

  if (not defined $field)
  {
    $self->{message} = "Field must be defined.";
    return undef;
  }

  if (not defined $valid_fields{$field})
  {
    $self->{message} = "Invalid field: $field";
    return undef;
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

  $ip = defined $ip ? $ip : "";
  $field = defined $field ? $field : "";

  my ($info, $message) = $self->_lookup_info($ip, $field);
  $self->{message} = $message;

  return defined $info ? Geo::Response->new($info) : undef;
}

sub _lookup_info
{
  my ($self, $ip, $field) = @_;

  my $key = $ip . "/" . $field;
  my $cached_info = $self->_lookup_info_from_cache($key);

  if (defined $cached_info)
  {
    return ($cached_info, "");
  }

  my ($source_info, $message) = $self->_lookup_info_from_source($key);
  if (not defined $source_info)
  {
    return ($source_info, $message);
  }

  my $country = $source_info->{"country"};
  if (defined $country)
  {
    $source_info->{"country_name"} = $self->{countries}->{$country};
  }

  if (defined $source_info->{"loc"})
  {
    my ($lat, $lon) = split(/,/, $source_info->{"loc"});
    $source_info->{"latitude"} = $lat;
    $source_info->{"longitude"} = $lon;
  }

  $source_info->{"meta"} = {"time" => time(), "from_cache" => 0};
  $self->{cache}->set($key, $source_info);

  return ($source_info, $message);
}

sub _lookup_info_from_cache
{
  my ($self, $cache_key) = @_;

  my $cached_info = $self->{cache}->get($cache_key);
  if (defined $cached_info)
  {
    my $timedelta = time() - $cached_info->{"meta"}->{"time"};
    if ($timedelta <= $cache_ttl || $custom_cache == 1)
    {
      $cached_info->{"meta"}->{"from_cache"} = 1;

      return $cached_info;
    }
  }

  return undef;
}

sub _lookup_info_from_source
{
  my ($self, $key) = @_;

  my $url = $self->{base_url} . $key;
  my $response = $self->{ua}->get($url);

  if ($response->is_success)
  {
    print $response->decoded_content;
    my $info = from_json($response->decoded_content);

    return ($info, "");
  }
  if ($response->code == 429)
  {
    return (undef, "Your monthly request quota has been exceeded.");
  }

  return (undef, $response->status_line);
}

sub _get_countries
{
  my ($pkg, %options) = @_;
  my $filename = undef;
  my $data_location = undef;
  if (defined $options{'countries'})
  {
    $filename = $options{'countries'};
    $data_location = $filename;
  }
  else
  {
    $filename = $DEFAULT_COUNTRY_FILE;
    $data_location = dist_file('Geo-IPinfo', $filename);
  }

  my $json_text = do {
    open(my $fh, '<', $data_location)
      or die "Could not open file: $filename $!\n";
    local $/;
    <$fh>;
  };

  return decode_json($json_text);
}

sub _build_cache
{
  my ($pkg, %options) = @_;

  if (defined $options{'cache'})
  {
    $custom_cache = 1;

    return $options{'cache'};
  }

  $cache_ttl = $DEFAULT_CACHE_TTL;
  if (defined $options{'cache_ttl'})
  {
      $cache_ttl = $options{'cache_ttl'};
  }

  return Cache::LRU->new(
    size => defined $options{'cache_max_size'} ?
      $options{'cache_max_size'} : $DEFAULT_CACHE_MAX_SIZE
  );
}
#-------------------------------------------------------------------------------

1;
__END__


=head1 NAME

Geo::IPinfo -  Official Perl module to use ipinfo.io geolocation services

=head1 VERSION

Version 1.0
  - Initial release

=cut

=head1 SYNOPSIS

Geo::IP provides an object-oriented perl interface to https://ipinfo.io geolocation services

A quick usage example:

    use Geo::IPinfo;

    my $token = "1234567";

    # if you have a valid token, use it
    my $ipinfo = Geo::IPinfo->new($token);

    # or, if you don't have a token, use this:
    # my $ipinfo = Geo::IPinfo->new();

    # return a hash reference containing all IP related information
    my $data = $ipinfo->info("8.8.8.8");

    if (defined $data)   # valid data returned
    {
      print "Information about IP 8.8.8.8:\n";
      for my $key (sort keys %$data )
      {
        printf "%10s : %s\n", $key, $data->{$key};
      }
      print "\n";
    }
    else   # invalid data obtained, show error message
    {
      print $ipinfo->error_msg . "\n";
    }

    # retrieve only city information of the IP address
    my $city = $ipinfo->field("8.8.8.8", "city");

    print "The city of 8.8.8.8 is $city\n";



=head1 SUBROUTINES/METHODS

=head2 new([token])

Create an ipinfo object. The 'token' argument (string value) is optional.

If 'token' is specified, then it's used to overcome the default
non-commercial limitation of 1,000 request/day (For more details, see L<https://ipinfo.io/pricing>)

=cut

=head2 info(ip_address)

Returns a reference to a hash containing all information related to the IP address. In case
of errors, returns undef, the error message can be retrieved with the function 'error_msg()'

The values returned are: ip, hostname, city, region, country, loc, org

=head2 geo(ip_address)

Returns a reference to a hash containing only the geolocation related data. Returns undef
in case of errors, the error message can be retrieved with the function 'error_msg'

It's usually faster than getting the full response using 'info()'

The values returned are: ip, loc, city, region, country

=head2 field(ip_address, field_name)

Returns a string with the contents of field_name for the specified IP address. Returns undef
if the field is invalid

The possible values of 'field_name' are: ip, hostname, city, region, country, loc, org

=head2 error_msg( )

Returns a string containing the error message of the last operation, it returns an empty
string if the last operation was successful

=cut

sub function2 {
}

=head1 AUTHOR

Ben Dowling, C<< <ben at change.me> >>

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

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 ipinfo.io.

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
