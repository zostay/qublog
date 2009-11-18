package Qublog::Schema::Action::User::Update;
use Moose;

use Qublog::Form::Processor;

extends qw( Qublog::Schema::Action::User::Store );
with qw( Qublog::Schema::Action::Role::Lookup::Find);

has_control old_password => (
    label    => 'Old Password',
    control  => 'password',
    features => {
        required => 1,
    },
);

override success_message => sub {
    return 'updated your profile';
};

1;
