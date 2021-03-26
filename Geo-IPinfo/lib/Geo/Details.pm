package Geo::Details;

use 5.006;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self  = shift;

    bless $self, $class;

    return $self;
}

sub ip {
    return $_[0]->{ip};
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

sub timezone {
    return $_[0]->{timezone};
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

sub privacy {
    return $_[0]->{privacy};
}

sub abuse {
    return $_[0]->{abuse};
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
