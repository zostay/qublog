package Qublog::Schema::Action::JournalTimer::ChangeStop;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::JournalTimer::Store );
with qw(
    Qublog::Schema::Action::Role::Lookup::Find
    Qublog::Action::Role::WantsTimeZone
    Qublog::Action::Role::WantsCurrentUser
    Qublog::Action::Role::Secure
);

has_control id => (
    control   => 'value',
    traits    => [ 'Model::Column' ],

    options   => {
        value => 0,
    },

    features => {
        fill_on_assignment => { slot => 'value' },
    },
);

has_control stop_time => (
    is        => 'rw',
    isa       => 'DateTime',

    control   => 'text',
    traits    => [ 'Model::Column' ],

    features  => {
        fill_on_assignment => 1,
        trim      => 1,
        required  => 1,
        date_time => {
            use_attribute_as_context => 1,
            parse_method             => 'parse_human_time',
            format_method            => 'format_human_time',
        },
    },
);

sub may_run {
    my $self = shift;

    unless ($self->current_user->id == $self->record->journal_entry->owner->id) {
        $self->error('you cannot change a timer belonging to a different user');
        $self->is_valid(0);
    }
}

1;
