package Qublog::Schema::Action::JournalSession::Create;
use Form::Factory::Processor;

with qw(
    Qublog::Schema::Action::Role::Model::JournalSession
    Qublog::Schema::Action::Role::Lookup::New
    Qublog::Schema::Action::Role::Do::Store
    Qublog::Action::Role::Secure::CheckOwner
    Qublog::Action::Role::WantsCurrentUser
);

has_control name => (
    is        => 'rw',

    control   => 'text',
    traits    => [ 'Model::Column' ],
    features  => {
        required => 1,
        trim     => 1,
    },
);

has owner => (
    is        => 'rw',
    isa       => 'Qublog::Schema::Result::User',
    required  => 1,
    traits    => [ 'Model::Column' ],
    lazy      => 1,
    default   => sub {
        my $self = shift;
        $self->current_user;
    },
);

has start_time => (
    is        => 'rw',
    isa       => 'DateTime',
    required  => 1,
    default   => sub { DateTime->now },
    traits    => [ 'Model::Column' ],
);

1;
