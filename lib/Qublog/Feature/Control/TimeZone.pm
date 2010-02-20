package Qublog::Feature::Control::TimeZone;
use Moose;

use DateTime::TimeZone;

with qw(
    Form::Factory::Feature
    Form::Factory::Feature::Role::Control
    Form::Factory::Feature::Role::ControlValueConverter
);

sub check_control {
    my ($self, $control) = @_;

    die "only scalar valued controls are supported"
        unless $control->does('Form::Factory::Control::Role::ScalarValue');
}

sub value_to_control {
    my ($self, $value) = @_;
    return $value->name;
}

sub control_to_value {
    my ($self, $value) = @_;
    return DateTime::TimeZone->new( name => $value );
}

package Form::Factory::Feature::Control::Custom::TimeZone;
sub register_implementation { 'Qublog::Feature::Control::TimeZone' }

1;
