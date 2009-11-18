package Qublog::Schema::Action::User::Create;
use Moose;

use Qublog::Form::Processor;

extends qw( Qublog::Schema::Action::User::Store );
with qw( Qublog::Schema::Action::Role::Lookup::New);

has_control 'id' => (
    control  => 'stash',
);

has_control '+name' => (
    control  => 'text',
    features => {
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

has_control password => (
    control  => 'stash',
    default  => '*',
);

check user => sub {
    my ($self, $options) = @_;
    my $schema = $options->{schema};

    my $user = $schema->resultset('User')->find({ name => $self->name });
    if ($user) {
        $self->result->field_error({
            field   => 'name',
            message => 'sorry, that %s is already in use',
        });
    }
};

after run => sub {
    my ($self, $options) = @_;

    $self->record->change_password($self->new_password);
    $self->update;
};

override success_message => sub {
    return 'created your profile, you may now sign in',
};

1;