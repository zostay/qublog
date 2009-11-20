package Moose::Meta::Attribute::Custom::Trait::Form::Control;
sub register_implementation { 'Qublog::Form::Action::Meta::Attribute::Control' }

package Qublog::Form::Action::Meta::Attribute::Control;
use Moose::Role;

has control => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => 'text',
);

has options => (
    is        => 'ro',
    isa       => 'HashRef',
    required  => 1,
    default   => sub { {} },
);

has features => (
    is          => 'ro',
    isa         => 'HashRef[HashRef]',
    required    => 1,
    default     => sub { {} },
);

1;
