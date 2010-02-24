package Qublog::Schema::Action::JournalEntry::Update;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::JournalEntry::Store );
with qw(
    Qublog::Schema::Action::Role::Lookup::Find
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

has_control name => (
    is        => 'rw',

    placement => 10,
    control   => 'text',
    traits    => [ 'Model::Column' ],

    features  => {
        fill_on_assignment => 1,
        required => 1,
        trim     => 1,
    },
);

has_control primary_link => (
    is        => 'rw',

    placement => 20,
    control   => 'text',
    traits    => [ 'Model::Column' ],

    features  => {
        fill_on_assignment => 1,
        trim     => 1,
    },
);

has_control project => (
    is        => 'rw',
    isa       => 'Qublog::Schema::Result::Task',

    placement => 30,
    control   => 'select_one',
    traits    => [ 'Model::Column' ],


    options   => {
        available_choices => deferred_value {
            my $self = shift;
            my $schema = $self->schema;

            [
                map { 
                    Form::Factory::Control::Choice->new(
                        $_->id, '#' . $_->tag . ': ' . $_->name
                    ) 
                } $schema->resultset('Task')->search({ 
                    task_type => 'project', 
                    status    => 'open' 
                }, { order_by => { -desc => 'created_on' } })
            ]
        },

        # TODO Conver this into a feature for object refs
        value_to_control => sub {
            my ($action, $control, $value) = @_;
            $value->id;
        },
        control_to_value => sub {
            my ($action, $control, $value) = @_;
            $action->schema->resultset('Task')->find($value);
        },
    },

    features => {
        fill_on_assignment => 1,
        required => 1,
    },
);

1;
