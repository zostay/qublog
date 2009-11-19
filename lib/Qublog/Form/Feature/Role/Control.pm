package Qublog::Form::Feature::Role::Control;
use Moose::Role;

use Scalar::Util qw( blessed );

requires qw( check_control );

has control => (
    is        => 'ro',
    does      => 'Qublog::Form::Control',
    required  => 1,
    initializer => sub {
        my ($self, $value, $set, $attr) = @_;
        $self->check_control($value);
        $self->action($value->action);
        $set->($value);
    },
);

sub format_message {
    my $self    = shift;
    my $message = $self->message || shift;

    my $control_label 
        = $control->does('Qublog::Form::Control::Role::Labeled') ? $control->label
        :                                                          $control->name
        ;

    sprintf $message, $control_label;
}

sub control_info {
    my $self    = shift;
    my $message = $self->format_message(shift);
    $self->result->field_info($self->control->name, $message);
}

sub control_warning {
    my $self = shift;
    my $message = $self->format_message(shift);
    $self->result->field_warning($self->control->name, $message);
}

sub control_error {
    my $self = shift;
    my $message = $self->format_message(shift);
    $self->result->field_error($self->control->name, $message);
}

1;
