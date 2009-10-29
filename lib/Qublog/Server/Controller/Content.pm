package Qublog::Server::Controller::Content;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use File::Slurp qw( read_file );

=head1 NAME

Qublog::Server::Controller::Content - Content manager for Qublog

=head1 DESCRIPTION

This is the very simple content manager for Qublog. It serves static content
found under the F<root/content> directory.

=head1 METHODS

=head2 index

This takes the requested path and attempts to load the content of a C<.mkd> file
matching it under F<root/content>. If such a file is found, it is slurped and
passed off to the L<Qublog::Server::View::TD::Content/content/show> template.

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

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 LICENSE

Qublog Personal/Professional Journaling
Copyright (C) 2009  Andrew Sterling Hanenkamp

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
