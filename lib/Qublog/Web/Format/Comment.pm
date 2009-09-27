package Qublog::Web::Format::Comment;
use Moose;

use Qublog::Text::CommentParser;

has schema => (
    is        => 'rw',
    isa       => 'Qublog::Schema',
    required  => 1,
    handles   => [ qw( resultset ) ],
);

has parser => (
    is        => 'rw',
    isa       => 'Qublog::Text::CommentParser',
    required  => 1,
    lazy      => 1,
    default   => sub { Qublog::Text::CommentParser->new },
    handles   => [ qw( parse ) ],
);

use constant TEXT => 'Qublog::Text::CommentParser::Token::Text';
use constant TAG  => 'Qublog::Text::CommentParser::Token::TagReference';
use constant TASK => 'Qublog::Text::CommentParser::Token::TaskLogReference';

sub format {
    my ($self, $scalar) = @_;

    my $tokens = $self->parse($scalar);

    my $output = '';
    for my $token (@$tokens) {
        if ($token->isa(TEXT)) {
            $output .= $token->text;
        }
        elsif ($token->isa(TASK) or $token->isa(TAG)) {
            my $log;
            $log = $self->resultset('TaskLog')->find($token->task_log)
                if $token->isa(TASK);
            my $task = $self->resultset('Task')->find_by_tag_name($token->nickname);

            my $nickname = $task->tag;
            if ($log and $task and $log->task->id == $task->id) {
                my $old_task = $task->historical_value($log->created_on);

                my $classes
                    = join ' ',
                        map { $_ ? 'a-'.$_ : () }
                            $log->log_type, $old_task->task_type,
                            $old_task->status;

                my $url  = '/project/edit/'.$task->tag;
                my $name = $task->name;
                $output .= qq{<a href="$url" class="icon task-reference v-view $classes o-task">#$nickname: $name</a>};
            }

            else {
                my $tag;
                $self->schema->do_txn(sub {
                    $tag = $self->resultset('Tag')->find_or_create( 
                        name => $nickname 
                    );
                });
                $output .= qq{<a class="icon center-left v-view o-tag" href="/tag/view/$nickname">#$nickname</a>};
            }
        }
        else {
            warn "Don't know what to do with $token";
        }
    }

    return $output;
}

1;
