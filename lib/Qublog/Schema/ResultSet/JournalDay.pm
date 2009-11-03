package Qublog::Schema::ResultSet::JournalDay;
use strict;
use warnings;
use base qw( Qublog::Schema::ResultSet );

BEGIN {
    die "DO NOT LOAD UNDER JIFTY" if $Jifty::VERSION;
}

use Qublog::DateTime2;

=head1 NAME

Qublog::Schema::ResultSet::JournalDay - the results of journal day

=head1 DESCRIPTION

Handy result set methods.

=haed1 METHODS

=head2 for_date

=head2 find_by_date

Given a date returns, the journal day for the date. This will create it if it does not yet exist.

=cut

sub find_by_date {
    my ($self, $date) = @_;
    my $day = $date->clone->truncate( to => 'day' );

    my $journal_day;
    $self->result_source->schema->txn_do(sub {
        $journal_day = $self->find_or_create({
            datestamp => Qublog::DateTime->format_sql_date($day),
        });
    });

    return $journal_day;
}

=head2 for_today

=head2 find_today

Given your notion of today, return the journal day for that date.

=cut

sub find_today {
    my ($self, $today) = @_;
    return $self->find_by_date( $today );
}

*for_date  = *find_by_date;
*for_today = *find_today;

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
