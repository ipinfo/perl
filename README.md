# Geo::IPinfo

Official ipinfo.io Perl library

## EXAMPLE

    use Geo::IPinfo;

    my $token = "1234567";

    # if you have a valid token, use it
    my $ipinfo = Geo::IPinfo->new($token);

    # or, if you don't have a token, use this:
    # my $ipinfo = Geo::IPinfo->new();

    # return a hash reference containing all IP related information
    my $data = $ipinfo->info("8.8.8.8");

    if (defined $data)   # valid data returned
    {
      print "Information about IP 8.8.8.8:\n";
      for my $key (sort keys %$data )
      {
        printf "%10s : %s\n", $key, $data->{$key};
      }
      print "\n";
    }
    else   # invalid data obtained, show error message
    {
      print $ipinfo->error_msg . "\n";
    }

    # retrieve only city information of the IP address
    my $city = $ipinfo->field("8.8.8.8", "city");

    print "The city of 8.8.8.8 is $city\n";

### OUTPUT
    Information about IP 8.8.8.8:
          city : Mountain View
       country : US
      hostname : google-public-dns-a.google.com
            ip : 8.8.8.8
           loc : 37.3860,-122.0840
           org : AS15169 Google LLC
         phone : 650
        postal : 94035
        region : California

    The city of 8.8.8.8 is Mountain View

## USAGE

For details about how to use the library, install it and then run:

    perldoc Geo::IPinfo


## Before submitting to CPAN

Make sure ALL tests executed without errors; to do this, run:

    $ cd Geo-IPinfo/
    $ perl Makefile.PL
    $ RELEASE_TESTING=1 make test

In particular, pay attention to the result of the execution of 't/01-usage.t'; to see
more detailed information about the execution of this test, run:

    $ RELEASE_TESTING=1 prove -bv t/01-usage.t
