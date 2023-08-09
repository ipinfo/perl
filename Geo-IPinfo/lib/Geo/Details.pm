package Geo::Details;

use 5.006;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $data  = shift;
    my $key   = shift // '';

   # If $data is a hash reference, directly bless it into the class and return.
    if ( ref($data) eq 'HASH' ) {
        bless $data, $class;
        return $data;
    }

    # If $data is a plain string, create a new hash reference and set the specified key to the string value.
    # Use the provided key or default to ''.
    my $self = { $key => $data };
    bless $self, $class;
    return $self;
}

sub TO_JSON {
    my ($self) = @_;
    # Return a copy of the object as a hash reference for JSON encoding
    return { %$self };
}

sub abuse {
    return $_[0]->{abuse};
}

sub ip {
    return $_[0]->{ip};
}

sub org {
    return $_[0]->{org};
}

sub domains {
    return $_[0]->{domains};
}

sub privacy {
    return $_[0]->{privacy};
}

sub timezone {
    return $_[0]->{timezone};
}

sub hostname {
    return $_[0]->{hostname};
}

sub city {
    return $_[0]->{city};
}

sub region {
    return $_[0]->{region};
}

sub country {
    return $_[0]->{country};
}

sub country_name {
    return $_[0]->{country_name};
}

sub country_flag {
    return $_[0]->{country_flag};
}

sub country_flag_url {
    return $_[0]->{country_flag_url};
}

sub country_currency {
    return $_[0]->{country_currency};
}

sub continent {
    return $_[0]->{continent};
}

sub is_eu {
    return $_[0]->{is_eu};
}

sub loc {
    return $_[0]->{loc};
}

sub latitude {
    return $_[0]->{latitude};
}

sub longitude {
    return $_[0]->{longitude};
}

sub postal {
    return $_[0]->{postal};
}

sub asn {
    return $_[0]->{asn};
}

sub company {
    return $_[0]->{company};
}

sub carrier {
    return $_[0]->{carrier};
}

sub meta {
    return $_[0]->{meta};
}

sub all {
    return $_[0];
}

#-------------------------------------------------------------------------------

1;
__END__


=head1 NAME

Geo::Details - Module to represent details of a geographical location

=head1 SYNOPSIS

    use Geo::Details;

    my $data = {
        ip            => '169.48.204.140',
        city          => 'Dallas',
        country       => 'US',
        country_name  => 'United States',
        hostname      => '8c.cc.30a9.ip4.static.sl-reverse.com',
        country_flag_url => 'https://example.com/us.png', # URL to the country flag image
        # ... (other attributes)
    };

    my $geo_details = Geo::Details->new($data);

    print $geo_details->ip;           # Output: 192.168.1.1
    print $geo_details->city;         # Output: New York
    print $geo_details->country_name; # Output: United States

=head1 DESCRIPTION

Geo::Details is a simple module that represents details of a geographical location.

=head1 METHODS

=head2 new

    my $geo_details = Geo::Details->new($data, $key);

Creates a new Geo::Details object. If C<$data> is a hash reference, it directly blesses it into the class and returns the object. If C<$data> is a plain string, it creates a new hash reference with the specified key and sets the string value.

C<$key> is an optional parameter used when C<$data> is a plain string. It defaults to an empty string if not provided.

=head2 abuse

    my $abuse_email = $geo_details->abuse();

Returns the abuse contact email address associated with the geographical location.

=head2 ip

    my $ip_address = $geo_details->ip();

Returns the IP address associated with the geographical location.

=head2 org

    my $organization = $geo_details->org();

Returns the organization associated with the geographical location.

=head2 domains

    my $domains_ref = $geo_details->domains();

Returns a reference to an array containing the domain names associated with the IP address.

=head2 privacy

    my $privacy_policy = $geo_details->privacy();

Returns the privacy policy related to the geographical location.

=head2 timezone

    my $timezone = $geo_details->timezone();

Returns the timezone information of the geographical location.

=head2 hostname

    my $hostname = $geo_details->hostname();

Returns the hostname associated with the IP address.

=head2 city

    my $city_name = $geo_details->city();

Returns the city name of the geographical location.

=head2 region

    my $region_name = $geo_details->region();

Returns the region or state name of the geographical location.

=head2 country

    my $country_code = $geo_details->country();

Returns the ISO 3166-1 alpha-2 code of the country associated with the geographical location.

=head2 country_name

    my $country_name = $geo_details->country_name();

Returns the full name of the country associated with the geographical location.

=head2 country_flag

    my $country_flag_code = $geo_details->country_flag();

Returns the ISO 3166-1 alpha-2 code for the country flag associated with the geographical location.

=head2 country_flag_url

    my $flag_url = $geo_details->country_flag_url();

Returns the URL to the country flag image associated with the geographical location.

=head2 country_currency

    my $currency_code = $geo_details->country_currency();

Returns the currency code used in the country associated with the geographical location.

=head2 continent

    my $continent_code = $geo_details->continent();

Returns the continent code of the geographical location.

=head2 is_eu

    my $is_eu_country = $geo_details->is_eu();

Returns true if the country associated with the geographical location is in the European Union (EU).

=head2 loc

    my $location_string = $geo_details->loc();

Returns a string representing the latitude and longitude of the geographical location.

=head2 latitude

    my $latitude = $geo_details->latitude();

Returns the latitude coordinate of the geographical location.

=head2 longitude

    my $longitude = $geo_details->longitude();

Returns the longitude coordinate of the geographical location.

=head2 postal

    my $postal_code = $geo_details->postal();

Returns the postal or ZIP code associated with the geographical location.

=head2 asn

    my $asn_number = $geo_details->asn();

Returns the Autonomous System Number (ASN) associated with the IP address.

=head2 company

    my $company_name = $geo_details->company();

Returns the name of the company or organization associated with the geographical location.

=head2 carrier

    my $carrier_name = $geo_details->carrier();

Returns the name of the carrier or internet service provider (ISP) associated with the IP address.

=head2 meta

    my $meta_data_ref = $geo_details->meta();

Returns a reference to the meta-data hash containing additional information about the geographical location.

=head2 all

    my $all_details_ref = $geo_details->all();

Returns a reference to the hash containing all the details of the geographical location.

=head1 AUTHOR

Your Name <your.email@example.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

# End of Geo::Details
