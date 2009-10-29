package Qublog::Server::Link;
use Moose;

use Moose::Util::TypeConstraints;

enum 'Qublog::Server::Link::LinkType' => qw( script style );

no Moose::Util::TypeConstraints;

=head1 NAME

Qublog::Server::Link - encapsulate information about head links

=head1 DESCRIPTION

Scripts and stylesheets go in here.

=head1 TYPES

=head2 Qublog::Server::Link::LinkType

This is an enumeration of one of the following values:

=over

=item *

script

=item *

style

=back

=head1 ATTRIBUTES

=head2 type

This is the type of link. It is a L</Qublog::Server::Link::LinkType>.

=cut

has type => (
    is       => 'ro',
    isa      => 'Qublog::Server::Link::LinkType',
    required => 1,
);

=head2 code

This is the literal code to place in the value. Either this or L</file> must be
set.

=cut

has code => (
    is       => 'ro',
    isa      => 'Str',
    predicate => 'is_source',
);

=head2 file

This is the external file to link. Either this or L</code> must be set.

=cut

has file => (
    is       => 'ro',
    isa      => 'Str',
    predicate => 'is_file',
);

=head1 METHODS

=head2 file_type

Returns the file extension to use with a link file. This returns "C<js>" for
scripts and "C<css>" for styles.

=cut

sub file_type {
    my $self = shift;

    return {
        script => 'js',
        style  => 'css',
    }->{ $self->type };
}

=head2 path

Returns the server path of the file resources.

=cut

sub path {
    my $self = shift;
    return unless $self->is_file;
    return '/static/' . $self->type . '/' 
        . $self->file . '.' . $self->file_type;
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

no Moose;

1;
