package Qublog::Form::Factory::HTML::Widget::Div;
use Moose;

with qw( Qublog::Form::Factory::HTML::Widget );

extends qw( Qublog::Form::Factory::HTML::Widget::Element );

has widgets => (
    is        => 'ro',
    isa       => 'ArrayRef',
    required  => 1,
    default   => sub { [] },
);

augment render_content => sub {
    my $self = shift;
    return $self->content . (inner() || '');
};

sub consume_control {
    my $self = shift;
    my %args_accumulator;

    %args_accumulator = (%args_accumulator, $_->consume(@_)) for @{ $self->widgets };

    return \%args_accumulator;
}

1;
