package Qublog::Schema::Action::Comment::Delete;
use Form::Factory::Processor;

with qw(
    Qublog::Schema::Action::Role::Model::Comment
    Qublog::Schema::Action::Role::Lookup::Find
    Qublog::Schema::Action::Role::Do::Delete
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
    
1;
