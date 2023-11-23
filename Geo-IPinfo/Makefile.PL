use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME             => 'Geo::IPinfo',
    AUTHOR           => q{ipinfo.io <support@ipinfo.io>},
    VERSION_FROM     => 'lib/Geo/IPinfo.pm',
    ABSTRACT_FROM    => 'lib/Geo/IPinfo.pm',
    LICENSE          => 'apache_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'LWP::UserAgent'          => '0',
        'JSON'                    => '0',
        'File::ShareDir::Install' => '0',
        'Cache::LRU'              => '0',
        'File::Share'             => '0',
        'Net::CIDR'               => '0',      
        'Net::CIDR::Set'          => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Geo-IPinfo-*' },
);

package MY;
use File::ShareDir::Install 'postamble';
