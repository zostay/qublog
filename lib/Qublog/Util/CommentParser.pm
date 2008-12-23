use strict;
use warnings;

package Qublog::Util::CommentParser;

use List::Util qw/ min /;
use Moose;

=head1 NAME

Qublog::Util::CommentParser - parses a bit of text and manipulates tasks

=head1 SYNOPSIS

  use Qublog::Util::CommentParser;

  # Setup a nice long comment.
  $comment = <<'END_OF_COMMENT';
  Some regular text in the comment. This /is/ generally *formatted* using 
  Markdown.

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
  END_OF_COMMENT

  # Get a comment object
  my $comment_record = Qublog::Model::Comment->new;
  # Load or create a $comment_record ...

  # Build a parser object
  my $parser = Qublog::Util::CommentParser->new(
      project => $default_project,
      text    => $comment,
      comment => $comment_record,
  );

  # Execution Path A: "Execute" the comment to build tasks and such
  $parser->execute;

  # Only the parts needed to reference the tasks remain in the comment
  my $new_comment = $parser->comment;

  # Execution Path B: "Transform" the comment into pretty HTML
  $parser->htmlify;

  # This text has tag references transformed into HTML
  my $htmlified = $parser->htmlify;

=head1 DESCRIPTION

This class encapsulates the comment parser. This parser takes a string of text and tries to find references to tags or task nicknames and requests to create and update tasks within the string. It then rewrites the string as appropriate for running through L</htmlify>.

This class is built using L<Moose>, so you can construct it by passing the attributes as a hash to the C<new> constructor.

=head1 ATTRIBUTES

=head2 project

This is a L<Qublog::Model::Task> object to use as the project when creating a new task.

=cut

has project => (
    is => 'rw',
    isa => 'Qublog::Model::Task',
);

=head2 text

B<Required>. This is the text of the comment to parse.

=cut

has text => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

=head2 comment

B<Required>. This is the L<Qublog::Model::Comment> class to task log objects should be attached to.

=cut

has comment => (
    is => 'rw',
    isa => 'Qublog::Model::Comment',
    required => 1,
);

=head2 tasks

After calling L</execute>, this will return an array of L<Qublog::Model::Task> objects from all of the above lists of tasks, in no particular order.

=cut

sub tasks {
    my $self = shift;

    # Okay, so it is a particular order, but this isn't guaranteed to remain the same!
    return ($self->created_tasks, $self->updated_tasks, $self->linked_tasks);
}

=head1 METHODS

=head2 execute

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

As the comment is parsed, it is also rewritten in a form suitable for use with L</htmlify>. All of the creates and updates are just included as references to the ticket number.

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

    return (
        scalar(@$parent_stack) > 0 ? ($parent_stack->[0]) : (undef), 
        $new_depth
    );
}

sub _eval_tag_name {
    my ($self, $tag) = @_;

    my $task = Qublog::Model::Task->new;
    $task->load_by_tag_name($tag);

    my $task_log = Qublog::Model::TaskLog->new;
    $task_log->create(
        task     => $task,
        log_type => 'note',
        comment  => $self->comment,
    );

    return '#' . $tag . '*' . $task_log->id;
}

sub execute {
    my $self = shift;
    
    my $original_comment = $self->text;
    open my $commentfh, '<', \$original_comment;

    my $new_comment  = '';
    my @parent_stack;

    LINE: 
    while (<$commentfh>) {
        SWITCH: {
            m{^  
                  (-*)             \s*        # Nesting depth
              \[  ([\ !x-]) \]     \s*        # Task status
              (?: (\+?\#\w+):?     \s*        # Load/create nick
              (?: (\#\w+)(:) )? )? \s*        # Rename the nick to
                  (.*)                      # Name of task
            $}x && do {
                chomp;

                my $depth       = $1;
                my $status      = lc $2;
                my $nick        = $3;
                my $new_nick    = $4;
                my $extra_colon = $5;
                my $description = $6;

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
                    $task->load_by_tag_name($nick);
                    $found_task = $task->id;
                }

                # Forget the new name on a create
                if (!$found_task) {
                    if ($new_nick && length $new_nick > 0) {
                        $description = '#' . $new_nick . $extra_colon 
                                     . ' ' . $description;
                    }
                    $new_nick = $nick;
                }

                # Figure out who the parent should be
                my $parent;
                ($parent, $depth) = _decide_parent(@parent_stack, $depth);

                # TODO warning on bad status
                $status = $status eq '-' ? undef
                        : $status eq ' ' ? 'open'
                        : $status eq 'x' ? 'done'
                        : $status eq '!' ? 'nix'
                        :                  undef
                        ;

                my %arguments = (
                    parent   => $parent,
                    tag_name => $new_nick,
                    name     => $description,
                    status   => $status,
                );

                FIELD:
                for my $field (keys %arguments) {
                    if (not defined $arguments{ $field }) {
                        delete $arguments{ $field };
                        next FIELD;
                    }

                    # String things must have at least one char
                    delete $arguments{ $field }
                        if grep { $field eq $_ } qw( tag_name name status )
                       and $arguments{ $field } !~ /\S/;
                }

                $task = $self->_create_task($task, \%arguments);

                my $task_log;
                if ($found_task) {
                    # Find the latest task log (just created) and link to it
                    my $task_logs = $task->task_logs;
                    $task_logs->limit( 
                        column => 'log_type', 
                        value  => 'update',
                    );
                    $task_logs->order_by({ 
                        column => 'created_on', 
                        order  => 'des',
                    }, {
                        column => 'id',
                        order  => 'des',
                    });
                    $task_log = $task_logs->first;
                    $task_log->set_comment( $self->comment );
                }
                else {
                    # Find the latest task log (just created) and link to it
                    my $task_logs = $task->task_logs;
                    $task_logs->limit( 
                        column => 'log_type', 
                        value  => 'create',
                    );
                    $task_logs->order_by({ 
                        column => 'created_on', 
                        order  => 'des',
                    }, {
                        column => 'id',
                        order  => 'des',
                    });
                    $task_log = $task_logs->first;
                    $task_log->set_comment( $self->comment );
                }

                unshift @parent_stack, $task;

                $_ = ("  " x $depth) . ' * #' . $task->tag 
                   . "*" . $task_log->id . "\n";
                last SWITCH;
            };

            # If this doesn't include a [*] line, clear the @parent_stack
            @parent_stack = (); 

            m{#\w+} && do {
                s/#(\w+)/$self->_eval_tag_name($1)/ge;
                last SWITCH;
            };
        }

        $new_comment .= $_;
    }

    $self->text($new_comment);
}

=head2 htmlify

This turns all task references into HTML links. We decorate these links so that they show the status that that item held immediately after the comment was executed.

=cut

sub _replace_task_nicknames {
    my ($nickname, $task_log_id) = @_;

    my $log = Qublog::Model::TaskLog->new;
    $log->load($task_log_id) if $task_log_id;

    my $task = Qublog::Model::Task->new;
    $task->load_by_tag_name($nickname);

    my $old_task = $task->historical_values($log->created_on);

    my $action = join ' ', 'task-reference', ($log->log_type || '');
    my $status = join ' ', ($old_task->{task_type} || ''), 
                           ($old_task->{status}    || '');

    return '#'.$nickname unless $task->id;

    my $url  = Jifty->web->url(path => '/project').'#'.$task->tag;
    my $name = $task->name;
    return qq{<span class="$action">}
          .qq{<a href="$url" class="$status">#$nickname: $name</a></span>};
}

sub htmlify {
    my $self = shift;
    my $text = $self->text;

    $text =~ s/#(\w+)(?:\*(\d+))?/_replace_task_nicknames($1, $2)/ge;

    $self->text($text);
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
