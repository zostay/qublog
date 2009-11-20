package Qublog::Schema::Action::User::Update;
use Moose;

use Qublog::Form::Processor;

extends qw( Qublog::Schema::Action::User::Store );
with qw( Qublog::Schema::Action::Role::Lookup::Find);

has_control name => (
    control  => 'view',
    options  => {
        label => 'Login name',
    },
);

has_control old_password => (
    control  => 'password',
    options  => {
        label => 'Old Password',
    },
    features => {
        required => 1,
    },
);

override success_message => sub {
    return 'updated your profile';
};

1;
