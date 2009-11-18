package Qublog::Form::Control::SelectOne;
use Moose;

with qw(
    Qublog::Form::Control
    Qublog::Form::Control::Role::Labeled
);

has value => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_value',
);

has default_value => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_default_value',
);

has available_choices => (
    is        => 'ro',
    isa       => 'ArrayRef[Qublog::Form::Control::Choice]',
    required  => 1,
    default   => sub { [] },
);

sub current_value {
    my $self = shift;

    return $self->has_value         ? $self->value
         : $self->has_default_value ? $self->default_value
         :                            '';
}

1;
