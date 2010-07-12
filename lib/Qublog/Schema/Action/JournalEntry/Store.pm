package Qublog::Schema::Action::JournalEntry::Store;
use Form::Factory::Processor;

with qw(
    Qublog::Schema::Action::Role::Model::JournalEntry
    Qublog::Schema::Action::Role::Do::Store
);

__PACKAGE__->meta->make_immutable;

1;
