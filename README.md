# [<img src="https://ipinfo.io/static/ipinfo-small.svg" alt="IPinfo" width="24"/>](https://ipinfo.io/) IPinfo Perl Client Library

This is the official Perl client library for the [IPinfo.io](https://ipinfo.io) IP address API, allowing you to lookup your own IP address, or get any of the following details for an IP:
 - [IP to Geolocation](https://ipinfo.io/ip-geolocation-api) (city, region, country, postal code, latitude and longitude)
 - [IP to ASN](https://ipinfo.io/asn-api) (ISP or network operator, associated domain name, and type, such as business, hosting or company)
 - [IP to Company](https://ipinfo.io/ip-company-api) (the name and domain of the business that uses the IP address)
 - [IP to Carrier](https://ipinfo.io/ip-carrier-api) (the name of the mobile carrier and MNC and MCC for that carrier if the IP is used exclusively for mobile traffic)

Check all the data we have for your IP address [here](https://ipinfo.io/what-is-my-ip).

### Getting Started

You'll need an IPinfo API access token, which you can get by singing up for a free account at [https://ipinfo.io/signup](https://ipinfo.io/signup).

The free plan is limited to 50,000 requests per month, and doesn't include some of the data fields such as IP type and company data. To enable all the data fields and additional request volumes see [https://ipinfo.io/pricing](https://ipinfo.io/pricing)

#### Installation

Using `cpanm` install the `Geo::IPinfo` module:

    $ cpanm Geo::IPinfo

Add this line to your application application code:

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
  * Cache::LRU
  * File::Share
  * File::ShareDir::Install
  * JSON
  * LWP::UserAgent
  * HTTP::Headers
  * Net::CIDR::Lite

#### Usage

The `Geo::IPinfo->info()` method accepts an IP address as an optional, positional argument. If no IP address is specified, the API will return data for the IP address from which it receives the request.

```perl
use Geo::IPinfo;

$access_token = '123456789abc';
$ipinfo = Geo::IPinfo->new($access_token);
$details = $ipinfo->info($ip_address);

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

`Geo::IPinfo->info()` will return a `Details` object that contains all fields listed in the [IPinfo developer docs](https://ipinfo.io/developers/responses#full-response) with a few minor additions. Properties can be accessed through methods of the same name.

```perl
$hostname = $details->hostname; # cpe-104-175-221-247.socal.res.rr.com
```

##### Country Name

`Details->country_name` will return the country name, as supplied by the `countries.json` file. See below for instructions on changing that file for use with non-English languages. `Details->country` will still return country code.

```perl
$country = $details->country; # US
$country_name = $details->country_name; # United States
```

#### IP Address

`Details->ip_address` will return the an `IPAddr` object from the [Perl Standard Library](https://perl-doc.org/stdlib-2.5.1/libdoc/ipaddr/rdoc/IPAddr.html). `Details->ip` will still return a string.

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

#### Caching

In-memory caching of `Details` data is provided by default via the [Cache::LRU](https://metacpan.org/pod/Cache::LRU) package. This uses an LRU (least recently used) cache with a TTL (time to live) by default. This means that values will be cached for the specified duration; if the cache's max size is reached, cache values will be invalidated as necessary, starting with the oldest cached value.

##### Modifying cache options

Cache behavior can be modified with the `%options` argument.

* Default maximum cache size: 4096 (multiples of 2 are recommended to increase efficiency)
* Default TTL: 24 hours (in seconds)

```perl
$token = '1234';
$ipinfo = Geo::IPinfo->new($token, ("cache_ttl" => 100, "cache_max_size" => 1000));
```

##### Using a different cache

It's possible to use a custom cache by passing this into the handler object with the `cache` option. A custom cache must include the following methods:

* $custom_cache->get($key);
* $custom_cache->set($key, $value);

If a custom cache is used then the `cache_ttl` and `cache_max_size` options will not be used.

```perl
$ipinfo = Geo::IPinfo->new($token, ("cache" => $my_custom_cache));
```


### Request options
The request timeout period can be set in the `%options` parameter.

* Default request timeout: 2 seconds

```perl
$ipinfo = Geo::IPinfo->new($token, ("timeout" => 5));
```

#### Internationalization

When looking up an IP address, the `$details` object includes a `$details->country_name` method which includes the country name based on American English, `$details->is_eu` method which returns `true` if the country is a member of the European Union (EU) else `undef`, `$details->country_flag` method which returns dictionary of emoji and unicode of the country's flag, `$details->country_flag_url` will return a public link to the country's flag image as an SVG which can be used anywhere and `$details->country_currency` method which returns dictionary of code, symbol of a country's currency and `$details->continent` which includes code and name of the continent. It is possible to return the country name in other languages, change the EU countries, countries flags, countries currencies and continets file by setting the `countries`, `eu_countries`, `countries_flags`, `countries_currencies` and `continents` settings  when creating the `IPinfo` object.

The file must be a `.json` file with the following structure:

[countries.json](./Geo-IPinfo/share/countries.json)

[eu.json](./Geo-IPinfo/share/eu.json)

[flags.json](./Geo-IPinfo/share/flags.json)

[currency.json](./Geo-IPinfo/share/currency.json)

[continent.json](./Geo-IPinfo/share/continent.json)

```perl
$ipinfo = Geo::IPinfo->new($token, ("countries" => $path_to_countries_file));
$ipinfo = Geo::IPinfo->new($token, ("eu_countries" => $path_to_eu_countries_file));
$ipinfo = Geo::IPinfo->new($token, ("countries_flags" => $path_to_countries_flags_file));
$ipinfo = Geo::IPinfo->new($token, ("countries_currencies" => $path_to_countries_currencies_file));
$ipinfo = Geo::IPinfo->new($token, ("continents" => $path_to_continent_file));
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

There are [official IPinfo client libraries](https://ipinfo.io/developers/libraries) available for many languages including PHP, Go, Java, Ruby, and many popular frameworks such as Django, Rails and Laravel. There are also many third party libraries and integrations available for our API.

### About IPinfo

Founded in 2013, IPinfo prides itself on being the most reliable, accurate, and in-depth source of IP address data available anywhere. We process terabytes of data to produce our custom IP geolocation, company, carrier, privacy detection, Reverse IP, hosted domains, and IP type data sets. Our API handles over 40 billion requests a month for 100,000 businesses and developers.

[![image](https://avatars3.githubusercontent.com/u/15721521?s=128&u=7bb7dde5c4991335fb234e68a30971944abc6bf3&v=4)](https://ipinfo.io/)


SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Geo::IPinfo
