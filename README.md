# [<img src="https://ipinfo.io/static/ipinfo-small.svg" alt="IPinfo" width="24"/>](https://ipinfo.io/) IPinfo Perl Client Library

This is the official Perl client library for the [IPinfo.io](https://ipinfo.io) IP address API, allowing you to look up your own IP address, or get any of the following details for an IP:

- [IP to Geolocation](https://ipinfo.io/ip-geolocation-api) (city, region, country, postal code, latitude, and longitude)
- [IP to ASN](https://ipinfo.io/asn-api) (ISP or network operator, associated domain name, and type, such as business, hosting, or company)
- [IP to Company](https://ipinfo.io/ip-company-api) (the name and domain of the business that uses the IP address)
- [IP to Carrier](https://ipinfo.io/ip-carrier-api) (the name of the mobile carrier and MNC and MCC for that carrier if the IP is used exclusively for mobile traffic)

Check all the data we have for your IP address [here](https://ipinfo.io/what-is-my-ip).

### Getting Started

You'll need an IPinfo API access token, which you can get by signing up for a free account at [https://ipinfo.io/signup](https://ipinfo.io/signup).

The free plan is limited to 50,000 requests per month, and doesn't include some of the data fields such as IP type and company data. To enable all the data fields and additional request volumes see [https://ipinfo.io/pricing](https://ipinfo.io/pricing)

The library also supports the Lite API, see the [Lite API section](#lite-api) for more info.

#### Installation

Using `cpanm` install the `Geo::IPinfo` module:

    $ cpanm Geo::IPinfo

Add this line to your application code:

```perl
use Geo::IPinfo;
```

If you'd like to install from source (not necessary for use in your application), download the source and run the following commands:

    perl Makefile.PL
    make
    make test
    make install

#### Quick Start

```perl
use Geo::IPinfo;

$access_token = '123456789abc';
$ipinfo = Geo::IPinfo->new($access_token);

$ip_address = '216.239.36.21';
$details = $ipinfo->info($ip_address);
$city = $details->city; # Emeryville
$loc = $details->loc; # 37.8342,-122.2900
```

#### Dependencies

- Cache::LRU
- JSON
- LWP::UserAgent
- HTTP::Headers
- Net::CIDR
- Net::CIDR::Set

#### Usage

The `Geo::IPinfo->info()` method accepts an IPv4 address as an optional, positional argument. If no IP address is specified, the API will return data for the IP address from which it receives the request. The `Geo::IPinfo->info_v6()` method works in a similar fashion but for IPv6 addresses.

```perl
use Geo::IPinfo;

$access_token = '123456789abc';
$ipinfo = Geo::IPinfo->new($access_token);
$details = $ipinfo->info($ip_address);
# for IPv6
# $details = $ipinfo->info_v6($ip_address);

if (defined $details)   # valid data returned
{
  $city = $details->city; # Emeryville
  $loc = $details->loc; # 37.8342,-122.2900
}
else   # invalid data obtained, show error message
{
  print $ipinfo->error_msg . "\n";
}
```

If the `Details` object is empty the error message can be accessed via `Geo::IPinfo->error_msg`.

#### Authentication

The IPinfo library can be authenticated with your IPinfo API token, which is passed in as a positional argument. It also works without an authentication token, but in a more limited capacity.

```perl
$access_token = '123456789abc';
$ipinfo = Geo::IPinfo->new($access_token);
```

#### Details Data

`Geo::IPinfo->info()` and `Geo::IPinfo->info_v6()` will return a `Details` object that contains all fields listed in the [IPinfo developer docs](https://ipinfo.io/developers/responses#full-response) with a few minor additions. Properties can be accessed through methods of the same name.

```perl
$hostname = $details->hostname; # cpe-104-175-221-247.socal.res.rr.com
```

##### Country Name

`Details->country_name` will return the country name. See below for instructions on changing these country names for use with non-English languages. `Details->country` will still return the country code.

```perl
$country = $details->country; # US
$country_name = $details->country_name; # United States
```

#### IP Address

`Details->ip_address` will return the `IPAddr` object from the [Perl Standard Library](https://perl-doc.org/stdlib-2.5.1/libdoc/ipaddr/rdoc/IPAddr.html). `Details->ip` will still return a string.

```perl
$ip = $details->ip; # 104.175.221.247
$ip_addr = $details->ip_address; # <IPAddr: IPv4:104.175.221.247/255.255.255.255>
```

##### Longitude and Latitude

`Details->latitude` and `Details->longitude` will return latitude and longitude, respectively, as strings. `Details->loc` will still return a composite string of both values.

```perl
$loc = $details->loc; # 34.0293,-118.3570
$lat = $details->latitude; # 34.0293
$lon = $details->longitude; # -118.3570
```

##### Accessing all properties

`Details->all` will return all details data as a dictionary.

```perl
$details->all = {
  "ip": "104.175.221.247",
  "hostname": "cpe-104-175-221-247.socal.res.rr.com",
  "city": "Los Angeles",
  "region": "California",
  "country": "US",
  "loc": "34.0290,-118.4000",
  "postal": "90034",
  "asn": {
    "asn": "AS20001",
    "name": "Time Warner Cable Internet LLC",
    "domain": "twcable.com",
    "route": "104.172.0.0/14",
    "type": "isp"
  },
  "company": {
    "name": "Time Warner Cable Internet LLC",
    "domain": "twcable.com",
    "type": "isp"
  }
}
```

### Lite API

The library gives the possibility to use the [Lite API](https://ipinfo.io/developers/lite-api) too, authentication with your token is still required.

The returned details are slightly different from the Core API.

```perl
use Geo::IPinfoLite;

$access_token = '123456789abc';
$ipinfo = Geo::IPinfo->new($access_token);

$ip_address = '216.239.36.21';
$details = $ipinfo->info($ip_address);
$country_code = $details->country_code; # US
$country = $details->country; # United States
```

#### Caching

In-memory caching of `Details` data is provided by default via the [Cache::LRU](https://metacpan.org/pod/Cache::LRU) package. This uses an LRU (least recently used) cache with a TTL (time to live) by default. This means that values will be cached for the specified duration; if the cache's max size is reached, cache values will be invalidated as necessary, starting with the oldest cached value.

##### Modifying cache options

Cache behavior can be modified with the `%options` argument.

- Default maximum cache size: 4096 (multiples of 2 are recommended to increase efficiency)
- Default TTL: 24 hours (in seconds)

```perl
$token = '1234';
$ipinfo = Geo::IPinfo->new($token, ("cache_ttl" => 100, "cache_max_size" => 1000));
```

##### Using a different cache

It's possible to use a custom cache by passing this into the handler object with the `cache` option. A custom cache must include the following methods:

- $custom_cache->get($key);
- $custom_cache->set($key, $value);

If a custom cache is used then the `cache_ttl` and `cache_max_size` options will not be used.

```perl
$ipinfo = Geo::IPinfo->new($token, ("cache" => $my_custom_cache));
```

### Request options

The request timeout period can be set in the `%options` parameter.

- Default request timeout: 2 seconds

```perl
$ipinfo = Geo::IPinfo->new($token, ("timeout" => 5));
```

#### Internationalization

When looking up an IP address, the `$details` object includes a `$details->country_name` method which includes the country name based on American English, `$details->is_eu` method which returns `true` if the country is a member of the European Union (EU) else `undef`, `$details->country_flag` method which returns a dictionary of emoji and Unicode of the country's flag, `$details->country_flag_url` will return a public link to the country's flag image as an SVG which can be used anywhere and `$details->country_currency` method which returns a dictionary of code, the symbol of a country's currency and `$details->continent` which includes code and name of the continent. It is possible to return the country name in other languages, change the EU countries, countries flags, countries' currencies, and continents by setting the `countries`, `eu_countries`, `countries_flags`, `countries_currencies` and `continents` settings when creating the `IPinfo` object. The `countries`, `countries_flags`, `countries_currencies`, and `continents` are hashes while `eu_countries` is an array.

```perl
my %custom_countries = (
    "US" => "Custom United States",
    "DE" => "Custom Germany"
);
my @custom_eu_countries = ( "FR", "DE" );
my %custom_countries_flags = (
    'AD' => { 'emoji' => '🇦🇩', 'unicode' => 'U+1F1E6 U+1F1E9' },
    'AE' => { 'emoji' => '🇦🇪', 'unicode' => 'U+1F1E6 U+1F1EA' }
);
my %custom_countries_currencies = (
    'AD' => { 'code' => 'EUR', 'symbol' => '€' },
    'AE' => { 'code' => 'AED', 'symbol' => 'د.إ' }
);
my %custom_continents = (
    "BE" => { "code" => "EU", "name" => "Europe" },
    "BF" => { "code" => "AF", "name" => "Africa" }
);

$ipinfo = Geo::IPinfo->new($token, countries => \%custom_countries);
$ipinfo = Geo::IPinfo->new($token, eu_countries => \@custom_eu_countries);
$ipinfo = Geo::IPinfo->new($token, countries_flags => \%custom_countries_flags);
$ipinfo = Geo::IPinfo->new($token, countries_currencies => \%custom_countries_currencies);
$ipinfo = Geo::IPinfo->new($token, continents => \%custom_continents);
```

### Additional Information

Additional package information can be found at the following locations:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-IPinfo

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Geo-IPinfo

    CPAN Ratings
        http://cpanratings.perl.org/d/Geo-IPinfo

    Search CPAN
        http://search.cpan.org/dist/Geo-IPinfo/

### Other Libraries

There are [official IPinfo client libraries](https://ipinfo.io/developers/libraries) available for many languages including PHP, Go, Java, Ruby, and many popular frameworks such as Django, Rails, and Laravel. There are also many third-party libraries and integrations available for our API.

### About IPinfo

Founded in 2013, IPinfo prides itself on being the most reliable, accurate, and in-depth source of IP address data available anywhere. We process terabytes of data to produce our custom IP geolocation, company, carrier, privacy detection, Reverse IP, hosted domains, and IP type data sets. Our API handles over 40 billion requests a month for 100,000 businesses and developers.

[![image](https://avatars3.githubusercontent.com/u/15721521?s=128&u=7bb7dde5c4991335fb234e68a30971944abc6bf3&v=4)](https://ipinfo.io/)

SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Geo::IPinfo
