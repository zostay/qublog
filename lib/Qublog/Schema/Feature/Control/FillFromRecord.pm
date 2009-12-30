package Qublog::Schema::Feature::Control::FillFromRecord;
use Moose;

use Scalar::Util qw( blessed );

with qw(
    Form::Factory::Feature
    Form::Factory::Feature::Role::BuildControl
    Form::Factory::Feature::Role::Control
);

sub check_control { }

sub build_control {
    my ($class, $options, $action, $name, $control) = @_;

    my $value = $action->record->$name;

    # HACK This is an ugly kludge, but it works for the time being
    $value = $value->name if blessed $value and $value->isa('DateTime::TimeZone');

    $control->{options}{value} = $value if defined $value;
}

package Form::Factory::Feature::Control::Custom::FillFromRecord;
sub register_implementation { 'Qublog::Schema::Feature::Control::FillFromRecord' }

1;
