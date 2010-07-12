package Qublog::Schema::Action::JournalSession::Store;
use Form::Factory::Processor;

with qw(
    Qublog::Schema::Action::Role::Model::JournalSession
    Qublog::Schema::Action::Role::Do::Store
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

__PACKAGE__->meta->make_immutable;

1;
