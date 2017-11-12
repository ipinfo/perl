# Geo::IPinfo

Official ipinfo.io Perl library


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
