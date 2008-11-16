use strict;
use warnings;

package Qublog::Mixin::Model::Nicknamed;
use base qw/ Jifty::DBI::Record::Plugin /;

our @EXPORT = qw(
    nicknames
    nickname
    autonick
    add_nickname
    remove_nickname
    load_by_nickname
);

=head1 NAME

Qublog::Mixin::Model::Nicknamed - Provides additional methods for dealing with nicknames

=head1 SYNOPSIS

  # Please add one..

=head1 DESCRIPTION

Something that can be nicknamed should use this class to add nickname-related methods.

=cut

use Jifty::DBI::Schema;
use Jifty::Record schema {

};

=head1 METHODS

=head2 nicknames

This returns a list of strings for all the nicknames that have been assigned to the current object. Returns an empty list if the current object does not have an ID.

=cut

sub nicknames {
    my $self = shift;
    return () unless $self->id;
    my $nicknames = Qublog::Model::NicknameCollection->new;
    $nicknames->limit(
        column => 'kind',
        value  => Qublog::Model::Nickname->kind_of_object($self),
    );
    $nicknames->limit(
        column => 'object_id',
        value  => $self->id,
    );
    $nicknames->order_by({
        column => 'id',
        order  => 'DES',
    });
    return map { $_->nickname } @{ $nicknames->items_array_ref };
}

=head2 nickname

This returns the most recently added nickname for the current object. Returns C<undef> if the current object does not have an ID.

=cut

sub nickname {
    my $self = shift;
    my @nicknames = $self->nicknames;

    # The very last nickname should be the current nick
    return scalar $nicknames[0];
}

=head2 autonick

This returns the original sticky nickname for the current object. Returns C<undef> if the current object does not have an ID.

=cut

sub autonick {
    my $self = shift;
    my @nicknames = $self->nicknames;

    # The very first nickname should be the auto nick
    return scalar $nicknames[-1];
}

=head2 add_nickname

Adds a new nickname to the current object. If the nickname is already taken or is not made up of only letters and numbers, this method will fail with an exception.

=cut

sub add_nickname {
    my ($self, $nick_str) = @_;
    my $nickname = Qublog::Model::Nickname->new;
    $nickname->create_nickname( $nick_str => $self );
}

=head2 remove_nickname

Removes a nickname from the current object. If the nickname is sticky, this will fail with an exception.

=cut

sub remove_nickname {
    my ($self, $nick_str) = @_;
    my $nickname = Qublog::Model::Nickname->new;
    $nickname->load_by_cols( nickname => $nick_str );
    $nickname->delete;
}

=head2 load_by_nickname

Loads the object that has the given nickname.

=cut

sub load_by_nickname {
    my ($self, $nick_str) = @_;
    my $nickname = Qublog::Model::Nickname->new;
    my $kind     = $nickname->kind_of_object($self);
    $nickname->load_by_cols(
        nickname  => $nick_str,
        kind      => $kind,
    );
    if ($nickname->id) {
        return $self->load($nickname->object_id);
    }
    else {
        return (0, "Could not find a $kind for the requested nickname");
    }
}

=head1 TRIGGERS

=head2 register_triggers

This registers a trigger for the nicknamed object to assign the auto-nick after a successful create.

=cut

sub register_triggers {
    my $self = shift;

    $self->add_trigger(
        after_create => sub {
            my ($self, $id) = @_;
            return unless $$id;

            $self->load($$id);
            my $autonick = Qublog::Model::Nickname->new;
            $autonick->create_automatic_nickname($self);

            return 1;
        }
    );
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

This is free software. You may modify and distributed it under the terms of the Artistic 2.0 license.

=cut

1;
