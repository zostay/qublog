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

=head2 widgets

This is the list of low-level widget objects responsible for rendering and processing the data from the client.

=cut

has widgets => (
    is        => 'ro',
    isa       => 'ArrayRef',
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

=head2 features

These are the features that have been assigned to this instance of the control.

=cut

has features => (
    is        => 'ro',
    isa       => 'ArrayRef',
    required  => 1,
    default   => sub { [] },
);

=head1 METHODS

=head1 render

Renders the widget and any messages, errors, etc.

=cut

sub render {
}

=head1 process

Processes the input from the widget and applies any of the desired features.

=cut

sub process {
}

1;
