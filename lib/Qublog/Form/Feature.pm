package Qublog::Form::Feature;
use Moose::Role;

requires qw( check_control );

has control => (
    is        => 'ro',
    isa       => 'Qublog::Form::Control',
    required  => 1,
    weak_ref  => 1,
);

has message => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_message',
);

sub clean {
    my ($self, $value, %options) = @_;

    return $self->clean_value($value, %options) if $self->can('clean_value');
    return $value;
}

sub validate {
    my ($self, $value, %options) = @_;
    $self->validate_value($value, %options) if $self->can('validate_value');
}

# TODO Implement...
# sub error {}
# sub warning {}
# sub info {}

1;
