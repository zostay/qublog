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
        $set->($value);
    },
);

1;
