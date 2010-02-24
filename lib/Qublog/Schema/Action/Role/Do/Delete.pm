package Qublog::Schema::Action::Role::Do::Delete;
use Moose::Role;

with qw( Qublog::Schema::Action::Role::Do );

sub do {
    my $self = shift;

    die "no record has been loaded" unless $self->has_record;

    my $record = $self->record;
    $record->delete;
}

sub success_message {
    my $self = shift;
    return sprintf('removed the %s', $self->result_source->source_name);
}

1;
