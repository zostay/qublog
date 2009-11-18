package Qublog::Form::Feature::MatchRegex;
use Moose;

with qw( Qublog::Form::Feature );

has regex => (
    is        => 'ro',
    isa       => 'Regexp',
    required  => 1,
);

sub check_control {
    my ($self, $control) = @_;

    return 1 if $control->does('Qublog::Form::Control::Role::ScalarValue');
    return;
}

sub validate_value {
    my ($self, $value) = @_;

    my $regex = $self->regex;
    unless ($value =~ /$regex/) {
        $self->error("the %s does not match $regex");
    }
}

1;
