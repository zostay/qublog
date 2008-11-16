use strict;
use warnings;

package Qublog::Model::Nickname;
use base qw/ Class::Data::Inheritable /;
use Jifty::DBI::Schema;

use Number::RecordLocator;

__PACKAGE__->mk_classdata( _locator => Number::RecordLocator->new );

=head1 NAME

Qublog::Model::Nickname - things with nicknames go here

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

Nicknames are intended to provide simple, easy to reference words to refer to objects in Qublog. As of this writing the following model objects may have nicknames:

=over

=item *

L<Qublog::Model::Task>

=back

Here are some facts about nicknames:

=over

=item *

When an object that uses nicknames is created, it is assigned an automatic nickname. An automatic nickname is:

=over

=item *

Generally assigned as a sequence number.

=item *

A word using letters and numbers that is relatively short and easy to remember. This is created with the help of L<Number::RecordLocator> (go to that documentation for more details).

=item *

Permanently assigned and forever unique for that object. It cannot be reused by anything else and it cannot be changed.

=back

=item *

Objects may have more than one nickname referring to them.

=item *

A nickname may only be used to refer to one object. However, it is easy to change which object a given nickname refers to or remove it altogether.

=back

=head1 SCHEMA

=head2 nickname

The actual albphanumeric string containing the nickname.

=head2 kind

The kind of thing this nickname points to. Is one of the following:

=over

=item Task

A nickname referring to a L<Qublog::Model::Task> object.

=back

=head2 object_id

This is the ID of the object this nickname refers to. Combined with L<kind>, we have enough information to load the referred object.

=head2 sticky

This is a boolean flag that is usually only ever set on automatic nicknames. If this flag is set, then the nickname cannot be deleted.

=cut

use Qublog::Record schema {
    column nickname =>
        type is 'text',
        label is 'Nickname',
        is mandatory,
        is distinct,
        is immutable,
        ;

    column kind =>
        type is 'text',
        label is 'Kind',
        is mandatory,
        is immutable,
        valid_values are qw(
            Task
            Tag
        ),
        ;

    column object_id =>
        type is 'int',
        label is 'Object ID',
        is mandatory,
        is immutable,
        ;

    column sticky =>
        type is 'bool',
        label is 'Sticky?',
        is mandatory,
        is immutable,
        default is 0,
        ;
};

=head1 METHODS

In general, one should not use the typical methods and accessors available in the nickname model. Instead, a number of helper methods are provided that just make the right thing go when needed.

=head2 since

This model was added with database version 0.3.0

=cut

sub since { '0.3.0' }

=head2 create_automatic_nickname

  my $nickname = Qublog::Model::Nickname->new;
  $nickname->create_automatic_nickname($object);

Given an object to nickname, this will generate the new sticky nickname.

=cut

sub create_automatic_nickname {
    my ($self, $object) = @_;

    # Bad stuff?
    die "The object most have an ID." unless $object->id;

    # What is it?
    my $kind = $self->kind_of_object($object);

    # Nickname it
    return $self->create(
        nickname  => '-',
        kind      => $kind,
        object_id => $object->id,
        sticky    => 1,
    );
}

=head2 create_nickname

  my $nickname = Qublog::Model::Nickname->new;
  $nickname->create_nickname( nickname => $object );

Given a custom nickname and object, this will generate a new nickname. The nickname must be alphanumeric and may have mixed case.

=cut

sub create_nickname {
    my ($self, $nickname, $object) = @_;

    # Is the nickname okay?
    die "A nickname may only contain letters and numbers." if $nickname =~ /[^A-Z0-9]/i;
    die "The object most have an ID." unless $object->id;


    # What is it?
    my $kind = $self->kind_of_object($object);

    # Nickname it
    return $self->create(
        nickname  => $nickname,
        kind      => $kind,
        object_id => $object->id,
        sticky    => 0,
    );
}

=head1 delete

  my $nickname = Qublog::Model::Nickname->new;
  $nickname->load_by_cols( nickname => '1E5N' );
  $nickname->delete;

  # OR
  
  $nickname->delete( force => 1 );

Prevents deletion of sticky nicknames unless force is present. The only time a sticky nickname should be deleted is if the record to which it belongs is being deleted.

=cut

sub delete {
    my $self = shift;
    my %params = @_;

    die "Will not delete a sticky nickname without being forced."
        if $self->sticky and not $params{force};

    return $self->SUPER::delete;
}

=head2 kind_of_object

  my $kind = $self->kind_of_object($object);

Given a nicknamed object, this will look up the kind of object. This is currently implemented with a hardcoded look table.

=cut

my %kind_to_object = (
    Tag  => 'Qublog::Model::Tag',
    Task => 'Qublog::Model::Task',
);

my %object_to_kind = reverse %kind_to_object;

sub kind_of_object {
    my ($self, $object) = @_;

    # What is it?
    my $object_class = ref $object;
    my $kind = $object_to_kind{ $object_class };

    # More bad stuff?
    die "You must pass a model object." unless $object_class;
    die "The object does not have a known nickname kind." 
        unless $kind;

    return $kind;
}

=head2 object_of_kind 

  my $object = $self->object_of_kind($kind);

Given a kind, it returns an initialized object representing that kind of nicknamed model.

=cut

sub object_of_kind {
    my ($self, $kind) = @_;

    my $class = $kind_to_object{ $kind };

    die "No such kind as $kind." unless defined $class;

    return $class->new;
}

=head1 INTERNAL HELPERS

These are not intended to have any user-serviceable parts and are for the internal use of this class.

=head2 _nickname_to_id

  my $id = $self->_nickname_to_id($nickname);

This is a helper function for converting the given nickname into an ID number. This is done using L<Number::RecordLocator>.

=cut

sub _nickname_to_id {
    my ($self, $text) = @_;

    return undef if $text =~ /[^A-Z0-9]/i;

    return $self->_locator->decode($text);
}

=head2 _id_to_nickname

  my $nickname = $self->_id_to_nickname($id);

This is a helper function for converting the given ID number into a nickname. This is done using L<Number::RecordLocator>.

=cut

sub _id_to_nickname {
    my ($self, $id) = @_;

    return undef if $id =~ /[^0-9]/;

    return $self->_locator->encode($id);
}

=head1 TRIGGERS

=head2 after_create

This is where autonicks are generated from the ID using L<Number::RecordLocator>.

=cut

sub after_create {
    my ($self, $id) = @_;

    # Either get it or forget it
    return 1 unless $$id;
    $self->load($$id);

    # If we get a - for a nickname (not normally legal), add the autonick
    if ($self->nickname eq '-') {
        my $nickname = $self->_id_to_nickname($self->id);
        $self->_set( column => 'nickname', value => $nickname );
    }

    return 1;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;

