package Qublog::Server;

use strict;
use warnings;

use Catalyst::Runtime 5.80;

use Data::Dumper;
$Data::Dumper::Freezer = '_dumper_hook';

use Digest::MD5 qw( md5_hex );
use File::Slurp qw( read_file );

use Qublog::DateTime2;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use parent qw/Catalyst/;
use Catalyst qw(
    -Debug
    ConfigLoader
    Static::Simple

    StackTrace

    Authentication

    Session
    Session::Store::FastMmap
    Session::State::Cookie
);
our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in qublog_server.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( 
    name         => 'Qublog::Server',
    default_view => 'TD',
);

# Start the application
__PACKAGE__->setup();


=head1 NAME

Qublog::Server - Catalyst based application

=head1 SYNOPSIS

    script/qublog_server_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

sub field_defaults {
    my ($c, $fields) = @_;

    for my $key (keys %$fields) {
        $fields->{ $key } 
            = $c->request->params->{ $key } ? $c->request->params->{ $key }
            : $c->flash->{fields}{ $key }   ? $c->flash->{fields}{ $key }
            :                                 $fields->{ $key }
            ;
    }

    return $c->flash->{fields} = $fields;
}

sub add_style {
    my ($c, $type, $code) = @_;
    push @{ $c->stash->{style} }, Qublog::Server::Link->new(
        $type => $code,
        type  => 'style',
    );
}

sub add_script {
    my ($c, $type, $code) = @_;
    push @{ $c->stash->{script} }, Qublog::Server::Link->new(
        $type => $code,
        type  => 'script',
    );
}

sub time_zone {
    my $c = shift;

    if ($c->user_exists) {
        return $c->user->get_object->time_zone;
    }

    return DateTime::TimeZone->new( name => $c->config->{'time_zone'} );
}


sub now {
    my $c = shift;
    return Qublog::DateTime->now->set_time_zone( $c->time_zone );
}

sub today {
    my $c = shift;
    return $c->now->truncate( to => 'day' );
}

sub current_terms_md5 {
    my $c = shift;

    my $config = $c->config->{'Qublog::Terms'};
    my $license = $config->{file};

    my $license_path = $c->path_to('root', 'content', $license);
    return unless -f $license_path;

    return md5_hex(read_file("$license_path"));
}

=head1 SEE ALSO

L<Qublog::Server::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Andrew Sterling Hanenkamp,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
