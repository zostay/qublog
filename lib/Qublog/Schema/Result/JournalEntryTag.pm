package Qublog::Schema::Result::JournalEntryTag;
use Moose;

extends qw( Qublog::Schema::Result );

=head1 NAME

Qublog::Schema::Result::JournalEntryTag - link entries to tags

=head1 DESCRIPTION

Links journal entries to tags.

=head1 SCHEMA

=head2 id

The autogenderated ID column.

=head2 journal_entry

The linked L<Qublog::Schema::Result::JournalEntry>.

=head2 tag

The linked L<Qublog::Schema::Result::Tag>.\\

=cut

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('journal_entry_tags');
__PACKAGE__->add_columns(
    id            => { data_type => 'int' },
    journal_entry => { data_type => 'int' },
    tag           => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( journal_entry => 'Qublog::Schema::Result::JournalEntry' );
__PACKAGE__->belongs_to( tag => 'Qublog::Schema::Result::Tag' );

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
