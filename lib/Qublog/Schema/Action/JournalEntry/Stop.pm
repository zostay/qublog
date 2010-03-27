package Qublog::Schema::Action::JournalEntry::Stop;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::JournalEntry::Do );
with    qw( Qublog::Action::Role::Secure::CheckOwner );

sub do {
    my $self = shift;
    $self->record->stop_timer;
}

sub success_message {
    my $self = shift;
    return sprintf('stopped the timer for %s', $self->record->name);
}

1;
