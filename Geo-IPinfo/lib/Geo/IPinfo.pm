package Geo::IPinfo;

use 5.006;
use strict;
use warnings;

use LWP::UserAgent;
use JSON;

our $VERSION = '1.0';

my %valid_fields = (
                    ip => 1,
                    hostname => 1,
                    city => 1,
                    region => 1,
                    country => 1,
                    loc => 1,
                    org => 1,
                    postal => 1,
                    phone => 1
                );
my $base_url = 'https://ipinfo.io/';

#-------------------------------------------------------------------------------

sub new
{
  my ($pkg, $token) = @_;

  my $self = {};
  $self->{token} = defined $token ? "?token=$token" : "";

  $self->{base_url} = $base_url;
  $self->{ua} = LWP::UserAgent->new;
  $self->{ua}->agent("curl/Geo::IP $VERSION");
  $self->{message} = "";

  bless($self, $pkg);
  return $self;
}

#-------------------------------------------------------------------------------

sub info
{
  my ($self, $ip) = @_;

  return $self->_getinfo($ip, "");
}

#-------------------------------------------------------------------------------

sub geo
{
  my ($self, $ip) = @_;

  return $self->_getinfo($ip, "geo");
}

#-------------------------------------------------------------------------------

sub field
{
  my ($self, $ip, $field) = @_;

  if (not defined $ip)
  {
    $self->{message} = "IP is undefined";
    return undef;
  }

  if (not defined $valid_fields{$field})
  {
    $self->{message} = "Invalid field: $field";
    return undef;
  }

  my $url = $self->{base_url} . $ip . "/" . $field . $self->{token};

  my $res = $self->{ua}->get($url);
  if ($res->is_success)
  {
    $self->{message} = "";
    return $res->decoded_content;
  }
  else
  {
    $self->{message} = $res->status_line;
    return undef;
  }
}

#-------------------------------------------------------------------------------

sub error_msg
{
  my $self = shift;

  return $self->{message};
}

#-------------------------------------------------------------------------------
#-- private method(s) below , don't call them directly -------------------------

sub _getinfo
{
  my ($self, $ip, $type) = @_;

  if (not defined $ip)
  {
    $self->{message} = "IP is undefined";
    return undef;
  }

  my $url = $self->{base_url} . $ip . "/" . $type . $self->{token};

  my $res = $self->{ua}->get($url);
  if ($res->is_success)
  {
    $self->{message} = "";
    return from_json($res->decoded_content);
  }
  else
  {
    $self->{message} = $res->status_line;
    return undef;
  }
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

    my $ipinfo = Geo::IPinfo->new();

    # return a hash reference containing all IP related information
    my $data = $ipinfo->info("8.8.8.8");
    if (defined $data)
    {
      printf "IP: %s, Country: %s\n", $data->{ip}, $data->{country};
      printf "Latitude, longitude: %s", $data->{loc};
    }
    else
    {
      print $ipinfo->error_msg . "\n";
    }

    # retrieve only city information of the IP address
    my $city = $ipinfo->field("8.8.8.8", "city");



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
