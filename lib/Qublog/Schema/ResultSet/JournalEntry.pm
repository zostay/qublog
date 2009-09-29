package Qublog::Schema::ResultSet::JournalEntry;
use Moose;
extends qw( DBIx::Class::ResultSet );

sub search_by_running {
    my ($self, $running) = @_;

    return $self->search({ 
        stop_time => { ($running ? '=' : '!='), undef },
    });
}

1;
