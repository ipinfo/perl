package Geo::DetailsPlus;

use 5.006;
use strict;
use warnings;

# Helper package for GeoPlus data
package Geo::DetailsPlus::Geo {
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
    sub dma_code { return $_[0]->{dma_code}; }
    sub geoname_id { return $_[0]->{geoname_id}; }
    sub radius { return $_[0]->{radius}; }
    sub last_changed { return $_[0]->{last_changed}; }

    # Enriched fields
    sub country_name { return $_[0]->{country_name}; }
    sub is_eu { return $_[0]->{is_eu}; }
    sub country_flag { return $_[0]->{country_flag}; }
    sub country_flag_url { return $_[0]->{country_flag_url}; }
    sub country_currency { return $_[0]->{country_currency}; }
    sub continent_info { return $_[0]->{continent_info}; }
}

# Helper package for ASPlus data
package Geo::DetailsPlus::AS {
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
    sub last_changed { return $_[0]->{last_changed}; }
}

# Helper package for Mobile data
package Geo::DetailsPlus::Mobile {
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $data  = shift || {};
        bless $data, $class;
        return $data;
    }
}

# Helper package for Anonymous data
package Geo::DetailsPlus::Anonymous {
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $data  = shift || {};
        bless $data, $class;
        return $data;
    }

    sub is_proxy { return $_[0]->{is_proxy}; }
    sub is_relay { return $_[0]->{is_relay}; }
    sub is_tor { return $_[0]->{is_tor}; }
    sub is_vpn { return $_[0]->{is_vpn}; }
}

# Helper package for Abuse data
package Geo::DetailsPlus::Abuse {
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $data  = shift || {};
        bless $data, $class;
        return $data;
    }

    sub address { return $_[0]->{address}; }
    sub country { return $_[0]->{country}; }
    sub email { return $_[0]->{email}; }
    sub name { return $_[0]->{name}; }
    sub network { return $_[0]->{network}; }
    sub phone { return $_[0]->{phone}; }

    # Enriched
    sub country_name { return $_[0]->{country_name}; }
}

# Helper package for Company data
package Geo::DetailsPlus::Company {
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $data  = shift || {};
        bless $data, $class;
        return $data;
    }

    sub name { return $_[0]->{name}; }
    sub domain { return $_[0]->{domain}; }
    sub type { return $_[0]->{type}; }
}

# Helper package for Privacy data
package Geo::DetailsPlus::Privacy {
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $data  = shift || {};
        bless $data, $class;
        return $data;
    }

    sub vpn { return $_[0]->{vpn}; }
    sub proxy { return $_[0]->{proxy}; }
    sub tor { return $_[0]->{tor}; }
    sub relay { return $_[0]->{relay}; }
    sub hosting { return $_[0]->{hosting}; }
    sub service { return $_[0]->{service}; }
}

# Helper package for Domains data
package Geo::DetailsPlus::Domains {
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $data  = shift || {};
        bless $data, $class;
        return $data;
    }

    sub domains { return $_[0]->{domains}; }
    sub total { return $_[0]->{total}; }
}

# Main package
package Geo::DetailsPlus;

sub new {
    my $class = shift;
    my $data  = shift;
    my $key   = shift // '';

    # If $data is a hash reference, process and bless it
    if ( ref($data) eq 'HASH' ) {
        # Convert nested objects to blessed objects
        if ( exists $data->{geo} && ref($data->{geo}) eq 'HASH' ) {
            $data->{geo} = Geo::DetailsPlus::Geo->new($data->{geo});
        }
        if ( exists $data->{as} && ref($data->{as}) eq 'HASH' ) {
            $data->{as} = Geo::DetailsPlus::AS->new($data->{as});
        }
        if ( exists $data->{mobile} && ref($data->{mobile}) eq 'HASH' ) {
            $data->{mobile} = Geo::DetailsPlus::Mobile->new($data->{mobile});
        }
        if ( exists $data->{anonymous} && ref($data->{anonymous}) eq 'HASH' ) {
            $data->{anonymous} = Geo::DetailsPlus::Anonymous->new($data->{anonymous});
        }
        if ( exists $data->{abuse} && ref($data->{abuse}) eq 'HASH' ) {
            $data->{abuse} = Geo::DetailsPlus::Abuse->new($data->{abuse});
        }
        if ( exists $data->{company} && ref($data->{company}) eq 'HASH' ) {
            $data->{company} = Geo::DetailsPlus::Company->new($data->{company});
        }
        if ( exists $data->{privacy} && ref($data->{privacy}) eq 'HASH' ) {
            $data->{privacy} = Geo::DetailsPlus::Privacy->new($data->{privacy});
        }
        if ( exists $data->{domains} && ref($data->{domains}) eq 'HASH' ) {
            $data->{domains} = Geo::DetailsPlus::Domains->new($data->{domains});
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
sub hostname { return $_[0]->{hostname}; }
sub geo { return $_[0]->{geo}; }
sub as { return $_[0]->{as}; }
sub mobile { return $_[0]->{mobile}; }
sub anonymous { return $_[0]->{anonymous}; }
sub abuse { return $_[0]->{abuse}; }
sub company { return $_[0]->{company}; }
sub privacy { return $_[0]->{privacy}; }
sub domains { return $_[0]->{domains}; }
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

Geo::DetailsPlus - Module to represent details of an IP returned by the Plus API

=head1 SYNOPSIS

    use Geo::DetailsPlus;

    my $data = {
        ip       => '8.8.8.8',
        hostname => 'dns.google',
        geo      => {
            city => 'Mountain View',
            country => 'United States',
            country_code => 'US',
        },
        as => {
            asn => 'AS15169',
            name => 'Google LLC',
        },
        privacy => {
            vpn => 0,
            proxy => 0,
        },
    };

    my $details = Geo::DetailsPlus->new($data);
    print $details->ip;              # Output: 8.8.8.8
    print $details->hostname;        # Output: dns.google
    print $details->geo->city;       # Output: Mountain View
    print $details->privacy->vpn;    # Output: 0

=head1 DESCRIPTION

Geo::DetailsPlus represents details of an IP returned by the IPinfo Plus API.

=head1 AUTHOR

IPinfo <support@ipinfo.io>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 IPinfo

Licensed under the Apache License, Version 2.0.

=cut
