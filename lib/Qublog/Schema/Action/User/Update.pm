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
    is        => 'rw',
    isa       => 'Int',

    placement => 10,
    control   => 'value',
    traits    => [ 'Model::Column' ],

    options   => {
        value => 0,
    },

    features  => {
        fill_on_assignment => { slot => 'value' }
    },
);

has_control name => (
    is        => 'rw',

    placement => 10,
    control   => 'value',
    traits    => [ 'Model::Column' ],

    options   => {
        label      => 'Login name',
        is_visible => 1,
        value      => '',
    },

    features  => {
        fill_on_assignment => { slot => 'value' },
    },
);

has_control old_password => (
    is        => 'rw',

    placement => 40,
    control   => 'password',

    options   => {
        label => 'Old Password',
    },
);

has_checker correct_old_password => sub {
    my $self = shift;

    return unless $self->controls->{old_password}->has_current_value;

    my $password = $self->controls->{old_password}->current_value;
    unless ($self->record->check_password($password)) {
        $self->result->field_error(
            old_password => 'Old password is not correct.'
        );
        $self->result->is_valid(0);
    }
};

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
