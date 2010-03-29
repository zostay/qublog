package Qublog::Schema::Action::Thingy::Create;
use Form::Factory::Processor;

with qw( 
    Qublog::Action::Role::WantsCurrentUser
    Qublog::Action::Role::WantsToday 
    Qublog::Action::Role::Secure
);

use Qublog::Schema::Action::Comment::Create;
use Qublog::Schema::Action::Comment::Update;

use List::Util qw( min );

has_control title => (
    is        => 'rw',
    default   => '',

    control   => 'text',

    features  => {
        fill_on_assignment => 1,
        trim     => 1,
        required => 1,
    },

    options   => {
        label => 'On',
    },
);

has_control detail => (
    is        => 'rw',
    default   => '',

    control   => 'full_text',

    features  => {
        fill_on_assignment => 1,
        trim     => 1,
        required => 1,
    },

    options   => {
        label => 'Comment',
    },
);

has schema => (
    is        => 'ro',
    isa       => 'Qublog::Schema',
    required  => 1,
    handles   => [ qw( resultset ) ],
);

has journal_session => (
    is        => 'rw',
    isa       => 'Qublog::Schema::Result::JournalSession',
    predicate => 'has_journal_session',
);

has journal_timer => (
    is        => 'rw',
    isa       => 'Qublog::Schema::Result::JournalTimer',
    predicate => 'has_journal_timer',
);

has comment => (
    is        => 'rw',
    isa       => 'Qublog::Schema::Result::Comment',
    predicate => 'has_comment',
);

has project => (
    is        => 'rw',
    isa       => 'Qublog::Schema::Result::Task',
    required  => 1,
    lazy      => 1,
    default   => sub { shift->schema->resultset('Task')->project_none },
);

sub _process_task {
    my ($self, $task, $nickname, $short_nickname) = @_;

    # Add a comment to an existing task
    if ($task->in_storage) {
        $self->_process_comment;

        $task->create_related(task_logs => {
            type    => 'note',
            message => $self->comment,
        });

        $self->success(
            sprintf('added a comment to task #%s', $task->tag)
        );
    }

    else {
        $task->name($self->detail);
        $task->owner($self->current_user);
        $task->task_type('action');
        $task->status('open');
        $task->parent($self->schema('Task')->project_none);
        $task->insert;

        $task->add_tag($nickname) if $nickname;

        $self->success(
            sprintf('added a new task #%s to project #%s',
                $task->tag, $task->project->tag)
        );
    }
}

sub _process_timer {
    my ($self, $timer, $nickname, $short_nickname) = @_;

    $self->journal_timer($timer);
    $self->_process_comment;

    $self->success('added a new comment to the current timer');
}

sub _process_entry {
    my ($self, $entry, $nickname, $short_nickname) = @_;

    my ($timer, $message);

    # Restart the existing entry
    if ($entry->in_storage) {
        $timer   = $entry->start_timer;
        $message = sprintf('restarted %s and added your comment', $entry->name);
    }

    # Create and start a new entry
    else {
        my $schema = $self->schema;
        my $task = $schema->resultset('Task')->find_by_tag_name($nickname);
           $task = $schema->resultset('Task')->project_none unless $task;

        $entry->journal_session($self->journal_session);
        $entry->name($self->title);
        $entry->project($task);
        $entry->owner($self->current_user);
        $entry->insert;

        $timer   = $entry->start_timer;
        $message = sprintf('started %s and added your comment', $entry->name);
    }

    unless ($timer) {
        $self->failure('failed to start a timer');
        return;
    }

    $self->journal_timer($timer);
    $self->project($timer->journal_entry->project);
    $self->_process_comment;

    $self->success($message);
}

sub _process_comment {
    my $self = shift;

    my $action;
    if ($self->has_comment) {
        $action = $self->form_interface->new_action(
            'Qublog::Schema::Action::Comment::Update' => {
                schema        => $self->schema,
                record        => $self->comment,
                id            => $self->comment->id,
                created_on    => $self->comment->created_on,
                name          => $self->detail,
                current_user  => $self->current_user,
            },
        );
    }

    else {
        $action = $self->form_interface->new_action(
            'Qublog::Schema::Action::Comment::Create' => {
                schema          => $self->schema,
                journal_session => $self->journal_session,
                journal_timer   => $self->journal_timer,
                created_on      => Qublog::DateTime->now,
                name            => $self->detail,
                owner           => $self->current_user,
                current_user    => $self->current_user,
            },
        );
    }

    $action->clean;
    $action->check;
    $action->process;
}

sub run {
    my $self   = shift;
    my $schema = $self->schema;

    $schema->txn_do(sub {

    my $title  = $self->title;
    my ($nickname, $short_nickname) = $title =~ /^(#(\w+))/;

    my $thingy;

    # Is the nickname the title? Task comment create; no entry or timer
    if (defined $nickname and $nickname eq $title) {
        $thingy = $schema->resultset('Task')->load_by_tag_name($short_nickname)
               || $schema->resultset('Task')->new;
    }

    # Otherwise, we're trying to create an entry/timer/comment
    else {

        # Get the current day; we'll use it to find timers
        my $day = $schema->resultset('JournalDay')->for_today($self->today);

        my $matching_entries = $day->search_related(journal_entries => {
            name => $title,
        });

        # Does the title match a running entry?
        {
            my $entries = $matching_entries->search_by_running(1)->search({}, {
                order_by => { -desc => 'start_time' },
                rows     => 1,
            });

            if ($entries->count > 0) {
                my $timer = $entries->single->journal_timers->search_by_running(1)
                    ->search({}, {
                        order_by => { -desc => 'start_time' },
                        rows     => 1,
                    })->single;

                $thingy = $timer if $timer;
            }
        }

        # If we're still looking, does the title match an existing entry?
        unless ($thingy) {
            my $entries = $matching_entries->search({}, {
                order_by => { -desc => 'start_time' },
                rows     => 1,
            });

            $thingy = $entries->single || $entries->new({});
        }
    }

    my @args = ($thingy, $nickname, $short_nickname);
    if ($thingy->isa('Qublog::Schema::Result::Task')) {
        $self->_process_task(@args);
    }
    elsif ($thingy->isa('Qublog::Schema::Result::JournalTimer')) {
        $self->_process_timer(@args);
    }
    elsif ($thingy->isa('Qublog::Schema::Result::JournalEntry')) {
        $self->_process_entry(@args);
    }
    else {
        die 'I do not know what happened, but it was bad.';
    }

    });
}

sub may_run {
    my $self = shift;

    if ($self->has_journal_timer) {
        unless ($self->current_user->id == $self->journal_timer->journal_entry->owner->id) {
            $self->error('you cannot work on a comment on a timer for a different user');
            $self->is_valid(0);
        }
    }

    if ($self->has_comment) {
        unless ($self->current_user->id == $self->comment->owner->id) {
            $self->error('you cannot modify a comment for a different user');
            $self->is_valid(0);
        }
    }

    unless ($self->current_user->id == $self->project->owner->id) {
        $self->error('you cannot comment on a project for a different user');
        $self->is_valid(0);
    }
}

1;
