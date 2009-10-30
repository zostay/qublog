package Qublog::Schema::Result;
use Moose;

extends qw( DBIx::Class );

=head1 NAME

Qublog::Schema::Result - base class for Qublog result sources

=head1 DESCRIPTIONo

This is the base class for all the Qublgo result sources.

=head1 METHODS

=head2 _dumper_hook

Used as the L<Data::Dumper> freezer method.

=cut

sub _dumper_hook { 
    $_[0] = bless { %{ $_[0] }, _source_handle => undef, }, ref($_[0]); 
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
