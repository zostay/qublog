package Qublog::Schema::Action::User::Update;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::User::Store );
with qw( Qublog::Schema::Action::Role::Lookup::Find);

has_control name => (
    placement => 10,
    control   => 'value',
    traits    => [ 'Model::Column' ],
    options   => {
        label      => 'Login name',
        is_visible => 1,
        value      => '',
    },
);

has_control old_password => (
    placement => 40,
    control   => 'password',
    options   => {
        label => 'Old Password',
    },
    features  => {
        required           => 1,
        fill_on_assignment => 1,
    },
);

after do => sub {
    my $self = shift;

    return unless $self->is_success;

    $self->record->change_password($self->new_password);
    $self->record->update;
};

override success_message => sub {
    return 'updated your profile';
};

1;
