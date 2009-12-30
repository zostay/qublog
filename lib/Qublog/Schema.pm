package Qublog::Schema;
use strict;
use warnings;
use base qw( DBIx::Class::Schema );

__PACKAGE__->load_namespaces();

=head1 NAME

Qublog::Schema - Qublog database schema

=head1 DESCRIPTION

The L<DBIx::Class> schema for Qublog.

=head1 METHODS

=head2 _dumper_hook

Less verbose output for L<Data::Dumper>.

=cut

sub _dumper_hook {
    $_[0] = bless {
        %{ $_[0] },
        storage              => ''.$_[0]{storage},
        source_registrations => ''.$_[0]{source_registrations},
    }, ref($_[0]);
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
