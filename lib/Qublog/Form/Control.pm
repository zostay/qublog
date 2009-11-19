package Qublog::Form::Control;
use Moose::Role;

=head1 NAME

Qublog::Form::Control - high-level API for working with form controls

=head1 DESCRIPTION

Allows for high level processing, validation, filtering, etc. of form control information.

=head1 ATTRIBUTES

=head2 name

This is the base name for the control.

=cut

has name => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

=head2 stashable_keys

This is the list of control keys that may be stashed.

=cut

# TODO This really ought to be a meta-attribute.
has stashable_keys => (
    is        => 'ro',
    isa       => 'ArrayRef',
    required  => 1,
    lazy      => 1,
    default   => sub { [] },
);

1;
