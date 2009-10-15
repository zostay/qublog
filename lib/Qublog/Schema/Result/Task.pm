package Qublog::Schema::Result::Task;
use Moose;
extends qw( Qublog::Schema::Result );

with qw( Qublog::Schema::Role::Itemized );

use Moose::Util::TypeConstraints;

enum 'Qublog::Schema::Result::Task::Status' => qw( open done nix );
enum 'Qublog::Schema::Result::Task::ChildHandling' => qw( serial parallel );
enum 'Qublog::Schema::Result::Task::Type' => qw( project group action );

no Moose::Util::TypeConstraints;

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('tasks');
__PACKAGE__->add_columns(
    id             => { data_type => 'int' },
    name           => { data_type => 'text' },
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
    my ($class, $attrs) = @_;

    $attrs->{order_by} = 0 
        unless defined $attrs->{order_by};

    return $class->next::method($attrs);
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
    return [ $self->comments ];
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

1;
