package Geo::DetailsCore;

use 5.006;
use strict;
use warnings;

# Helper package for Geo data
package Geo::DetailsCore::Geo {
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $data  = shift || {};
        bless $data, $class;
        return $data;
    }

    sub city { return $_[0]->{city}; }
    sub region { return $_[0]->{region}; }
    sub region_code { return $_[0]->{region_code}; }
    sub country { return $_[0]->{country}; }
    sub country_code { return $_[0]->{country_code}; }
    sub continent { return $_[0]->{continent}; }
    sub continent_code { return $_[0]->{continent_code}; }
    sub latitude { return $_[0]->{latitude}; }
    sub longitude { return $_[0]->{longitude}; }
    sub timezone { return $_[0]->{timezone}; }
    sub postal_code { return $_[0]->{postal_code}; }

    # Enriched fields
    sub country_name { return $_[0]->{country_name}; }
    sub is_eu { return $_[0]->{is_eu}; }
    sub country_flag { return $_[0]->{country_flag}; }
    sub country_flag_url { return $_[0]->{country_flag_url}; }
    sub country_currency { return $_[0]->{country_currency}; }
    sub continent_info { return $_[0]->{continent_info}; }
}

# Helper package for AS data
package Geo::DetailsCore::AS {
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $data  = shift || {};
        bless $data, $class;
        return $data;
    }

    sub asn { return $_[0]->{asn}; }
    sub name { return $_[0]->{name}; }
    sub domain { return $_[0]->{domain}; }
    sub type { return $_[0]->{type}; }
}

# Main package
package Geo::DetailsCore;

sub new {
    my $class = shift;
    my $data  = shift;
    my $key   = shift // '';

    # If $data is a hash reference, process and bless it
    if ( ref($data) eq 'HASH' ) {
        # Convert nested geo and as to blessed objects
        if ( exists $data->{geo} && ref($data->{geo}) eq 'HASH' ) {
            $data->{geo} = Geo::DetailsCore::Geo->new($data->{geo});
        }
        if ( exists $data->{as} && ref($data->{as}) eq 'HASH' ) {
            $data->{as} = Geo::DetailsCore::AS->new($data->{as});
        }

        bless $data, $class;
        return $data;
    }

    # If $data is a plain string, create a new hash reference
    my $self = { $key => $data };
    bless $self, $class;
    return $self;
}

sub TO_JSON {
    my ($self) = @_;
    return {%$self};
}

sub ip { return $_[0]->{ip}; }
sub geo { return $_[0]->{geo}; }
sub as { return $_[0]->{as}; }
sub is_anonymous { return $_[0]->{is_anonymous}; }
sub is_anycast { return $_[0]->{is_anycast}; }
sub is_hosting { return $_[0]->{is_hosting}; }
sub is_mobile { return $_[0]->{is_mobile}; }
sub is_satellite { return $_[0]->{is_satellite}; }
sub bogon { return $_[0]->{bogon}; }

sub all {
    return $_[0];
}

1;
__END__

=head1 NAME

Geo::DetailsCore - Module to represent details of an IP returned by the Core API

=head1 SYNOPSIS

    use Geo::DetailsCore;

    my $data = {
        ip   => '8.8.8.8',
        geo  => {
            city => 'Mountain View',
            country => 'United States',
            country_code => 'US',
        },
        as => {
            asn => 'AS15169',
            name => 'Google LLC',
        },
        is_anycast => 1,
    };

    my $details = Geo::DetailsCore->new($data);
    print $details->ip;              # Output: 8.8.8.8
    print $details->geo->city;       # Output: Mountain View
    print $details->as->name;        # Output: Google LLC

=head1 DESCRIPTION

Geo::DetailsCore represents details of an IP returned by the IPinfo Core API.

=head1 AUTHOR

IPinfo <support@ipinfo.io>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 IPinfo

Licensed under the Apache License, Version 2.0.

=cut
