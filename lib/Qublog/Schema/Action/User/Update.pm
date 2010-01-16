package Qublog::Schema::Action::User::Update;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::User::Store );
with qw( Qublog::Schema::Action::Role::Lookup::Find);

use_feature require_none_or_all => {
    groups => {
        password => [ qw(
            old_password
            new_password
            confirm_password
        ) ],
    },
};

use_feature 'automatic_lookup';

has_control id => (
    placement => 10,
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
