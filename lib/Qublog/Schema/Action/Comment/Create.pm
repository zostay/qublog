package Qublog::Schema::Action::Comment::Create;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::Comment::Store );
with qw( Qublog::Schema::Action::Role::Lookup::New );

has journal_day => (
    is        => 'ro',
    isa       => 'Qublog::Schema::Result::JournalDay',
    required  => 1,
    traits    => [ 'Model::Column' ],
);

has journal_timer => (
    is        => 'ro',
    isa       => 'Qublog::Schema::Result::JournalTimer',
    required  => 1,
    traits    => [ 'Model::Column' ],
);

has owner => (
    is        => 'ro',
    isa       => 'Qublog::Schema::Result::User',
    required  => 1,
    traits    => [ 'Model::Column' ],
);

has created_on => (
    is        => 'ro',
    isa       => 'DateTime::DateTime',
    required  => 1,
    traits    => [ 'Model::Column' ],
);

1;
