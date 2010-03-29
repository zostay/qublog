package Qublog::Schema::ResultSet::JournalSession;
use Moose;

extends qw( Qublog::Schema::ResultSet );

use Qublog::DateTime;

=head1 NAME

Qublog::Schema::ResultSet::JournalSession - a collection of journal sessions

=head1 DESCRIPTION

Handy result set methods.

=head1 METHODS

=head2 for_date

=head2 find_by_date

Given a date, returns a modified result that only includes journal sessions that were used during that day.

=cut

sub find_by_date {
    my ($self, $date) = @_;
    my $day = $date->clone->truncate( to => 'day' );

    my $before = Qublog::DateTime->format_sql_date($day->clone);
    my $after  = Qublog::DateTime->format_sql_date($day->clone->add( days => 1 ));

    return $self->search([
        -or => [
            start_time => [ -and => { '>=', $before }, { '<',  $after  }, ],
            stop_time  => [ -and => { '>=', $before }, { '<',  $after  }, ],
        ],
    ]);
}

*for_date = *$find_by_date;

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 LICENSE

Qublog Personal/Professional Journaling
Copyright (C) 2010  Andrew Sterling Hanenkamp

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
