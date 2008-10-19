use strict;
use warnings;

package Qublog::Util::CommentParser;

use List::Util qw/ min /;
use Moose;

=head1 NAME

Qublog::Util::CommentParser - parses a bit of text and manipulates tasks

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

This class encapsulates a very simple (i.e., not very smart) parser. This parser takes a string of text and tries to find references to tasks and requests to create and update tasks within the string. It then rewrites the string as appropriate for running through L<Qublog::Web/htmlify> and sets up some information about the tasks that have been manipulated.

Each instance of this class should be used to parse one pieces of text and then discarded.

This class is built using L<Moose>, so you can construct it by passing the attributes as a hash to the C<new> constructor.

=head1 ATTRIBUTES

=head2 project

This is a L<Qublog::Model::Task> object to use as the project when creating a new task.

=cut

has project => (
    is => 'rw',
    isa => 'Qublog::Model::Task',
);

=head2 comment

B<Required>. This is the text of the comment to parse.

=cut

has comment => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

=head2 created_tasks

After calling L</parse>, this will return an array of L<Qublog::Model::Task> objects that have just been created.

=cut

has created_tasks => (
    is => 'rw',
    isa => 'ArrayRef[Qublog::Model::Task]',
    auto_deref => 1,
);

=head2 updated_tasks

After calling L</parse>, this will return an array of L<Qublog::Model::Task> objects that have just been updated.

=cut

has updated_tasks => (
    is => 'rw',
    isa => 'ArrayRef[Qublog::Model::Task]',
    auto_deref => 1,
);

=head2 linked_tasks

After calling L</parse>, this will return an array of L<Qublog::Model::Task> objects that were referenced in the task.

=cut

has linked_tasks => (
    is => 'rw',
    isa => 'ArrayRef[Qublog::Model::Task]',
    auto_deref => 1,
);

=head2 tasks

After calling L</parse>, this will return an array of L<Qublog::Model::Task> objects from all of the above lists of tasks, in no particular order.

=cut

sub tasks {
    my $self = shift;

    # Okay, so it is a particular order, but this isn't guaranteed to remain the same!
    return ($self->created_tasks, $self->updated_tasks, $self->linked_tasks);
}

=head1 METHODS

=head2 parse

This performs all the interesting work in this class. This will look for strings like:

 [ ] Task 1
 -[ ] Task 2
 --[ ] Task 3

 [x] Task 4
 [!] Task 5
 [-] Task 6
 
 [x] #1J3G
 [-] #NG54: Task 7
 [-] #4FFT: #foo: Task 8

 #R441: I did some interesting stuff.

In the lines above containing "Task 1" through "Task 3", the parser will create three new tasks with the given descriptions ("Task 1", "Task 2", and "Task 3", respectively). They will also be created such that "Task 1" is the parent of "Task 2" and that "Task 2" is the parent of "Task 1". These tasks will be created with a status of "open".

In the lines labeled "Task 4" through "Task 6", the parser will create three new tasks. "Task 4" will be created already marked "done". "Task 5" will be created deleted. "Task 6" will be created as open. The "-" is synonymous with space (" ") on create.

In the line labeled "#1J3G", the task referenced by nickname "1J3G" will be marked as done, signified by the "x". Similarly, a "!" would mark the task as deleted (or "nix"), a space (" ") would mark the task as "open" and the "-" performs a no-op, leaving the status unchanged.

In the line labeled "#NG54", the status is unchanged, but the task title is changed to "Task 7".

In the line labeled "#4FFT", the status is unchanged, but the task nickname is changed to "foo" and the titled is changed to "Task 8".

In the line labeled "#R441", a from that other task to this comment should be created.

As the comment is parsed, it is also rewritten in a form suitable for use with L<Qublog::Web/htmlify>. All of the creates and updates are just included as references to the ticket number.

=cut

sub _create_task {
    my ($self, $record, $arguments) = @_;
    my $task_action;

    # The parser thinks it already exists, so updated it
    if ($record->id) {
        $task_action = Jifty->web->new_action(
            class     => 'UpdateTask',
            record    => $record,
            arguments => $arguments,
        );
    }

    # The parser does not think it exists yet, create it
    else {
        $arguments->{project} = $self->project;

        $task_action = Jifty->web->new_action(
            class     => 'CreateTask',
            arguments => $arguments,
        );
    }

    # Do it
    $task_action->take_action;

    return $task_action->record;
}

sub _decide_parent(\@$) {
    my ($parent_stack, $depth) = @_;

    # Use min() in case they used too many dashes
    # FIXME This is probably not quite DWIMming
    my @depth_matches = $depth =~ /-/g;
    my $new_depth = min(
        scalar (@depth_matches) + 1, 
        scalar (@$parent_stack) + 3,
    );

    # Current depth
    my $old_depth = scalar(@$parent_stack);

    SWITCH: {
        $new_depth  > $old_depth && do { last SWITCH };
        $new_depth == $old_depth && do { shift @$parent_stack; last SWITCH };
        DEFAULT: do { splice @$parent_stack, 0, $old_depth - $new_depth + 1 };
    }

    return scalar(@$parent_stack) > 0 ? ($parent_stack->[0]) : (undef);
}

sub parse {
    my $self = shift;
    
    my $original_comment = $self->comment;
    open my $commentfh, '<', \$original_comment;

    my $new_comment  = '';
    my @parent_stack;
    my (@created_tasks, @updated_tasks, @linked_tasks);

    LINE: 
    while (<$commentfh>) {
        SWITCH: {
            m{^  
                  (-*)           \s*        # Nesting depth
              \[  ([\ !x-]) \]   \s*        # Task status
              (?: (\+?\#\w+):?   \s*        # Load/create nick
              (?: (\#\w+): )? )? \s*        # Rename the nick to
                  (.*)                      # Name of task
            $}x && do {
                chomp;

                my $depth       = $1;
                my $status      = lc $2;
                my $nick        = $3;
                my $new_nick    = $4;
                my $description = $5;

                # Strip trailing space from the description
                $description =~ s/\s+$//;

                # Force new even if there may be a matching nick
                my $force_new = '';
                $force_new = 1 if defined $nick and $nick =~ s/^\+//;

                # Strip off the # if there
                for ($nick, $new_nick) { s/^\#// if $_ and length $_ > 0 }

                # Load the existing task if we can
                my $found_task;
                my $task = Qublog::Model::Task->new;
                if (not $force_new and defined $nick and (length $nick > 1)) {
                    $task->load_by_nickname($nick);
                    $found_task = $task->id;
                }

                # Forget the new name on a create
                if (!$found_task) {
                    if ($new_nick && length $new_nick > 0) {
                        $description .= $new_nick . ' ' . $description;
                    }
                    $new_nick = $nick;
                }

                # Figure out who the parent should be
                my $parent = _decide_parent(@parent_stack, $depth);

                # TODO warning on bad status
                $status = $status eq '-' ? undef
                        : $status eq ' ' ? 'open'
                        : $status eq 'x' ? 'done'
                        : $status eq '!' ? 'nix'
                        :                  undef
                        ;

                my %arguments = (
                    parent             => $parent,
                    alternate_nickname => $new_nick,
                    name               => $description,
                    status             => $status,
                );

                FIELD:
                for my $field (keys %arguments) {
                    if (not defined $arguments{ $field }) {
                        delete $arguments{ $field };
                        next FIELD;
                    }

                    # String things must have at least one char
                    delete $arguments{ $field }
                        if grep { $field eq $_ } qw( alternate_nickname name status )
                       and $arguments{ $field } !~ /\S/;
                }

                $task = $self->_create_task($task, \%arguments);

                if ($found_task) {
                    push @updated_tasks, $task;
                }
                else {
                    push @created_tasks, $task;
                }

                unshift @parent_stack, $task;

                $_ = '#'.$task->nickname."  \n";
                last SWITCH;
            };

            # If this doesn't include a [*] line, clear the @parent_stack
            @parent_stack = (); 

            m{#\w+} && do {
                my @nicknames = m{#(\w+)};

                for my $nickname (@nicknames) {
                    my $task = Qublog::Model::Task->new;
                    $task->load_by_nickname($nickname);

                    push @linked_tasks, $task if $task->id;
                }
            };
        }

        $new_comment .= $_;
    }

    $self->comment($new_comment);

    $self->created_tasks(\@created_tasks);
    $self->updated_tasks(\@updated_tasks);
    $self->linked_tasks(\@linked_tasks);
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
