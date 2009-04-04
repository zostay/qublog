use strict;
use warnings;

package Qublog::Model::TaskTag;
use Jifty::DBI::Schema;

=head1 NAME

Qublog::Model::TaskTag - link tasks to tags

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

This is a list of links used to determine how tag names are associated with tasks. A task should always have exactly one "auto-tag", which is the name automatically assigned to every task on creation. In addition, a tag may have one or more additional tags to name the task. A tag should only be associated with a single task at any given moment, but a task may have multiple tags assigned.

=head2 TODO

 In the future, we want to be able to distinguish between "reference tags" and "topic tags". A "reference tag" is what is currently indicated by records in this link class. A reference tag points to exactly one task. Previously, I used the term "nickname" to describe these kinds of tags and will probably continue to do so in the future since "nickname" is more intuitive than the formal name "reference tag".

 A "topic tag", on the other hand, is used to group tasks into logical units of some kind. For example, a topic tag named "#bug" might be used to group all the bug tasks together across projects while a "#feature" tag indicates features across projects.

=head1 SCHEMA

=head2 task

This is the L<Qublog::Model::Task> end of the link.

=head2 tag

This is the L<Qublog::Model::Tag> end of the link.

=head2 sticky

This determines whether or not this link is "sticky." A sticky tag applied to a task is one that cannot be deleted. The only time one of these should be created, as of this writing, is when setting up a task's initial auto-tag. These cannot be removed from a task unless the task itself is deleted.

See L</delete>.

=head2 nickname

There are two kinds of tag relationships a tag may have with a task: nickname or topic. A nickname is a tag name that is used to refer to a specific task. A topic tag is just a way of categorizing a task. A given tag may only be used as a nickname once, but a given task may have multiple nicknames. A tag that is used as a nickname may also be used as a topic tag on other tasks.

=cut

use Qublog::Record schema {
    column task =>
        references Qublog::Model::Task,
        label is 'Task',
        is mandatory,
        is immutable,
        ;

    column tag =>
        references Qublog::Model::Tag,
        label is 'Tag',
        is mandatory,
        is immutable,
        is distinct,
        ;

    column sticky =>
        type is 'boolean',
        label is 'Sticky?',
        default is 0,
        is mandatory,
        is immutable,
        ;

    column nickname =>
        type is 'boolean',
        label is 'Nickname?',
        default is 0,
        is mandatory,
        is immutable,
        since '0.4.1',
        ;
};

=head1 METHODS

=head2 since

This was added with database versio 0.4.0.

=cut

sub since { '0.4.0' }

=head2 owner

This has the same owner as the task to which it belongs.

=cut

sub owner {
    shift->task->owner;
}

=head2 delete

  my $task_tag = Qublog::Model::TaskTag->new;
  $task_tag->load_by_cols( name => '1E5N' );
  $task_tag->delete;

  # OR
  
  $task-tag->delete( force => 1 );

Prevents deletion of sticky tag links unless force is present. The only time a sticky tag should be deleted is if the record to which it belongs is being deleted.

=cut

sub delete {
    my $self = shift;
    my %params = @_;

    die "Will not delete a sticky tag without being forced."
        if $self->sticky and not $params{force};

    return $self->SUPER::delete;
}

=head1 TRIGGERS

=head2 before_create

Fail if trying to create a nickname tag if that tag is already used as a nickname.

=cut

sub before_create {
    my ($self, $args) = @_;

    if ($args->{nickname} and $args->{tag}) {
        my $tag;
        if (ref $args->{tag}) {
            $tag = $args->{tag};
        }
        else {
            $tag = Qublog::Model::Tag->new;
            $tag->load($args->{tag});
            return '' if $tag->task;
        }
    }

    return 1;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut


1;

