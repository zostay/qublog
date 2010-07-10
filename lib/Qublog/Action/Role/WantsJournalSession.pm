package Qublog::Action::Role::WantsJournalSession;
use Moose::Role;

has journal_session => (
    is        => 'rw',
    isa       => 'Qublog::Schema::Result::JournalSession',
    predicate => 'has_journal_session',
);

1;
