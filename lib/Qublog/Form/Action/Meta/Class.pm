package Qublog::Form::Action::Meta::Class;
use Moose::Role;

has cleaners => (
    is       => 'ro',
    isa      => 'ArrayRef[HashRef]',
    required => 1,
    default  => sub { [] },
);

has checkers => (
    is       => 'ro',
    isa      => 'ArrayRef[HashRef]',
    required => 1,
    default  => sub { [] },
);

sub get_controls {
    my ($meta, @control_names) = @_;

    my @controls;
    if (@control_names) {
        @controls = grep { $_ } map { $meta->get_attribute($_) } @control_names;
    }

    else {
        @controls = $meta->get_all_attributes;
    }

    @controls = grep { $_->does('Qublog::Form::Action::Meta::Attribute::Control') } 
                     @controls;
}

1;