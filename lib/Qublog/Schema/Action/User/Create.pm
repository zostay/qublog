package Qublog::Schema::Action::User::Create;
use Moose;

use Qublog::Form::Processor;
use Qublog::Form::Control::Choice;

extends qw( Qublog::Schema::Action::User::Store );
with qw( Qublog::Schema::Action::Role::Lookup::New );

has_control name => (
    placement => 10,
    control   => 'text',
    options   => {
        label => 'Login Name',
    },
    features  => {
        trim        => 1,
        required    => 1,
        length      => {
            minimum => 3,
        },
        match_regex => {
            regex   => qr/^[\w\ '\-]+$/,
            message => 'your %s may only contain letters, numbers, spaces, apostrophes, and hypens',
        },
    },
);

has_checker user => sub {
    my ($self) = @_;

    my $user = $self->schema->resultset('User')->find({ name => $self->name });
    if ($user) {
        $self->result->field_error({
            field   => 'name',
            message => 'sorry, that %s is already in use',
        });
    }
};

after do => sub {
    my $self = shift;

    return unless $self->is_success;

    $self->record->change_password($self->new_password);
    $self->update;
};

override success_message => sub { 'created your profile, you may now sign in' };

1;
