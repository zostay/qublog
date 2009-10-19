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

sub new {
    my ($class, $args) = @_;

    $args->{task_type}      = 'action' unless defined $args->{task_type};
    $args->{child_handling} = 'serial' unless defined $args->{child_handler};
    $args->{status}         = 'open'   unless defined $args->{status};
    $args->{created_on}     = Qublog::DateTime->now
                                       unless defined $args->{created_on};
    $args->{order_by}       = 0        unless defined $args->{order_by};

    my $self = $class->next::method($args);

    if (not $self->project and not $self->parent) {
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

sub tag {
    my $self = shift;
    my $tag = $self->tags({}, { 
        rows     => 1, 
        order_by => { -desc => 'tag.id' }, 
    })->single;
    return $tag->name if $tag;
    die "no tag found for task";
}

sub autotag {
    my $self = shift;
    my $tag = $self->tags({}, { 
        rows     => 1, 
        order_by => { -asc => 'tag.id' }, 
    })->single;
    return $tag->name if $tag;
    die "no tag found for task";
}

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

sub update {
    my ($self, @args) = @_;
    $self->next::method(@args);
    $self->task_logs->new({})->fill_related_to(update => $self)->insert;
    return $self;
}

sub latest_task_log {
    my $self = shift;
    return $self->task_logs({}, { 
        order_by => { -desc => [ 'created_on', 'id' ] }, 
        rows     => 1,
    })->single;
}

sub as_journal_item {}

sub list_journal_item_resultsets {
    my ($self, $c) = @_;
    my $comments = $self->comments;
    return [ $comments ];
}

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

sub is_none_project {
    my $self = shift;
    return $self->name eq NONE_PROJECT_NAME;
}

sub store_column {
    my ($self, $name, $value) = @_;

    if ($name eq 'status' and $value eq 'done') {
        $self->completed_on(Qublog::DateTime->now);
    }

    return $self->next::method($name, $value);
}

1;
