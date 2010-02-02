package Qublog::Schema::Action::Thingy::Create;
use Form::Factory::Processor;

use Qublog::Text::CommentParser;

use List::Util qw( min );

has_control title => (
    control   => 'text',
    features  => {
        fill_on_assignment => 1,
        trim     => 1,
        required => 1,
    },
    options   => {
        label => 'On',
    },
    default   => '',
);

has_control detail => (
    control   => 'full_text',
    features  => {
        fill_on_assignment => 1,
        trim     => 1,
        required => 1,
    },
    options   => {
        label => 'Comment',
    },
    default   => '',
);

has parser => (
    is        => 'ro',
    isa       => 'Qublog::Text::CommentParser',
    lazy      => 1,
    required  => 1,
    default   => sub { Qublog::Text::CommentParser->new },
    handles   => [ qw( parse ) ],
);

has schema => (
    is        => 'ro',
    isa       => 'Qublog::Schema',
    required  => 1,
    handles   => [ qw( resultset ) ],
);

has today => (
    is        => 'ro',
    isa       => 'DateTime',
    required  => 1,
);

has owner => (
    is        => 'ro',
    isa       => 'Qublog::Schema::Result::User',
    required  => 1,
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

sub _create_comment_stub {
    my $self = shift;

    my $comment = $self->resultset('Comment')->create({
        journal_day   => $self->resultset('JournalDay')->for_today($self->today),
        journal_timer => $self->journal_timer,
        created_on    => Qublog::DateTime->now,
        name          => '',
        owner         => $self->owner,
    });

    $self->comment($comment);
}

sub _decide_parent {
    my ($self, $parent_stack, $depth) = @_;

    # Use min() in case they used too many dashes
    # FIXME This is probably not quite DWIMming
    my $new_depth = min($depth + 1, scalar(@$parent_stack) + 3);

    # Current depth
    my $old_depth = scalar @$parent_stack;

    SWITCH: {
        $new_depth  > $old_depth && do { last SWITCH };
        $new_depth == $old_depth && do { shift @$parent_stack; last SWITCH };
        DEFAULT: do { splice @$parent_stack, 0, $old_depth - $new_depth + 1 };
    }

    return (
        scalar(@$parent_stack) > 0 ? ($parent_stack->[0]) : (undef),
        $new_depth - 1
    );
}

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
        $task->owner($self->owner);
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

        $entry->journal_day($schema->resultset('JournalDay')->for_today(
            $self->today));
        $entry->name($self->title);
        $entry->project($task);
        $entry->owner($self->owner);
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

    $self->_create_comment_stub unless $self->has_comment;

    my $new_text = '';
    my @parent_stack;

    my $return_tokens = $self->parse( $self->detail );
    for my $token (@$return_tokens) {

        # Clear the parent stack if we encounter anything other than a task ref
        @parent_stack = () unless $token->isa(TASK);

        if ($token->isa(TASK)) {
            my $task;
            if (not $token->force_create and $token->has_nickname) {
                $task = $self->resultset('Task')
                    ->find_by_tag_name($token->nickname);
            }

            if (not $task) {
                if ($token->has_new_nickname) {
                    $token->description('#' . $token->new_nickname . ': ' 
                                      . $token->description);
                }
                $token->new_nickname($token->nickname)
                    if $token->has_nickname;
            }

            # Figure out who the parent should be
            my ($parent, $actual_depth) 
                = $self->_decide_parent(\@parent_stack, $token->depth);

            my %arguments;
            $arguments{parent}   = $parent        if $parent;
            $arguments{name}     = $token->description  
                if $token->has_description;
            $arguments{status}   = $token->status if $token->has_status;
            $arguments{latest_comment} = $self->comment->id;
            $arguments{owner}    = $self->owner;

            if ($task) {
                $task->update(\%arguments);
            }
            else {
                $arguments{project} = $self->project;
                $task = $self->resultset('Task')->create(\%arguments);
            }

            $task->add_tag( $token->new_nickname )
                if $token->has_new_nickname;

            unshift @parent_stack, $task;

            my $task_log = $task->latest_task_log;

            $new_text .= "\n" . (' ' x $actual_depth) . '* #' . $task->autotag
                . '*' . $task_log->id;
        }

        elsif ($token->isa(TEXT)) {
            $new_text .= $token->text;
        }
        
        elsif ($token->isa(TASK_LOG)) {
            $new_text .= '#' . $token->nickname . '*' . $token->task_log;
        }

        elsif ($token->isa(TAG)) {
            my $tag = $self->resultset('Tag')->find_or_create({ 
                name => $token->nickname 
            });

            $new_text .= '#' . $token->nickname;
        }

        else {
            die "Unknown token type.";
        }
    }

    my $comment = $self->comment;
    $new_text =~ s/^\n(\s+)\*/$1*/;
    $comment->name( $new_text );
    $comment->update;
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

1;
