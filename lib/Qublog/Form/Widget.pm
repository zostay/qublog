package Qublog::Form::Widget;
use Moose::Role;

requires qw( render_control process_control );

=head1 NAME

Qublog::Form::Widget - rendering/processing HTML controls

=head1 DESCRIPTION

Widget is the low-level API for rendering and processing HTML/HTTP form elements.

=head1 ATTRIBUTES

=head2 alternate_renderer

If the renderer needs to be customized, provide a custom renderer here. This is a code reference that is passed the control and options like the usual renderer method.

=cut

has alternate_renderer => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'has_alternate_renderer',
);

=head2 alternate_processor

If the control needes to be processed in a custom way, you can add that here. This is a code reference that is passed the control and options like the usual processor method.

=cut

has alternate_processor => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'has_alternate_processor',
);

=head1 METHODS

=head2 render

Renders the HTML required to use this method.

=cut

sub render {
    my $self = shift;

    if ($self->has_alternate_renderer) {
        $self->alternate_renderer->($self, @_);
    }
    else {
        $self->render_control(@_);
    }
}

=head2 process

Processes the request.

=cut

sub process {
    my $self = shift;

    if ($self->has_alternate_processor) {
        $self->alternate_processor->($self, @_);
    }
    else {
        $self->process_control(@_);
    }
}

=head1 ROLE METHODS

These methods must be implemented by role implementers.

=head2 render_control

Return HTML to render the control.

=head2 process_control

Given processor options, process the input.

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
