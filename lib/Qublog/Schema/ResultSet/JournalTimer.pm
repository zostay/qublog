package Qublog::Schema::ResultSet::JournalTimer;
use Moose;
extends qw( Qublog::Schema::ResultSet );

sub search_by_running {
    my ($self, $running) = @_;

    return $self->search({ 
        stop_time => { ($running ? '=' : '!='), undef },
    });
}

1;
