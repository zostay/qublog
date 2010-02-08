package Qublog::Schema::Action::Comment::Store;
use Form::Factory::Processor;

with qw(
    Qublog::Schema::Action::Role::Model::Comment
    Qublog::Schema::Action::Role::Do::Store
);

use Qublog::Text::CommentParser;

has parser => (
    is        => 'ro',
    isa       => 'Qublog::Text::CommentParser',
    lazy      => 1,
    required  => 1,
    default   => sub { Qublog::Text::CommentParser->new },
    handles   => [ qw( parse ) ],
);

has_control name => (
    control   => 'full_text',
    traits    => [ 'Model::Column' ],
    options   => {
        label => 'Comment',
    },
    features  => {
        fill_on_assignment => 1,
        required => 1,
        trim     => 1,
    },
);

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

around do => sub {
    my $next = shift;
    my $self = shift;

    my $new_text = '';
    my @parent_stack;

    $self->$next;

    my $return_tokens = $self->parse( $self->name );
    for my $token (@$return_tokens) {

        # Clear the parent stack if we encounter anything other than a task ref
        @parent_stack = () unless $token->isa(TASK);

        if ($token->isa(TASK)) {
            my $task;
            if (not $token->force_create and $token->has_nickname) {
                $task = $self->schema->resultset('Task')
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
            $arguments{latest_comment} = $self->record->id;
            $arguments{owner}    = $self->current_user;

            if ($task) {
                $task->update(\%arguments);
            }
            else {
                $arguments{project} = $self->project;
                $task = $self->schema->resultset('Task')->create(\%arguments);
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
            my $tag = $self->schema->resultset('Tag')->find_or_create({ 
                name => $token->nickname 
            });

            $new_text .= '#' . $token->nickname;
        }

        else {
            die "Unknown token type.";
        }
    }

    my $comment = $self->record;
    $new_text =~ s/^\n(\s+)\*/$1*/;
    $comment->name( $new_text );
    $comment->update;
};

1;
