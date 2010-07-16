package Qublog::Schema::Result::Task;
use Moose;
extends qw( Qublog::Schema::Result );

with qw( Qublog::Schema::Role::Itemized );

use Moose::Util::TypeConstraints;

enum 'Qublog::Schema::Result::Task::Status' => qw( open done nix );
enum 'Qublog::Schema::Result::Task::ChildHandling' => qw( serial parallel );
enum 'Qublog::Schema::Result::Task::Type' => qw( project group action );

no Moose::Util::TypeConstraints;

# TODO This is duplicated in Qublog::Schema::ResultSet::Task and should be
# configuration
use constant NONE_PROJECT_NAME => 'none';

=head1 NAME

Qublog::Schema::Result::Task - tasks go here

=head1 DESCRIPTION

=head1 TYPE

=head2 Qublog::Schema::Result::Task::Status

An enumeration of values: C<open>, C<done>, and C<nix>.

=head2 Qublog::Schema::Result::Task::ChildHandling

An enumeration of values: C<serial> and C<parallel>.

=head2 Qublog::Schema::Result::Task::Type

An enumeration of values: C<project>, C<group>, and C<action>.

=head1 SCHEMA

=head2 id

The autogenerated ID column.

=head2 name

The task name.

=head2 owner

The L<Qublog::Schema::Result::User> that created this task.

=head2 task_type

The type of task. This is a L</Qublog::Schema::Result::Task::TaskType>.

=head2 child_handling

Whether child tasks are sequentially ordered or parallel in nature. This is a L</Qublog::Schema::Result::Task::ChildHandling>.

=head2 status

The current status of the task. This is a L</Qublog::Schema::Result::Task::Status>.

=haed2 created_on

The L<DateTime> on which the task was created.

=head2 completed_on

The L<DateTime> on which the task was last marked C<done>.

=head2 order_by

An integer that should be used to order sibling tasks with respect to each other.

=head2 project

The project this task belongs to or C<undef> if this is a project.

=head2 parent

The parent of this task or C<undef> if this is a project.

=head2 latest_comment

A link to the most recent L<Qublog::Schema::Result::Comment> for this task.

=head2 children

A result set of the L<Qublog::Schema::Result::Task> objects that have this one set as its L</parent>.

=head2 journal_entries

A result set of the L<Qublog::Schema::Result::JournalEntry> objects that use this its project.

=head2 task_logs

A result set of L<Qublog::Schema::Result::TaskLog> objects that link to this task.

=head2 comments

A result set of L<Qublog::Schema::Result::Comment> objects that discuss this task.

=head2 tags

A result set of L<Qublog::Schema::Result::Tag> objects that tag this task.

=head2 task_tags

A result set of L<Qublog::Schema::Result::TaskTag> objects that link to this task.

=cut

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('tasks');
__PACKAGE__->add_columns(
    id             => { data_type => 'int' },
    name           => { data_type => 'text' },
    owner          => { data_type => 'int' },
    task_type      => { data_type => 'text' },
    child_handling => { data_type => 'text' },
    status         => { data_type => 'text' },
    created_on     => { data_type => 'datetime', timezone => 'UTC' },
    completed_on   => { data_type => 'datetime', timezone => 'UTC' },
    order_by       => { data_type => 'int' },
    project        => { data_type => 'int' },
    parent         => { data_type => 'int' },
    latest_comment => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( owner => 'Qublog::Schema::Result::User' );
__PACKAGE__->belongs_to( project => 'Qublog::Schema::Result::Task' );
__PACKAGE__->belongs_to( parent => 'Qublog::Schema::Result::Task' );
__PACKAGE__->has_many( children => 'Qublog::Schema::Result::Task', 'parent' );
__PACKAGE__->has_many( journal_entries => 'Qublog::Schema::Result::JournalEntry', 'project' );
__PACKAGE__->has_many( task_logs => 'Qublog::Schema::Result::TaskLog', 'task' );
__PACKAGE__->has_many( task_tags => 'Qublog::Schema::Result::TaskTag', 'task', { order_by => { -desc => 'me.id' } });
__PACKAGE__->many_to_many( tags => task_tags => 'tag' );
__PACKAGE__->many_to_many( comments => task_logs => 'comment' );
__PACKAGE__->resultset_class('Qublog::Schema::ResultSet::Task');

=head1 METHODS

=head2 new

Sets defaults for new tasks.

=cut

sub new {
    my ($class, $args) = @_;

    $args->{task_type}      = 'action' unless defined $args->{task_type};
    $args->{child_handling} = 'serial' unless defined $args->{child_handler};
    $args->{status}         = 'open'   unless defined $args->{status};
    $args->{created_on}     = Qublog::DateTime->now
                                       unless defined $args->{created_on};
    $args->{order_by}       = 0        unless defined $args->{order_by};

    if ($task_type eq 'project') {
        my $none = $self->result_source->resultset->project_none;

        $args->{project} = $none;
    }

    my $self = $class->next::method($args);

    if ($task_type eq 'project') {
        $self->project($self);
    }

    elsif (not $self->project and not $self->parent) {
        my $none = $self->result_source->resultset->project_none;

        $self->project($none);
        $self->parent($none);
    }

    elsif (not $self->project) {
        $self->project( $self->parent->project );
    }

    elsif (not $self->parent) {
        $self->parent( $self->project );
    }

    return $self;
}

=head2 add_tag

  $task->add_tag('Foo');

Tags this task with the given tag name.

=cut

sub add_tag {
    my ($self, $tag_name) = @_;

    # Find or load the tag
    my $tag = $self->result_source->schema->resultset('Tag')->find_or_create({
        name => $tag_name,
    });
    
    $self->create_related( task_tags => {
        tag      => $tag,
        nickname => 1,
    });
    
    return $tag;
}

=head2 has_tag

  if ($task->has_tag('Foo')) {
      # do something
  }

Checks to see if this task is tagged with the given tag name.

=cut

sub has_tag {
    my ($self, $name) = @_;
    return $self->tags({ name => $name })->count > 0;
}

=head2 tag

Returns the most recently assigned tag name.

=cut

sub tag {
    my $self = shift;
    my $tag = $self->tags({}, { 
        rows     => 1, 
        order_by => { -desc => 'tag.id' }, 
    })->single;
    return $tag->name if $tag;
    die "no tag found for task";
}

=head2 autotag

Returns the very first assigned tag name, which is the automatically assigned tag name.

=cut

sub autotag {
    my $self = shift;
    my $tag = $self->tags({}, { 
        rows     => 1, 
        order_by => { -asc => 'tag.id' }, 
    })->single;
    return $tag->name if $tag;
    die "no tag found for task";
}

=head2 insert

Hooked to automatically create the L</autotag> and the first L<Qublog::Schema::Result::TaskLog>.

=cut

sub insert {
    my ($self, @args) = @_;
    $self->next::method(@args);
    $self->task_logs->new({})->fill_related_to(insert => $self)->insert;
    my $autotag = $self->result_source->schema->resultset('Tag')->create({
        autotag => 1,

    });
    $self->create_related(task_tags => { 
        tag      => $autotag,
        sticky   => 1,
        nickname => 1,
    });
    return $self;
}

=head2 update

Hooked to automatically create a L<Qublog::Schema::Result::TaskLog> recording the modification.

=cut

sub update {
    my ($self, @args) = @_;
    $self->next::method(@args);
    $self->task_logs->new({})->fill_related_to(update => $self)->insert;
    return $self;
}

=head2 latest_task_log

The most recent L<Qublog::Schema::Result::TaskLog> object.

=cut

sub latest_task_log {
    my $self = shift;
    return $self->task_logs({}, { 
        order_by => { -desc => [ 'created_on', 'id' ] }, 
        rows     => 1,
    })->single;
}

=head2 as_journal_item

No op. See L<Qublog::Schema::Role::Itemized>.

=cut

sub as_journal_item {}

=head2 list_journal_item_resultsets

Returns a result set of comments associated with this task.

See L<Qublog::Schema::Role::Itemized>.

=cut

sub list_journal_item_resultsets {
    my ($self, $options) = @_;
    my $comments = $self->comments;
    return [ $comments ];
}

=head2 is_none_project

Returns true if this task represents the special "none" project.

=cut

sub is_none_project {
    my $self = shift;
    return $self->name eq NONE_PROJECT_NAME;
}

=head2 store_column

Hooked to make sure that a change in L</status> to C<done> results in the L</completed_on> date being set to right now.

=cut

sub store_column {
    my ($self, $name, $value) = @_;

    if ($name eq 'status' and $value eq 'done') {
        $self->completed_on(Qublog::DateTime->now);
    }

    return $self->next::method($name, $value);
}


=head2 historical_values

Given a date it returns a single L</MOMENTO> representing a view of the task as of that date.

  # Get the task as it looked 2 weeks ago
  my $old_task = $task->historical_values(DateTime->now->subtract( weeks => 2 ));

Without that argument, this an array reference of momentos ordered so that the most recent item is first. This gives the full history of changes to the task.

=cut

sub historical_values {
    my ($self, $date) = @_;

    if ($date) {
        return Qublog::Schema::Result::Task::Momento->new($self, $date);
    }

    else {
        my $task_logs = $self->task_logs({}, { order_by => { -desc => 'created_on' } });

        my @records;
        my $end_date = undef;
        my $record   = Qublog::Schema::Result::Task::Momento->new($self, Qublog::DateTime->now);

        push @records, $record;
        while (my $task_log = $task_logs->next) {
            $records[-1]{span} = DateTime::Span->new(
                start => $task_log->created_on,
                (defined $end_date ? (before => $end_date) : ()),
            );

            # Join spans if a task log has no changes
            my $task_changes = $task_log->task_changes;
            next unless $task_changes->count > 0;

            $end_date = $task_log->created_on;
            $record = $record->clone;

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

=head1 MOMENTO

The momento class is like a frozen version of the main class. It provides accessors for all the columns of this class. It might, in the future, provide other methods, but it does not at this time.

=cut

{
    package Qublog::Schema::Result::Task::Momento;
    use Moose;

    with qw( MooseX::Clone );

    has id => (
        is        => 'ro',
    );

    has task_type => (
        is        => 'ro',
    );

    has child_handling => (
        is        => 'rw',
    );

    has status => (
        is        => 'ro',
    );

    has completed_on => (
        is        => 'ro',
    );

    has order_by => (
        is        => 'ro',
    );

    has project => (
        is        => 'ro',
    );

    has parent => (
        is       => 'ro',
    );

    has span => (
        is        => 'ro',
        isa       => 'DateTime::Span',
        predicate => 'has_span',
    );

    has as_of_date => (
        is        => 'ro',
        isa       => 'DateTime',
        required  => 1,
    );

    has based_on => (
        is        => 'ro',
        isa       => 'Qublog::Schema::Result::Task',
        required  => 1,
        handles   => [ qw( created_on ) ],
    );

    sub BUILDARGS {
        my ($class, $task, $date) = @_;
        my %args;

        my $task_logs = $task->task_logs({
            created_on => { '>', Qublog::DateTime->format_sql_datetime($date) },
        });

        %args = $task->get_columns;
        while (my $task_log = $task_logs->next) {
            my $task_changes = $task_log->task_changes;
            while (my $task_change = $task_changes->next) {
                $args{ $task_change->name } = $task_change->old_value;
            }
        }

        $args{based_on}   = $task;
        $args{as_of_date} = $date;

        return \%args;
    }
}

=head1 SEE ALSO

L<Qublog::Schema::ResultSet::Task>

=head1 SEE ALSO

L<Qublog::Server::Controller::Root>, L<Catalyst>

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
