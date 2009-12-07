package Qublog::Schema::Action::User::Create;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::User::Store );
with qw( Qublog::Schema::Action::Role::Lookup::New );

has_control name => (
    placement => 10,
    traits    => [ 'Model::Column' ],
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
            regex   => qr/^[\w\ '\-]*$/,
            message => 'your %s may only contain letters, numbers, spaces, apostrophes, and hypens',
        },
    },
);

has password => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => '*',
    traits    => [ 'Model::Column' ],
);

has_checker user => sub {
    my ($self) = @_;
    my $name = $self->controls->{name}->current_value;

    my $user = $self->schema->resultset('User')->find({ name => $name });
    if ($user) {
        $self->result->field_error(
            name => 'sorry, that login name is already in use',
        );
    }
};

after do => sub {
    my $self = shift;

    return unless $self->is_success;

    $self->record->change_password($self->new_password);
    $self->record->update;
};

override success_message => sub { 'created your profile, you may now sign in' };

1;
