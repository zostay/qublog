package Qublog::Schema::Action::JournalSession::Update;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::JournalSession::Store );
with qw(
    Qublog::Schema::Action::Role::Lookup::Find
    Qublog::Action::Role::Secure::CheckOwner
);

has_control id => (
    is        => 'rw',
    isa       => 'Int',

    control   => 'value',
    traits    => [ 'Model::Column' ],

    options   => {
        value => 0,
    },

    features => {
        fill_on_assignment => { slot => 'value' },
    },
);

__PACKAGE__->meta->make_immutable;

1;

