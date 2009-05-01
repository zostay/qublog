use strict;
use warnings;

package Qublog::Model::Tag;
use base qw/ Class::Data::Inheritable /;
use Jifty::DBI::Schema;

use Number::RecordLocator;

__PACKAGE__->mk_classdata( _locator => Number::RecordLocator->new );

=head1 NAME

Qublog::Model::Tag - tag tasks and comments

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

Tags can be attached to tasks and comments and are also used to associated extra metadata with tasks and comments.

=head1 SCHEMA

=head2 name

This is the name of the tag. This must be alphanumeric and is the part that is generally placed after a pound sign. For example a value of "XG12" would be stored here for the tag noted as "#XG12".

Setting this to "-" on create will result in the creation of an "auto-tag". An auto-tag is one which has an automatically generated name using L<Number::Locator> applied to the ID assigned to the record.

In 0.4.0, the experiment with nicknames added with 0.3.0 was collapsed into this class. This included the addition of this column.

=head2 task_tags

This is a collection representing all the L<Qublog::Model::TaskTag> objects linking this class to tasks.

=cut

use Qublog::Record schema {
    column name =>
        type is 'text',
        label is 'Name',
        default is '-',
        is mandatory,
        is distinct,
        is immutable,
        since '0.4.0',
        ;

    column task_tags =>
        references Qublog::Model::TaskTagCollection by 'tag';

    column comment_tags =>
        references Qublog::Model::CommentTagCollection by 'tag';

    column journal_entry_tags =>
        references Qublog::Model::CommentTagCollection by 'tag';
};

=head1 METHODS

=head2 since

This has been part of the application since database version 0.3.1.

=cut

sub since { '0.3.1' }

=head2 task

If this tag is used as a nickname for a task. This returns that task or C<undef> if none is found.

=cut

sub task {
    my $self = shift;

    my $tasks = Qublog::Model::TaskTagCollection->new;
    $tasks->limit( tag => $self );
    $tasks->limit( nickname => 1 );
    return $tasks->first;
}

=head2 tasks

Finds all tasks linked to this tag.

=cut

sub tasks {
    my $self = shift;

    my $tasks = Qublog::Model::TaskCollection->new;
    my $task_tag_alias = $tasks->join(
        column1 => 'id',
        table2  => Qublog::Model::TaskTag->table,
        column2 => 'task',
    );
    $tasks->limit(
        alias  => $task_tag_alias,
        column => 'tag',
        value  => $self,
    );

    return $tasks;
}

=head2 comments

Finds all comments linked to this tag.

=cut

sub comments {
    my $self = shift;

    my $comments = Qublog::Model::CommentCollection->new;
    my $comment_tag_alias = $comments->join(
        column1 => 'id',
        table2  => Qublog::Model::CommentTag->table,
        column2 => 'comment',
    );
    $comments->limit(
        alias  => $comment_tag_alias,
        column => 'tag',
        value  => $self,
    );

    return $comments;
}

=head2 journal_entries

Finds all journal entries linked to this tag.

=cut

sub journal_entries {
    my $self = shift;

    my $journal_entries = Qublog::Model::JournalEntryCollection->new;
    my $journal_entry_tag_alias = $journal_entries->join(
        column1 => 'id',
        table2  => Qublog::Model::JournalEntryTag->table,
        column2 => 'journal_entry',
    );
    $journal_entries->limit(
        alias  => $journal_entry_tag_alias,
        column => 'tag',
        value  => $self,
    );

    return $journal_entries;
}

=head1 INTERNAL HELPERS

These are not intended to have any user-serviceable parts and are for the internal use of this class.

=head2 _id_to_tag_name

  my $tag_name = $self->_id_to_tag_name($id);

This is a helper function for converting the given ID number into a tag name. This is done using L<Number::RecordLocator>. This is used when creating an auto-tag.

=cut

sub _id_to_tag_name {
    my ($self, $id) = @_;

    return undef if $id =~ /[^0-9]/;

    return $self->_locator->encode($id);
}

=head1 TRIGGERS

=head2 after_create

This is where auto-tags are generated from the ID using L<Number::RecordLocator>.

=cut

sub after_create {
    my ($self, $id) = @_;

    # Either get it or forget it
    return 1 unless $$id;
    $self->load($$id);

    # If we get a - for a name (not normally legal), add the autonick
    if ($self->name eq '-') {
        my $name = $self->_id_to_tag_name($self->id);
        $self->_set( column => 'name', value => $name );
    }

    return 1;
}

=head2 current_user_can

Everyone can.

=cut

sub current_user_can { 1 }

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;

