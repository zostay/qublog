package Qublog::Schema::ResultSet::JournalDay;
use strict;
use warnings;
use base qw( DBIx::Class::ResultSet );

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

sub find_today {
    my $self = shift;
    return $self->find_by_date( Qublog::DateTime->today );
}

1;
