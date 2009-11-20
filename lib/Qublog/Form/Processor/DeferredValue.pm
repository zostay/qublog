package Qublog::Form::Processor::DeferredValue;
use Moose;

has code => (
    is        => 'ro',
    isa       => 'CodeRef',
    required  => 1,
);

1;
