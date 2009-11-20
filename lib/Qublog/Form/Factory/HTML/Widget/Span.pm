package Qublog::Form::Factory::HTML::Widget::Span;
use Moose;

extends qw( Qublog::Form::Factory::HTML::Widget::Element );

has '+tag_name' => (
    default   => 'span',
);

has '+content' => (
    required  => 1,
);

sub has_content { 1 }

1;
