package Qublog::Schema::Action::JournalTimer::Store;
use Form::Factory::Processor;

with qw(
    Qublog::Schema::Action::Role::Model::JournalTimer
    Qublog::Schema::Action::Role::Do::Store
);

1;
