package Qublog::Form::Control::Button;
use Moose;

with qw(
    Qublog::Form::Control
    Qublog::Form::Control::Role::Labeled
    Qublog::Form::Control::Role::ScalarValue
);

sub current_value { 
    my $self = shift;
    warn "attempt to change read-only label failed" if @_;
    return $self->label;
}

1;
