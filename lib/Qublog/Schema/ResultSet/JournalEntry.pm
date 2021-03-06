package Qublog::Schema::ResultSet::JournalEntry;
use Moose;
extends qw( Qublog::Schema::ResultSet );

=head1 NAME

Qublog::Search::ResultSet::JournalEntry - handy result set helpers for entries

=head1 DESCRIPTION

Helpers to the result set for journal entries.

=head1 METHODS

=head2 search_by_running

Takes a hash of options, including:

=over

=item running

(Required.) Give it a boolean value. True indicates you want running entries. False indicates you want stopped entries.

=item alias

The table alias to use for the column. Defaults to "me".

=back

=cut

sub search_by_running {
    my ($self, %options) = @_;
    my $alias = $options{alias} // "me";

    my $stop_time = "$alias.stop_time";

    return $self->search({ 
        $stop_time => { ($options{running} ? '=' : '!='), undef },
    });
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
