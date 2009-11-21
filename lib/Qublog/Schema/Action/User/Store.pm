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

has_control email => (
    placement => 20,
    control   => 'text',
    options   => {
        label => 'Email Address',
    },
    features  => {
        trim       => 1,
        required   => 1,
        match_code => {
            code    => sub { Email::Valid->address(shift) },
            message => 'the %s you typed does not look right',
        },
    },
);

has_control time_zone => (
    isa       => 'Qublog::DateTime::TimeZone',
    coerce    => 1,

    placement => 100,
    control   => 'select_one',
    options   => {
        available_choices => deferred_value {
            [ 
                map { Qublog::Form::Control::Choice->new($_) }
                      DateTime::TimeZone->all_names
            ]
        },
    },
    features  => {
        required                => 1,
        match_available_choices => 1,
    },
);

has_control new_password => (
    placement => 50,
    control   => 'password',
    features => {
        required => 1,
        length   => {
            minimum => 6,
        },
    },
);

has_control confirm_password => (
    placement => 60,
    control   => 'password',
    features => {
        required => 1,
    },
);

has_checker password_and_confirmation => sub {
    my ($self) = @_;

    return unless $self->new_password;
    return unless $self->confirm_password;

    if ($self->new_password ne $self->confirm_password) {
        $self->result->error(
            'the passwords you entered do not match, please try again',
        );
    }
};

1;
