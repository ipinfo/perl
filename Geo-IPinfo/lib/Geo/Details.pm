package Geo::Details;

use 5.006;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $data = shift;
  my $key = shift // '';

  # If $data is a hash reference, directly bless it into the class and return.
  if (ref($data) eq 'HASH') {
      bless $data, $class;
      return $data;
  }

  # If $data is a plain string, create a new hash reference and set the specified key to the string value.
  # Use the provided key or default to ''.
  my $self = { $key => $data };
  bless $self, $class;
  return $self;
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
