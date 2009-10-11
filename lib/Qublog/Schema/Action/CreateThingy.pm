package Qublog::Schema::Action::CreateThingy;
use Moose;

use Qublog::Text::CommentParser;

use List::Util qw( min );

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

has owner => (
    is        => 'ro',
    isa       => 'Qublog::Schema::Result::User',
    required  => 1,
);

has journal_timer => (
    is        => 'ro',
    isa       => 'Qublog::Schema::Result::JournalTimer',
    predicate => 'has_journal_timer',
);

has comment => (
    is        => 'rw',
    isa       => 'Qublog::Schema::Result::Comment',
    predicate => 'has_comment',
);

has comment_text => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has project => (
    is        => 'ro',
    isa       => 'Qublog::Schema::Result::Task',
    required  => 1,
    lazy      => 1,
    default   => sub { shift->schema->resultset('Task')->project_none },
);

sub _create_comment_stub {
    my $self = shift;

    my $comment = $self->resultset('Comment')->create({
        journal_day   => $self->resultset('JournalDay')->for_today,
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
        $new_depth
    );
}

sub process {
    my $self = shift;

    $self->schema->txn_do(sub {

    $self->_create_comment_stub unless $self->has_comment;

    my $new_text = '';
    my @parent_stack;

    my $return_tokens = $self->parse( $self->comment_text );
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
                $token->new_nickname($token->nickname);
            }

            # Figure out who the parent should be
            my ($parent, $actual_depth) 
                = $self->_decide_parent(\@parent_stack, $token->depth);

            my %arguments;
            $arguments{parent}   = $parent        if $parent;
            $arguments{name}     = $token->description  
                if $token->has_description;
            $arguments{status}   = $token->status if $token->has_status;
            $arguments{latest_comment} = $self->comment;

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

            my $task_log = $task->task_logs({}, {
                order_by => { -desc => 'created_on' },
                rows     => 1,
            })->single;

            $new_text .= (' ' x $actual_depth) . ' * #' . $task->tag
                . '*' . $task_log->id . "\n";
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
    $comment->name( $new_text );
    $comment->update;

    });
}

1;
