package Qublog::Form::Control::Role::Labeled;
use Moose::Role;

has label => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    builder   => 'build_label',
);

sub build_label {
    my $self = shift;

    # TODO This can be much smarter
    return ucfirst $self->name;
}

1;
