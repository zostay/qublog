package Qublog::Form::Widget::Input;
use Moose;

with qw( Qublog::Form::Widget );

extends qw( Qublog::Form::Widget::Element );

=head1 NAME

Qublog::Form::Widget::Input - input controls

=head1 DESCRIPTION

General purpose HTML input elements.

=head1 ATTRIBUTES

=head2 tag_name

It is "input" by default.

=cut

has '+tag_name' => (
    default => 'input',
);

=head2 type

The HTML control type.

=cut

has type => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => 'text',
);

=head2 name

The name of the control.

=cut

has name => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

=head2 value

The default value to put into the control.

=cut

has value => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => '',
);

=head2 size

The size of the control.

=cut

has size => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_size',
);

=head2 maxlength 

The length to cap the control at.

=cut

has maxlength => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_maxlength',
);

=head2 disabled

Disabling the control.

=cut

has disabled => (
    is        => 'ro',
    isa       => 'Bool',
);

=head2 readonly

Make the control read-only in the browser.

=cut

has readonly => (
    is        => 'ro',
    isa       => 'Bool',
);

=head2 tabindex

The tab index to assign to the control.

=cut

has tabindex => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_tabindex',
);

=head2 alt

A alternate description of the control.

=cut

has alt => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_alt',
);

=head2 checked

For checkboxes and radio buttons, whether or not the control should be checked to start.

=cut

has checked => (
    is        => 'ro',
    isa       => 'Bool',
);

=head1 METHODS

=head2 process_control

Harvest the input from the HTML INPUT.

=cut

sub process_control {
    my ($self, %options) = @_;
    my $params = $options{params};
    my $name   = $self->name;

    return { $name => $params->{ $name } };
}

=head2 more_attributes

Returns the attributes for making an INPUT tag.

=cut

override more_attributes => sub {
    my $self = shift;

    my %attributes = (
        type  => $self->type,
        name  => $self->name,
        value => $self->value,
    );

    $attributes{size}      = $self->size      if $self->has_size;
    $attributes{maxlength} = $self->maxlength if $self->has_maxlength;
    $attributes{disabled}  = 'disabled'       if $self->disabled;
    $attributes{readonly}  = 'readonly'       if $self->readonly;
    $attributes{tabindex}  = $self->tabindex  if $self->has_tabindex;
    $attributes{alt}       = $self->alt       if $self->has_alt;
    $attributes{checked}   = 'checked'        if $self->checked;

    return \%attributes;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 LICENSE

Qublog Personal/Professional Journaling
Copyright (C) 2009  Andrew Sterling Hanenkamp

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
