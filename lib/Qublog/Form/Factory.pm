package Qublog::Form::Factory;
use Moose::Role;

use Qublog::Util qw( class_name_from_name );

requires qw( render_control consume_control );

=head1 NAME

Qublog::Form::Factory - interface for control factories

=head1 DESCRIPTION

Defines the abstract interface for a form factory. 

=head1 METHODS

=head2 control_class

  my $class_name = $factory->control_class('full_text');

Returns the control class for the named control.

=cut

sub control_class {
    my ($self, $name);

    my $class_name = 'Qublog::Form::Control::' . class_name_from_name $name;

    unless (Class::MOP::load_class($class_name)) {
        warn $@ if $@;
        return;
    }

    return $class_name;
}

=head2 new_control

  my $control = $factory->new_control(text => {
      name          => 'foo',
      default_value => 'bar',
  });

Given the short name for a control and a hash reference of initialization arguments, return a fully initialized control.

=cut

sub new_control {
    my ($self, $name, $args) = @_;

    my $class_name = $self->control_class($name);
    return unless $class_name;

    return $class_name->new($args);
}

=head1 ROLE METHODS

Roles must implement the following methods.

=head2 new_widget_for_control

  my $widget = $factory->new_widget_for_control(text => $control);

Given the short name for a control and a control object, return the widget to attach to the control.

=head1 CONTROLS

Here's a list of controls and the classes they represent:

=over

=item button

L<Qublog::Form::Control::Button>

=item checkbox

L<Qublog::Form::Control::Checkbox>

=item full_text

L<Qublog::Form::Control::FullText>

=item password

L<Qublog::Form::Control::Password>

=item select_many

L<Qublog::Form::Control::SelectMany>

=item select_one

L<Qublog::Form::Control::SelectOne>

=item text

L<Qublog::Form::Control::Text>

=item value

L<Qublog::Form::Control::Value>

=back

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
