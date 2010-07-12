package Qublog::Schema::Action::JournalSession::Stop;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::JournalSession::Do );
with    qw( Qublog::Action::Role::Secure::CheckOwner );

use_feature 'automatic_lookup';

sub do {
    my $self = shift;
    $self->record->stop_timer;
}

sub success_message {
    my $self = shift;
    return sprintf('session %s is closed', $self->record->name);
}

__PACKAGE__->meta->make_immutable;

1;
