package Qublog::Server::Controller::Content;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use File::Slurp qw( read_file );

=head1 NAME

Qublog::Server::Controller::Content - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Very conservative validation here, wig out on anything remotely odd
    my $path_info = $c->request->path;
    return if $path_info =~ m{[^\w/]};

    # Path is squeaky clean (only letters, numbers, underscores, and slashes)
    my $path = $c->path_to('root', 'content', $path_info . '.mkd');
    if (-f $path) {
        $c->stash->{content}  = read_file("$path");
        $c->stash->{template} = '/content/show';
    }
}


=head1 AUTHOR

Andrew Sterling Hanenkamp,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
