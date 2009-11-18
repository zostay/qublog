package Qublog::Form::Feature::Length;
use Moose;

with qw( Qublog::Form::Feature );

has minimum => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_minimum',
);

has maximum => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_maximum',
);

sub BUILDARGS {
    my $class = shift;
    my $args  = @_ == 1 ? $_[0] : { @_ };

    if (defined $args->{minimum} and defined $args->{maximum}
            and $args->{minimum} >= $args->{maximum}) {
        die 'length minimum must be less than maximum';
    }

    return $self->SUPER::BUILDARGS(@_);
}

sub check_control {
    my ($self, $control) = @_;

    return 1 if $control->does('Qublog::Form::Control::Role::ScalarValue');
    return;
}

sub validate_value {
    my ($self, $control, $value) = @_;

    if ($self->has_minimum and length($value) < $self->minimum) {
        $self->error("the %s must be at least @{[$self->minimum]} characters long");
    }

    if ($self->has_maximum and length($value) > $self->maximum) {
        $self->error("the %s must be no longer than @{[$self->maximum]} characters");
    }
}

1;
