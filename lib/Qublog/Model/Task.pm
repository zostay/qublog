use strict;
use warnings;

package Qublog::Model::Task;
use Jifty::DBI::Schema;

use DateTime::Span;
use Jifty::DateTime;
use Storable qw( dclone );

=head1 NAME

Qublog::Model::Task - record for tasks, projects, and groups

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

This is a task object. A task may have a parent task, a project (task object), and children. 

Each task has a type. The type is dependent on it's placement in the task tree. If a task is a leaf in the tree, it's type is "action". If a task has a parent and children, it is a "group". If it is a root node (whether it has children or not), it is a "project".

=head1 SCHEMA

=head2 name

This is a descriptive name for the task.

=head2 task_type

The task type field describes the type and is one of: project, group, or action.

=head2 child_handling

This field is not yet used, but will be used to determine whether a set of children should be treated as to be completed in a specific order or not.

=head2 status

This is the current status of the task. It has one of the three following values.

=over

=item open

This means the task is currently in need of work.

=item done

This task has been completed.

=item nix

This task has been canceled/deleted.

=back

=head2 created_on

This is the date the task was originally created.

=head2 completed_on

This is the date the task was last set to done status.

=head2 order_by

This field is not yet used, but will be used to order tasks relative to one another in the future.

=head2 project

This is the project to which this task belongs. This should be C<undef> if L</task_type> is set to "project" but always set otherwise.

=head2 parent

This is the parent task to which this task belongs. This should be C<undef> if L</task_type> is set to "project" but always set otherwise.

=head2 children

This is a L<Qublog::Model::TaskCollection> of entries that have this task set as L</parent>. This should be empty if the L</task_type> is "action".

=head2 journal_entries

This is a L<Qublog::Model::JournalEntryCollection> of entries that have this task set as the project for them.

=head2 task_logs

This is a L<Qublog::Model::TaskLogCollection> for the logs attached to this task.

=cut

use Qublog::Record schema {
    column name =>
        type is 'text',
        label is 'Name',
        is mandatory,
        is focus,
        ;

    column task_type =>
        type is 'text',
        label is 'Type',
        is mandatory,
        valid_values are qw/ project group action /,
        default is 'action',
        render as 'unrendered',
        ;

    column child_handling =>
        type is 'text',
        label is 'Child handling',
        is mandatory,
        valid_values are qw/ serial parallel /,
        default is 'serial',
        render as 'unrendered',
        ;

    column status =>
        type is 'text',
        label is 'Status',
        is mandatory,
        valid_values are [
            { display => 'Open', value => 'open' },
            { display => 'Done', value => 'done' },
            { display => 'Nix',  value => 'nix' },
        ],
        default is 'open',
        render as 'unrendered',
        ;

    column created_on =>
        type is 'datetime',
        label is 'Created on',
        filters are qw/ Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime /,
        render as 'unrendered',
        ;

    column completed_on =>
        type is 'datetime',
        label is 'Completed on',
        filters are qw/ Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime /,
        render as 'unrendered',
        since '0.1.1',
        ;

    column order_by =>
        type is 'int',
        label is 'Order by',
        is mandatory,
        default is 0,
        render as 'unrendered',
        ;

    column project =>
        references Qublog::Model::Task,
        label is 'Project',
        ;

    column parent =>
        references Qublog::Model::Task,
        label is 'Group',
        ;

    column children =>
        references Qublog::Model::TaskCollection by 'parent',
        ;

    column journal_entries =>
        references Qublog::Model::JournalEntryCollection by 'project',
        ;

    column task_logs =>
        references Qublog::Model::TaskLogCollection by 'task';

    column task_tags =>
        references Qublog::Model::TaskTagCollection by 'task';

};

=head1 METHODS

=head2 since

This has been part of the application since database version 0.1.0.

=cut

sub since { '0.1.0' }

=head2 project_none

This is a class method that returns a task object that represents the special "none" task which is treated as a general kind of inbox for tasks.

If no such task currently exists, the project node will be created automatically.

=cut

sub project_none {
    my $name = Jifty->config->app('none_project_name');

    my $task = Qublog::Model::Task->new;
    $task->load_by_cols( name => $name, status => 'open' );

    return $task if $task->id;

    $task->create( name => $name, project => 0 );

    return $task;
}

=head2 comments

This returns the comments that have been associated with this task. These are tasks that have been linked via the L<Qublog::Model::TaskLog> model.

=cut

sub comments {
    my $self = shift;

    my $comments = Qublog::Model::CommentCollection->new;
    my $log_table = $comments->join(
        column1 => 'id',
        table2  => Qublog::Model::TaskLog->table,
        column2 => 'comment',
    );
    $comments->limit(
        alias  => $log_table,
        column => 'task',
        value  => $self->id,
    );

    return $comments;
}

=head2 is_none_project

This method returns true if this task represents the special none project inbox.

=cut

sub is_none_project {
    my $self = shift;

    my $none_project_name = Jifty->config->app('none_project_name');
    return '' unless $self->name eq $none_project_name;
    return '' unless $self->task_type eq 'project';

    # A task with this name and type with a lower ID, is the none project!
    my $tasks = Qublog::Model::TaskCollection->new;
    $tasks->limit( column => 'task_type', value => 'project' );
    $tasks->limit( column => 'status', value => 'open' );
    $tasks->limit( column => 'id', operator => '<', value => $self->id );
    return '' unless $tasks->count == 0;

    return 1;
}

=head2 begin_update LOG

This is used by L<Qublog::Action::UpdateTask>. This allows a series of changes to a task to be grouped on a single L<Qublog::Model::TaskLog> object.

=cut

sub begin_update {
    my ($self, $group_log) = @_;

    push @{ $self->{__group} }, $group_log;

    return $group_log;
}

=head2 group_update_log

Returns the L<Qublog::Model::TaskLog> object that changes being made should be associated with. This returns C<undef> if no such object exists at this time.

=cut

sub group_update_log {
    my $self = shift;
    $self->{__group} ||= [];

    return scalar @{ $self->{__group} } > 0 ? $self->{__group}[0]
         :                                    undef;
}

=head2 end_update

This is called at the end of L<Qublog::Action::UpdateTask> to note that the task log is no longer being added to.

=cut

sub end_update {
    my $self = shift;

    pop @{ $self->{__group} };
}

=head2 tags

This returns a list of tag names (strings) that have been assigned to the current object. Returns an empty list if the current object does not have an ID (i.e., is not loaded).

=cut

sub tags {
    my $self = shift;
    return () unless $self->id;

    my $task_tags = $self->task_tags;
    $task_tags->order_by({
        column => 'id',
        order  => 'DES',
    });
    return map { $_->tag->name } @{ $task_tags->items_array_ref };
}

=head2 tag

This returns the most recently added tag name for the current object. Returns C<undef> if the current object does not have an ID.

=cut

sub tag {
    my $self = shift;
    my @tags = $self->tags;

    # The very first tag in this list should be the current one
    return scalar $tags[0];
}

=head2 autotag

This returns the original sticky tag name for the current object. Returns C<undef> if the current object does not have an ID (i.e., is not loaded).

=cut

sub autotag {
    my $self = shift;
    my @tags = $self->tags;

    # The very last tag in this list should be the auto tag
    return scalar $tags[-1];
}

=head2 add_tag

Adds a new tag to the current object. If the tag is already taken or is not made up of only letters and numbers, this method will fail with an exception.

=cut

sub add_tag {
    my ($self, $tag_name) = @_;

    # Find or load the tag
    my $tag = Qublog::Model::Tag->new;
    $tag->load_or_create(
        name => $tag_name,
    );

    # See if such a task tag exists already and clear it first
    my $task_tag = Qublog::Model::TaskTag->new;
    $task_tag->load_by_cols( tag => $tag, nickname => 1 );
    $task_tag->delete if $task_tag->id;

    # Now create a new one that links here
    $task_tag->create(
        task     => $self,
        tag      => $tag,
        nickname => 1,
    );

    return $tag;
}

=head2 remove_tag

Removes a tag from the current object. If the tag is sticky, this will fail with an exception.

=cut

sub remove_tag {
    my ($self, $tag_name) = @_;

    my $task_tags = $self->task_tags;
    my $tag_table = $task_tags->join(
        column1 => 'tag',
        table2  => Qublog::Model::Tag->table,
        column2 => 'id',
    );
    $task_tags->limit(
        alias  => $tag_table,
        column => 'name',
        value  => $tag_name,
    );
    my $tag = $task_tags->first;
    $tag->delete if $tag->id;
}

=head2 load_by_tag_name

=head2 load_by_nickname

Loads the task that has the given nickname.

=cut

sub load_by_tag_name {
    my ($self, $tag_name) = @_;
    my $tasks = Qublog::Model::TaskCollection->new;
    my $task_tag_table = $tasks->join(
        column1 => 'id',
        table2  => Qublog::Model::TaskTag->table,
        column2 => 'task',
    );
    $tasks->limit(
        alias  => $task_tag_table,
        column => 'nickname',
        value  => 1,
    );
    my $task_table = $tasks->join(
        alias1  => $task_tag_table,
        column1 => 'tag',
        table2  => Qublog::Model::Tag->table,
        column2 => 'id',
    );
    $tasks->limit(
        alias  => $task_table,
        column => 'name',
        value  => $tag_name,
    );

    my $task = $tasks->first;
    if ($task and $task->id) {
        return $self->load($task->id);
    }
    else {
        return (0, "Could not find a task for the requested nickname");
    }
}

*load_by_nickname = *load_by_tag_name;

=head2 historical_values

Given a L<DateTime> object, this returns a hash reference containing the values each field would have had as of that date. If the task had not yet been created yet, C<undef> is returned instead of the hash.

If no L<DateTime> object is given, then the history of the object is returned. This will be a reference to an array of hashes. Each hash will also have an additional key named "span" which will be set to a L<DateTime::Span> representing the start and stop of each. The "span" of the final entry in the returned array (the latest entry) will have no end date and represent the current values.

=cut

sub historical_values {
    my ($self, $date) = @_;
    my $task_logs = $self->task_logs;

    if ($date) {
        my $utc_date = $date->clone;
        $utc_date->set_time_zone('UTC');

        $task_logs->limit( 
            column   => 'created_on',
            operator => '>',
            value    => $utc_date->format_cldr('YYYY-MM-dd HH:mm:ss'),
            entry_aggregator => 'AND',
        );
        $task_logs->order_by({ column => 'created_on', order => 'DES' });

        my $record = { $self->as_hash };
        while (my $task_log = $task_logs->next) {
            my $task_changes = $task_log->task_changes;
            while (my $task_change = $task_changes->next) {
                $record->{ $task_change->name } = $task_change->old_value;
            }
        }

        return $record;
    }

    else {
        my @records;
        $task_logs->order_by({ column => 'created_on', order => 'DES' });

        my $end_date = undef;
        my $record   = { $self->as_hash };

        push @records, $record;
        while (my $task_log = $task_logs->next) {
            $records[-1]{span} = DateTime::Span->new(
                start => $task_log->created_on,
                (defined $end_date ? (before => $end_date) : ()),
            );

            # Join spans if a task log has not changes
            my $task_changes = $task_log->task_changes;
            next unless $task_changes->count > 0;

            $end_date = $task_log->created_on;
            $record = dclone($record);
            
            while (my $task_change = $task_changes->next) {
                $record->{ $task_change->name } = $task_change->old_value;
            }

            push @records, $record;
        }

        $records[-1]{span} = DateTime::Span->new(
            start => $self->created_on,
            (defined $end_date ? (before => $end_date) : ()),
        );

        return [ reverse @records ];
    }
}

=head1 TRIGGERS

=head2 before_create

This makes sure the L</parent> and L</project> fields are set correctly. It initializes the L</created_on> field to right now. It sets L</completd_on> to now if the L</status> of the new task is already set to "done". It will make sure the L</task_type> is set correctly as well.

=cut

sub before_create {
    my ($self, $args) = @_;

    # Are we creating the none project? Deal with it specially
    if ($args->{name} eq Jifty->config->app('none_project_name')) {
        delete $args->{parent};
        delete $args->{project};

        $args->{created_on} = Jifty::DateTime->now;
        $args->{task_type}  = 'project';

        return 1;
    }

    # Did they specify a parent task?
    if ($args->{parent}) {

        # Load the task object if we need to
        my $parent;
        if (ref $args->{parent}) {
            $parent = $args->{parent};
        }
        else {
            $parent = Qublog::Model::Task->new;
            $parent->load( $args->{parent} );
        }

        # If the parent object is a project, set the project to that too
        if ($parent->task_type eq 'project') {
            $args->{project} = $parent;
        }

        # Otherwise, set the project to the project that the parent belongs to
        else {
            $args->{project} = $parent->project;
        }
    }

    # No parent, but project is given, so use that as the parent too
    elsif ($args->{project}) {
        $args->{parent} = $args->{project};
    }

    # No parent or project, so set both to "none"
    else {
        $args->{parent} = $args->{project} = $self->project_none;
    }

    $args->{created_on}   = Jifty::DateTime->now;
    $args->{completed_on} = Jifty::DateTime->now 
        if defined $args->{status} and $args->{status} eq 'done';
    $args->{task_type}    = 'action';

    return 1;
}

=head2 after_create

Changes the L</task_type> of a parent to "group" if not already set as such. This also creates the creation log message.

=cut

sub after_create {
    my ($self, $result) = @_;

    # Load the newly created task if there is one
    return unless $$result;
    $self->load($$result);

    # Make the parent a group if it isn't already
    if ($self->parent->id and $self->parent->task_type eq 'action') {
        $self->parent->set_task_type('group');
    }

    # Remember the creation of the object as a create log
    my $task_log = Qublog::Model::TaskLog->new;
    $task_log->create(
        task     => $self,
        log_type => 'create',
    );

    # Create the tag
    my $tag = Qublog::Model::Tag->new;
    $tag->create( name => '-' ); # name = "-" -> make an auto-tag
    
    # Now add the task tag link
    my $task_tag = Qublog::Model::TaskTag->new;
    $task_tag->create(
        task   => $self,
        tag    => $tag,
        sticky => 1,
    );

    # Make sure loading continues
    return 1;
}

=head2 before_set_project

Prevents the project from being set.

=cut

sub before_set_project {
    die "Cannot set project. Please set group instead.";
}

=head2 before_set_parent

Prevents a task parent relationship from creating a loop. Remembers the original parent value.

=cut

sub before_set_parent {
    my ($self, $args) = @_;

    my $new_parent = $args->{value};
    unless (ref $new_parent) {
        $new_parent = Qublog::Model::Task->new;
        $new_parent->load($args->{value});
    }

    while ($new_parent and $new_parent->id) {
        if ($new_parent->id == $self->id) {
            die "You cannot make a task an ancestor of itself. The space-time continuum won't tolerate it.\n";
        }
    } 
    continue { $new_parent = $new_parent->parent }

    $self->{__before_set_parent}{original_parent} 
        = $self->parent if $self->parent->id;

    #$self->log->error("SETTING PARENT of ".$self->id." to ".$args->{value}.($original_parent->id ? " from ".$original_parent->id : ''));

    return 1;
}

=head2 after_set_parent

Makes sure to update the original and new task parents to have the appropriate information after having this task removed/added as a child.

=cut

sub after_set_parent {
    my ($self, $args) = @_;

    #$self->log->error("original value ".$original_parent->id." is intact") if $original_parent;

    my $original_parent = delete $self->{__before_set}{original_parent};
    if ($original_parent
            and $original_parent->task_type ne 'project'
            and $original_parent->children->count == 0) {

        $original_parent->set_task_type('action');
    }

    if ($self->parent->id
            and $self->parent->task_type eq 'action') {

        $self->parent->set_task_type('group');
    }

    if ($self->parent->id) {
        if ($self->children->count > 0) {
            $self->set_task_type('group');
        }

        else {
            $self->set_task_type('action');
        }

        if ($self->parent->task_type eq 'project') {
            $self->__set( column => 'project', value => $self->parent->id );
        }
        
        else {
            $self->__set( column => 'project', value => $self->parent->project->id );
        }
    }

    else {
        $self->set_task_type('project');
        $self->__set( column => 'project', value => undef);
    }

    return 1;
}

=head2 after_set_status

If the status is set to done, this sets the L</completed_on> timestamp to right now.

=cut

sub after_set_status {
    my ($self, $args) = @_;

    if ($args->{value} eq 'done') {
        $self->set_completed_on(Jifty::DateTime->now);
    }

    return 1;
}

=head2 before_set

This remembers the old value for logging.

=cut

sub before_set {
    my ($self, $args) = @_;

    # FIXME There seems to be a bug in Jifty resulting in this being called
    # with incorrect parameters.
    return 1 unless defined $args->{column};

    my $column = $args->{column};
    $self->{__before_set}{old_value} = $self->$column();

    return 1;
}

=head2 after_set

This logs the change with a L<Qublog::Model::TaskLog> and L<Qublog::Model::TaskChange> object so that the history of a task can be tracked.

=cut

sub after_set {
    my ($self, $args) = @_;

    my $task_log = $self->group_update_log;

    my $label = $self->column($args->{column})->label;

    if (not defined $task_log) {
        $task_log = Qublog::Model::TaskLog->new;
        $task_log->create(
            task     => $self,
            log_type => 'update',
        );
    }

    my $task_change = Qublog::Model::TaskChange->new;
    $task_change->create(
        task_log  => $task_log,
        name      => $args->{column},
        old_value => delete $self->{__before_set}{old_value},
        new_value => $args->{value},
    );

    return 1;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
