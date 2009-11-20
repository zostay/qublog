package Qublog::Form::Factory::HTML::Widget::ListItem;
use Moose;

extends qw( Qublog::Form::Factory::HTML::Widget::Element );

has '+tag_name' => (
    default   => 'li',
);

has '+content' => (
    required  => 1,
);

sub has_content { 1 }

1;
