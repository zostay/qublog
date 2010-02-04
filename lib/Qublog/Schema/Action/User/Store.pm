package Qublog::Schema::Action::User::Store;
use Form::Factory::Processor;

with qw(
    Qublog::Schema::Action::Role::Model::User
    Qublog::Schema::Action::Role::Do::Store
);

use DateTime::TimeZone;
use Email::Valid;

has_control email => (
    placement => 20,
    control   => 'text',
    traits    => [ 'Model::Column' ],
    options   => {
        label => 'Email Address',
    },
    features  => {
        fill_on_assignment => 1,
        trim             => 1,
        required         => 1,
        match_code       => {
            code    => sub { 
                my $value = shift;
                length($value) == 0 or Email::Valid->address($value);
            },
            message => 'the %s you typed does not look right',
        },
    },
);

has_control time_zone => (
    isa       => 'DateTime::TimeZone',
    coerce    => 1,

    placement => 100,
    control   => 'select_one',
    traits    => [ 'Model::Column' ],
    options   => {
        available_choices => deferred_value {
            [ 
                map { Form::Factory::Control::Choice->new($_) }
                      DateTime::TimeZone->all_names
            ]
        },
    },
    features  => {
        fill_on_assignment      => 1,
        required                => 1,
        match_available_choices => 1,
    },
);

has_control new_password => (
    placement => 50,
    control   => 'password',
    features => {
        length   => {
            minimum => 6,
        },
    },
);

has_control confirm_password => (
    placement => 60,
    control   => 'password',
);

has_checker password_and_confirmation => sub {
    my ($self) = @_;

    my $new_password     = $self->controls->{new_password}->current_value;
    my $confirm_password = $self->controls->{confirm_password}->current_value;

    return unless $new_password and $confirm_password;

    if ($new_password ne $confirm_password) {
        $self->result->field_error(
            confirm_password => 'the passwords you entered do not match, please try again',
        );
    }
};

1;
