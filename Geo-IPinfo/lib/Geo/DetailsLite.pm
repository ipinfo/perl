package Geo::DetailsLite;

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
    return {%$self};
}


sub ip {
    return $_[0]->{ip};
}

sub country {
    return $_[0]->{country};
}

sub country_code {
    return $_[0]->{country_code};
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

sub continent_code {
    return $_[0]->{continent_code};
}

sub is_eu {
    return $_[0]->{is_eu};
}

sub asn {
    return $_[0]->{asn};
}

sub as_name {
    return $_[0]->{as_name};
}

sub as_domain {
    return $_[0]->{as_domain};
}

sub all {
    return $_[0];
}

#-------------------------------------------------------------------------------

1;
__END__


=head1 NAME

Geo::Details - Module to represent details of an IP returned by the Lite API

=head1 SYNOPSIS

    use Geo::Details;

    my $data = {
        ip            => '169.48.204.140',
        city          => 'Dallas',
        country       => 'United States',
        country_code  => 'US',
        country_flag_url => 'https://example.com/us.png', # URL to the country flag image
        # ... (other attributes)
    };

    my $geo_details = Geo::Details->new($data);

    print $geo_details->ip;           # Output: 169.48.204.140
    print $geo_details->country_name; # Output: United States

=head1 DESCRIPTION

Geo::Details is a simple module that represents details of an IP returned by the Lite API.

=head1 METHODS

=head2 new

    my $geo_details = Geo::Details->new($data, $key);

Creates a new Geo::Details object. If C<$data> is a hash reference, it directly blesses it into the class and returns the object. If C<$data> is a plain string, it creates a new hash reference with the specified key and sets the string value.

C<$key> is an optional parameter used when C<$data> is a plain string. It defaults to an empty string if not provided.

=head2 TO_JSON

This method is used to convert the object to a JSON representation.

=head2 ip

    my $ip_address = $geo_details->ip();

Returns the IP address associated with the details.

=head2 country_code

    my $country_code = $geo_details->country_code();

Returns the ISO 3166-1 alpha-2 code of the country associated with the geographical location.

=head2 country and country_name

    my $country = $geo_details->country();
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

    my $continent_name = $geo_details->continent();

Returns the continent name of the geographical location.

=head2 continent_code

    my $continent_code = $geo_details->continent();

Returns the continent code of the geographical location.

=head2 is_eu

    my $is_eu_country = $geo_details->is_eu();

Returns true if the country associated with the geographical location is in the European Union (EU).

=head2 asn

    my $asn_number = $geo_details->asn();

Returns the Autonomous System Number (ASN) associated with the IP address.

=head2 as_name

    my $as_name = $geo_details->as_name();

Returns the name of Autonomous System associated with the IP address.

=head2 as_domain

    my $as_domain = $geo_details->as_domain();

Returns the domain of Autonomous System associated with the IP address.

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
