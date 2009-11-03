package Qublog::Schema::ResultSet::JournalTimer;
use Moose;
extends qw( Qublog::Schema::ResultSet );

=head1 NAME

Qublog::Schema::ResultSet::JournalTimer - result set helpers for timers

=head1 DESCRIPTION

Time saving devices here.

=head1 METHODS

=head2 search_by_running

Expects a boolean value. True returns running timers. False returns stopped timers.

=cut

sub search_by_running {
    my ($self, $running) = @_;

    return $self->search({ 
        stop_time => { ($running ? '=' : '!='), undef },
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
