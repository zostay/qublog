package Qublog::Form::Feature::MatchCode;
use Moose;

with qw( Qublog::Form::Feature );

has code => (
    is        => 'ro',
    isa       => 'CodeRef',
    required  => 1,
);

sub check_control { 1 }

sub validate_value {
    my ($self, $value) = @_;

    unless ($self->code->($value)) {
        $self->error('the %s is not correct');
    }
}

1;
