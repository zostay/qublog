package Qublog::Form::Widget::Span;
use Moose;

with qw( Qublog::Form::Widget Qublog::Form::Widget::Element );

has for => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has '+content' => (
    required  => 1,
);

sub process_control { }

1;
