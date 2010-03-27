package Qublog::Schema::Action::Comment::Update;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::Comment::Store );
with qw( 
    Qublog::Schema::Action::Role::Lookup::Find 
    Qublog::Action::Role::WantsTimeZone
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

    features  => {
        fill_on_assignment => { slot => 'value' },
    },
);

has_control created_on => (
    is        => 'rw',
    isa       => 'DateTime',

    control   => 'text',
    traits    => [ 'Model::Column' ],
    options   => {
        label => 'Time',
    },

    features  => {
        fill_on_assignment => 1,
        required  => 1,
        trim      => 1,
        date_time => {
            use_attribute_as_context => 1,
            parse_method             => 'parse_human_time',
            format_method            => 'format_human_time',
        },
    },
);

1;
