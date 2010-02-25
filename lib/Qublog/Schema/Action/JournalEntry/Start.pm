package Qublog::Schema::Action::JournalEntry::Start;
use Form::Factory::Processor;

with qw(
    Qublog::Schema::Action::Role::Model::JournalEntry
    Qublog::Schema::Action::Role::Lookup::Find
    Qublog::Schema::Action::Role::Do
);

has_control id => (
    is        => 'rw',
    isa       => 'Int',

    control   => 'text',
    traits    => [ 'Model::Column' ],

    features  => {
        fill_on_assignment => 1,
    },
);

sub do {
    my $self = shift;
    $self->record->start_timer;
}

sub success_message {
    my $self = shift;
    return sprintf('started the timer for %s', $self->record->name);
}

1;
