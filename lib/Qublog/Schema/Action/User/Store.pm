package Qublog::Schema::Action::User::Store;
use Moose;

use Qublog::Form::Processor;

with qw(
    Qublog::Schema::Action::Role::Model::User
    Qublog::Schema::Action::Role::Do::Store
);

use DateTime::TimeZone;
use Email::Valid;

use Moose::Util::TypeConstraints;

subtype 'Qublog::DateTime::TimeZone' => as class_type('DateTime::Timezone');

coerce 'Qublog::DateTime::TimeZone' 
    => from 'Str'
    => via { DateTime::TimeZone->new( name => $_ ) };

no Moose::Util::TypeConstraints;

has_control name => (
    label    => 'Login name',
    control  => 'view',
);

has_control email => (
    label    => 'Email address',
    control  => 'text',
    features => {
        trim       => 1,
        required   => 1,
        match_code => {
            code    => sub {
                my ($self, $options, $name, $value) = @_;
                return Email::Valid->address($value);
            },
            message => 'the %s you typed does not look right',
        },
    },
);

has_control time_zone => (
    isa      => 'Qublog::DateTime::TimeZone',
    coerce   => 1,

    label    => 'Time zone',
    control  => 'select_one',
    options  => {
        available_options => sub {
            my ($self, $options, $name) = @_;
            return DateTime::TimeZone->all_names;
        },
    },
    features => {
        required                => 1,
        match_available_choices => 1,
    },
);

has_control new_password => (
    label    => 'New Password',
    control  => 'password',
    features => {
        required => 1,
        length   => {
            minimum => 6,
        },
    },
);

has_control confirm_password => (
    label    => 'Confirm password',
    control  => 'password',
    features => {
        required => 1,
    },
);

check password_and_confirmation => sub {
    my ($self, $options) = @_;

    unless ($self->password eq $self->confirm_password) {
        $self->result->error({
            message => 'the passwords you entered do not match, please try again',
        });
    }
};

1;
