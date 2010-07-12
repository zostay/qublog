package Qublog::Schema::Action::JournalSession::Start;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::JournalSession::Do );
with    qw( Qublog::Action::Role::Secure::CheckOwner );

use_feature 'automatic_lookup';

sub do {
    my $self = shift;
    $self->record->start_timer;
}

sub success_message {
    my $self = shift;
    return sprintf('session %s is open', $self->record->name);
}

__PACKAGE__->meta->make_immutable;

1;
