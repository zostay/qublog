package Qublog::Form::Factory::HTML::Widget::List;
use Moose;

extends qw( Qublog::Form::Factory::HTML::Widget::Element );

has '+tag_name' => (
    default   => 'ul',
);

has items => (
    is        => 'ro',
    isa       => 'ArrayRef[Qublog::Form::Factory::HTML::Widget::ListItem]',
    required  => 1,
    default   => sub { [] },
);

sub has_content { 1 }

sub render_items {
    my $self = shift;
    my $content = '';
    for my $item (@{ $self->items }) {
        $content .= $item->render;
    }
    return $content;
}

override render => sub {
    my $self = shift;
    return super() . $self->render_items;
};

sub consume_control { }

1;
