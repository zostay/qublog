package Qublog::Form::Factory::HTML::Widget::Span;
use Moose;

with qw( Qublog::Form::Factory::HTML::Widget );

extends qw( Qublog::Form::Factory::HTML::Widget::Element );

has for => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has '+content' => (
    required  => 1,
);

sub consume_control { }

1;
