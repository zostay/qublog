package Qublog::Schema::Action::Comment::Update;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::Comment::Store );
with qw( 
    Qublog::Schema::Action::Role::Lookup::Find 
    Qublog::Action::Role::WantsTimeZone
);

has_control id => (
    control   => 'value',
    traits    => [ 'Model::Column' ],

    options   => {
        value => 0,
    },
    trigger   => sub {
        my ($self, $id) = @_;
        $self->find;
        $self->controls->{id}->value($id);
    },
);

has_control created_on => (
    isa       => 'Str|DateTime::DateTime',

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
        },
    },
);

1;
