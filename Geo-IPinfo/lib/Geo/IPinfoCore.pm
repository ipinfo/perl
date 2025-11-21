package Geo::IPinfoCore;

use 5.006;
use strict;
use warnings;
use Cache::LRU;
use LWP::UserAgent;
use HTTP::Headers;
use JSON;
use Geo::DetailsCore;
use Net::CIDR;
use Net::CIDR::Set;

our $VERSION = '3.2.0';
use constant DEFAULT_CACHE_MAX_SIZE => 4096;
use constant DEFAULT_CACHE_TTL      => 86_400;
use constant DEFAULT_TIMEOUT        => 2;
use constant HTTP_TOO_MANY_REQUEST  => 429;

my $base_url = 'https://api.ipinfo.io/lookup/';

my @ip4_bogon_networks = (
    '0.0.0.0/8',         '10.0.0.0/8',       '100.64.0.0/10',  '127.0.0.0/8',
    '169.254.0.0/16',    '172.16.0.0/12',    '192.0.0.0/24',   '192.0.2.0/24',
    '192.168.0.0/16',    '198.18.0.0/15',    '198.51.100.0/24',
    '203.0.113.0/24',    '224.0.0.0/4',      '240.0.0.0/4',    '255.255.255.255/32',
);

my @ip6_bogon_networks = (
    '::/128',            '::1/128',          '::ffff:0:0/96',  '::/96',
    '100::/64',          '2001:10::/28',     '2001:db8::/32',  'fc00::/7',
    'fe80::/10',         'fec0::/10',        'ff00::/8',       '2002::/24',
    '2002:a00::/24',     '2002:7f00::/24',   '2002:a9fe::/32', '2002:ac10::/28',
    '2002:c000::/40',    '2002:c000:200::/40', '2002:c0a8::/32',
    '2002:c612::/31',    '2002:c633:6400::/40', '2002:cb00:7100::/40',
    '2002:e000::/20',    '2002:f000::/20',   '2002:ffff:ffff::/48',
    '2001::/40',         '2001:0:a00::/40',  '2001:0:7f00::/40',
    '2001:0:a9fe::/48',  '2001:0:ac10::/44', '2001:0:c000::/56',
    '2001:0:c000:200::/56', '2001:0:c0a8::/48', '2001:0:c612::/47',
    '2001:0:c633:6400::/56', '2001:0:cb00:7100::/56', '2001:0:e000::/36',
    '2001:0:f000::/36',  '2001:0:ffff:ffff::/64',
);

sub new {
    my ( $class, %options ) = @_;

    my $token = defined $options{token} ? $options{token} : '';

    my $cache_maxsize =
        defined $options{cache_maxsize}
        ? $options{cache_maxsize}
        : DEFAULT_CACHE_MAX_SIZE;

    my $cache_ttl =
        defined $options{cache_ttl}
        ? $options{cache_ttl}
        : DEFAULT_CACHE_TTL;

    my $timeout =
        defined $options{timeout}
        ? $options{timeout}
        : DEFAULT_TIMEOUT;

    my $header = HTTP::Headers->new();
    $header->header( 'User-Agent'   => 'IPinfoClient/Perl/3.2.0' );
    $header->header( 'Accept'       => 'application/json' );
    $header->header( 'Content-Type' => 'application/json' );

    if ($token) {
        $header->header( 'Authorization' => 'Bearer ' . $token );
    }

    my $ua = LWP::UserAgent->new(
        timeout      => $timeout,
        show_progress => 0,
    );

    $ua->default_headers($header);

    my $cache;
    if ( defined $options{cache} ) {
        $cache = $options{cache};
    }
    else {
        $cache = _build_cache( __PACKAGE__, cache_maxsize => $cache_maxsize, cache_ttl => $cache_ttl );
    }

    my $self = {
        token    => $token,
        base_url => $base_url,
        ua       => $ua,
        cache    => $cache,
        cache_ttl => $cache_ttl,
        message  => '',
    };

    return bless $self, $class;
}

sub info {
    my ( $self, $ip ) = @_;

    return $self->_get_info( $ip, );
}


sub _get_info {
    my ( $self, $ip ) = @_;

    $ip    = defined $ip    ? $ip    : '';

    if ( $ip ne '' ) {
        my $validated_ip = Net::CIDR::cidrvalidate($ip);
        if ( !defined $validated_ip ) {
            $self->{message} = 'Invalid IP address';
            return undef;
        }
    }

    my ( $info, $message ) = $self->_lookup_info( $ip );
    $self->{message} = $message;
    return $info if eval { $info->isa('Geo::DetailsCore') };

    return defined $info ? Geo::DetailsCore->new( $info ) : undef;
}

sub _lookup_info {
    my ( $self, $ip ) = @_;

    # checking bogon IP and returning response locally.
    if ( $ip ne '' ) {
        if ( _is_bogon($ip) ) {
            my $details = {};
            $details->{ip}    = $ip;
            $details->{bogon} = "True";
            return ( $details, '' );
        }
    }

    my ( $info, $message );
    my $cache_key = 'core_' . $ip;

    if ( !defined $self->{cache} ) {
        ( $info, $message ) = $self->_lookup_info_from_source($ip);
    }
    else {
        ( $info, $message ) = $self->_lookup_info_from_cache( $ip, $cache_key );

        if ( !defined $info ) {
            ( $info, $message ) = $self->_lookup_info_from_source($ip);

            if ( defined $info && ref $info eq 'HASH' && !exists $info->{bogon} ) {
                $self->{cache}->set( $cache_key => $info, $self->{cache_ttl} );
            }
        }
    }

    return ( $info, $message );
}

sub _lookup_info_from_cache {
    my ( $self, $ip, $cache_key ) = @_;

    my $info = $self->{cache}->get($cache_key);

    if ( !defined $info ) {
        return ( undef, '' );
    }

    return ( $info, '' );
}

sub _lookup_info_from_source {
    my ( $self, $ip ) = @_;

    my $url = '';
    if ( $ip ) {
        $url = $self->{base_url} . $ip;
    } else {
        $url = $self->{base_url} . "me";
    }

    my $response = $self->{ua}->get($url);

    if ( $response->is_success ) {

        my $content_type = $response->header('Content-Type') || '';
        my $info;

        if ( $content_type =~ m{application/json}i ) {
            eval { $info = from_json( $response->decoded_content ); };
            if ($@) {
                return ( undef, 'Error parsing JSON response.' );
            }
        }
        else {
            $info = $response->decoded_content;
            chomp($info);
        }

        return ( $info, '' );
    }
    if ( $response->code == HTTP_TOO_MANY_REQUEST ) {
        return ( undef, 'Your monthly request quota has been exceeded.' );
    }

    return ( undef, $response->status_line );
}

sub _build_cache {
    my ( $pkg, %options ) = @_;

    my $cache_maxsize = defined $options{cache_maxsize} ? $options{cache_maxsize} : DEFAULT_CACHE_MAX_SIZE;
    my $cache_ttl = defined $options{cache_ttl} ? $options{cache_ttl} : DEFAULT_CACHE_TTL;

    my $cache = Cache::LRU->new( size => $cache_maxsize );

    return $cache;
}

sub _is_bogon {
    my $ip = shift;

    my $ip_is_bogon = 0;

    if ( $ip =~ /:/ ) {    # IPv6 address
        my $ip6_bogon_cidr_set = Net::CIDR::Set->new();
        $ip6_bogon_cidr_set->add($_) foreach (@ip6_bogon_networks);
        $ip_is_bogon = $ip6_bogon_cidr_set->contains($ip);
    }
    else {    # IPv4 address
        my $ip4_bogon_cidr_set = Net::CIDR::Set->new();
        $ip4_bogon_cidr_set->add($_) foreach (@ip4_bogon_networks);
        $ip_is_bogon = $ip4_bogon_cidr_set->contains($ip);
    }

    return $ip_is_bogon;
}

1;

__END__

=head1 NAME

Geo::IPinfoCore - Perl module for IPinfo Core API

=head1 SYNOPSIS

    use Geo::IPinfoCore;

    my $ipinfo = Geo::IPinfoCore->new(token => 'YOUR_TOKEN');
    my $details = $ipinfo->info('8.8.8.8');

    print "IP: " . $details->ip . "\n";
    print "City: " . $details->geo->city . "\n";
    print "Country: " . $details->geo->country . "\n";

=head1 DESCRIPTION

Geo::IPinfoCore provides access to the IPinfo Core API for IP address lookups.

=head1 AUTHOR

IPinfo <support@ipinfo.io>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 IPinfo

Licensed under the Apache License, Version 2.0.

=cut
