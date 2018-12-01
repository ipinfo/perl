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

  return defined $info ? Geo::Details->new($info) : undef;
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
