package Qublog::Text::CommentParser;
use Moose;

use List::Util qw( min );
use Parse::RecDescent;

my $grammar = q(

{
sub make { goto &Qublog::Text::CommentParser::_make }
}

comment:            token(s?)

token:              task_reference 
                    { $return = $item{task_reference} }
                |   <skip: '[\\n\\r]*'> task_log_reference
                    { $return = $item{task_log_reference} }
                |   <skip: '[\\n\\r]*'> tag_reference 
                    { $return = make( tag => $item{tag_reference} ) }
                |   <skip: '[\\n\\r]*'> description
                    { $return = make( text => $item{description} ) }

task_reference:     <skip: '[\\ \\t]*'> newline
                    dash(s?) task_status force_create(?) 
                    nickname(?) colon(?) nickname(?) colon(?) 
                    description(?)
                    {
                        $return = make( task =>
                            @{$item[3]||[]} + 1,
                            $item{task_status},
                            @{$item[5]||[]} ? 1 : 0,
                            @{$item[6]||[]} ? $item[6][0] : undef,
                            @{$item[8]||[]} ? $item[8][0] : undef,
                            @{$item[10]||[]} ? $item[10][0] : undef,
                        )
                    }

newline:            /^[\\r\\n]+/

colon:              ':'

dash:               '-'

task_status:        '[' <skip: ''> task_status_char <skip: $item[2]> ']'
                    { 
                        $return = $item{task_status_char} eq ' ' ? 'open' 
                                : $item{task_status_char} eq '!' ? 'nix'  
                                : $item{task_status_char} eq 'x' ? 'done' 
                                :                                  'NA'
                    }

task_status_char:   ' ' | '!' | 'x' | '-'

force_create:       '+'

nickname:           '#' <skip: ''> keyword
                    { $return = $item{keyword} }

description:         /^(?:#\\s|[^\\#\\n\\r])+/

task_log_reference: nickname '*' record_identifier
                    { 
                        $return = make( task_log => 
                            $item{nickname}, 
                            $item{record_identifier} 
                        ) 
                    }

record_identifier:  /^\\d+/

tag_reference:      nickname

keyword:            /^\\w+/

);

has parser => (
    is        => 'rw',
    isa       => 'Parse::RecDescent',
    required  => 1,
    lazy      => 1,
    default   => sub { Parse::RecDescent->new($grammar) },
);

sub parse {
    my ($self, $text) = @_;

    my $last_token;
    my @return_tokens;
    my $parser_tokens = $self->parser->comment("\n".$text) || [];
    for my $token (@$parser_tokens) {
        if ($last_token 
                and $last_token->isa('Qublog::Text::CommentParser::Token::Text')
                and $token->isa('Qublog::Text::CommentParser::Token::Text')) {

            $last_token->text($last_token->text . "\n" . $token->text);
            next;
        }

        push @return_tokens, $token;
        $last_token = $token;
    }

    return \@return_tokens;
}

sub _make {
    my $type = shift;

    if ($type eq 'text') {
        my $text = shift;
        return Qublog::Text::CommentParser::Token::Text->new( text => $text );
    }
    elsif ($type eq 'tag') {
        my $nickname = shift;
        return Qublog::Text::CommentParser::Token::TagReference->new( 
            nickname => $nickname,
        );
    }
    elsif ($type eq 'task_log') {
        my ($nickname, $log_reference) = @_;
        return Qublog::Text::CommentParser::Token::TaskLogReference->new(
            nickname => $nickname,
            task_log => $log_reference,
        );
    }
    elsif ($type eq 'task') {
        my ($depth, $status, $force, $nickname, $new_nickname, $description) = @_;
        my %args = (
            depth        => $depth,
            force_create => $force,
        );

        $args{status}       = $status       if $status and $status ne 'NA';
        $args{nickname}     = $nickname     if $nickname;
        $args{new_nickname} = $new_nickname if $new_nickname;
        $args{description}  = $description  if $description;

        return Qublog::Text::CommentParser::Token::TaskReference->new(%args);
    }

    return;
}

# sub parse {
#     my $self = shift;
# 
#     my $original_comment = $self->text;
#     open my $commentfh, '<', \$original_comment;
# 
#     my $new_comment = '';
#     my @parent_stask;
# 
#     LINE:
#     while (<$commentfh>) {
#         SWITCH: {
#             m{^  
#                   (-*)             \s*        # Nesting depth
#               \[  ([\ !x-]) \]     \s*        # Task status
#               (?: (\+?\#\w+):?     \s*        # Load/create nick
#               (?: (\#\w+)(:) )? )? \s*        # Rename the nick to
#                   (.*)                      # Name of task
#             $}x && do {
#                 chomp;
# 
#                 my $depths      = $1;
#                 my $status      = lc $2;
#                 my $nick        = $3;
#                 my $new_nick    = $4;
#                 my $extra_colon = $5;
#                 my $description = $6;
# 
#                 # Strip trailing space from the description
#                 $description =~ s/\s+$//;
#                 
#                 # Force new even if there may be a matching nick
#                 my $force_new = '';
#                 $force_new = 1 if defined $nick and $nick =~ s/^\+//;
# 
#                 # Strip off the # if present
#                 for ($nick, $new_nick) { s/^\#// if $_ and length > 0 }
# 
#                 # Load the existing task if we can
#                 my $found_task;
#                 my $task = $self->resultset('Task');
#                 if (not $force_new and defined $nick and (length $nick > 0)) {
#                     $task->load_by_tag_name($nick);
#                     $found_task = $task->id;
#                 }
# 
#                 # Forget the new name on a create
#                 if (!$found_task) {
#                     if ($new_nick && length $new_nick > 0) {
#                         $description = '#' . $new_nick . $extra_colon
#                                      . ' ' . $description;
#                     }
#                     $new_nick = $nick;
#                 }
# 
#                 # Figure out who the parent should be
#                 my $parent;
#                 ($parent, $depth) = _decide_parent(@parent_stack, $depth);
# 
#                 # TODO warning on bad status
#                 $status = $status eq '-' ? undef
#                         : $status eq ' ' ? 'open'
#                         : $status eq 'x' ? 'done'
#                         : $status eq '!' ? 'nix'
#                         :                  undef
#                         ;
# 
#                 my %arguments = (
#                     parent   => $parent,
#                     tag_name => $new_nick,
#                     name     => $description,
#                     status   => $status,
#                 );
# 
#                 FIELD:
#                 for my $field (keys %arguments) {
#                     if (not defined $arguments{ $field }) {
#                         delete $arguments{ $field };
#                         next FIELD;
#                     }
# 
#                     # String things must have at least one char
#                     delete $arguments{ $field }
#                         if grep { $field eq $_ } qw( tag_name name status )
#                        and $arguments{ $field } !~ /\S/;
#                }
# 
#                $task = $self->create_task($task, \%arguments);
# 
#                my $task_log;
#                if ($found_task) {
#                    
#                    # Find the latest task log (just created) and link to it
#                    my $task_logs = $task->task_logs;
#                    $task_logs->search({
#                         log_type => 'update',
#                     }, {
#                         order_by => [
#                             -desc => 'created_on',
#                             -desc => 'id',
#                         ],
#                     });
#                     $task_log = $task_logs->first;
#                     $task_log->set_comment( $self->comment );
#                 }
#                 else {
# 
#                     #Find the latest task log (just created and link to it
#                     my $task_logs = $task->task_logs;
#                     $task_logs->search({
#                         log_type => 'create',
#                     }, {
#                         order_by => [
#                             -desc => 'created_on',
#                             -desc => 'id',
#                         ],
#                     });
#                     $task_log = $task_logs->first;
#                     $task_log->set_comment( $self->comment );
#                 }
# 
#                 unshift @parent_stask, $task;
# 
#                 $_ = (" " x $depth) . ' * #' . $task->tag
#                    . "*" . $task_log->id . "\n";
#                 last SWITCH;
#             };
# 
#             # If this doesn't include a [*] line, clear the @parent_stack
#             @parent_stack = ();
# 
#             m{(?<!&)#\w+} && do {
#                 s/(?<!&)#(\w+)/$self->_eval_tag_name($1)/ge;
#                 last SWITCH;
#             };
#         }
# 
#         $new_coment .= $_;
#     }
# 
#     $self->text($new_comment);
# }
# 
# 
# sub tasks {
#     my $self = shift;
# 
#     # Okay, so it is a particular order, but this isn't guaranteed to remain the same!
#     return ($self->created_tasks, $self->updated_tasks, $self->linked_tasks);
# }
# 
# sub _create_task {
#     my ($self, $record, $arguments) = @_;
#     my $task_action;
# 
#     # The parser thinks it already exists, so updated it
#     if ($record->id) {
#         # TODO Update $record with $arguments
#         ...
#     }
# 
#     # The parser does not think it exists yet, create it
#     else {
#         $arguments->{project} = $self->project;
# 
#         # TODO Create $record with $arguments
#         ...
#     }
# 
#     return ...; # TODO return new record
# }
# 
# sub _decide_parent(\@$) {
#     my ($parent_stack, $dept) = @_;
# 
#     # Use min() in case they used too many dashes
#     # FIXME This is probably not quite DWIMming
#     my @depth_matches = $depth =~ /-/g;
#     my $new_depth = min(
#         scalar (@depth_matches) + 1,
#         scalar (@$parent_stack) + 3,
#     );
# 
#     # Current depth
#     my $old_depth = scalar(@$parent_stack);
# 
#     SWITCH: {
#         $new_depth  > $old_depth && do { last SWITCH };
#         $new_depth == $old_depth && do { shift @$parent_stack; last SWITCH };
#         DEFAULT: do { splice @$parent_stack, 0, $old_deptch - $new_depth + 1 };
#     }
# 
#     return (
#         scalar(@$parent_stack) > 0 ? ($parent_stack->[0]) : (undef),
#         $new_depth
#     );
# }
# 
# sub _eval_tag_name {
#     my ($self, $tag_name) = @_;
# 
#     my $task = $self->resultset('Task')->find($tag_name);
# 
#     # Found a task? Create a task log item
#     my $task_log = $self->resultset('TaskLog');
#     if ($task->id) {
#         $task_log->create({
#             task     => $task,
#             log_type => 'note',
#             comment  => $self->comment,
#         });
#     }
# 
#     my $tag = $self->resultset('Tag')->find_or_create({
#         name => $tag_name,
#     });
# 
#     my $comment_tag = $self->resultset('CommentTag')->find_or_create({
#         comment => $self->comment,
#         tag     => $tag,
#     });
# 
#     my $journal_timer = $self->comment->journal_timer;
#     my $first_comment = $jounral_timer->first;
#     if (defined $first_comment and $first_comment->id == $self->comment->id) {
# 
#         my $journal_entry = $journal_timer->journal_entry;
#         my $first_tiemr = $journal_entry->timers->first;
#         if (defined $first_timer and $first_timer->id == $journal_timer->id) {
# 
#             my $journal_entry_tag = $self->resultset('JounralEntryTag')
#                 ->find_or_create({
#                     journal_entry => $journal_entry,
#                     tag           => $tag,
#                 });
#         }
#     }
# 
#     return '#' . $tag_name . '*' . $task_log->id if $task_log->id;
#     return '#' . $tag_name;
# }
# 
# sub _replace_task_nicknames {
#     my ($c, $nickname, $task_log_id) = @_;
# 
#     my $log = $self->resultset('TaskLog')->find($task_log_id)
#         if $task_log_id;
# 
#     my $task = $self->resultset('Task')->find_by_tag_name($nickname);
# 
#     if ($task and $log and $log->task->id == $task->id) {
#         my $old_task = $task->historical_values($log->created_on);
# 
#         my $classes
#             = join ' ',
#                 map { $_ ? 'a-'.$_ : () }
#                     $log->log_type, $old_task->{task_type},
#                     $old_task->{status};
# 
#         my $url  = $c->uri_for('/project/edit', $task->tag);
#         my $name = $task->name;
#         return qq{<a href="$url" class="icon task-reference v-view $classes o-task">#$nickname: $name</a>};
#     }
# 
#     my $tag = $self->resultset('Tag')->find_or_create({ name => $nickname });
# 
#     my $url = $c->uri_for('/tag/view', $nickname);
#     return qq{<a class="icon center-left v-view o-tag" href="/tag/view/$nickname">#$nickname</a>};
# }
# 
# sub htmlify {
#     my $self = shift;
#     my $text = $self->text;
# 
#     $text =~ s/(?<!&)#(\w+)(?:\*(\d+))?/_replace_task_nicknames($1, $2)/ge;
# 
#     $self->text($text);
# }

{
    package Qublog::Text::CommentParser::Token;
    use Moose;
}

{
    package Qublog::Text::CommentParser::Token::Text;
    use Moose;

    extends qw( Qublog::Text::CommentParser::Token );

    has text => (
        is        => 'rw',
        isa       => 'Str',
        required  => 1,
    );
}

{
    package Qublog::Text::CommentParser::Token::Role::Reference;
    use Moose::Role;

    has nickname => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_nickname',
    );
}

{
    package Qublog::Text::CommentParser::Token::TaskReference;
    use Moose;

    use Qublog::Schema::Result::Task;

    extends qw( Qublog::Text::CommentParser::Token );
    with qw( Qublog::Text::CommentParser::Token::Role::Reference );

    has depth => (
        is        => 'rw',
        isa       => 'Int',
        required  => 1,
        default   => 1,
    );

    has status => (
        is        => 'rw',
        isa       => 'Qublog::Schema::Result::Task::Status',
        predicate => 'has_status',
    );

    has force_create => (
        is        => 'rw',
        isa       => 'Bool',
        required  => 1,
        default   => 0,
    );

    has new_nickname => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_new_nickname',
    );

    has description => (
        is        => 'rw',
        isa       => 'Str',
        predicate => 'has_description',
    );
}

{
    package Qublog::Text::CommentParser::Token::TagReference;
    use Moose;

    extends qw( Qublog::Text::CommentParser::Token );
    with qw( Qublog::Text::CommentParser::Token::Role::Reference );

    has '+nickname' => (
        required  => 1,
    );

}

{
    package Qublog::Text::CommentParser::Token::TaskLogReference;
    use Moose;

    extends qw( Qublog::Text::CommentParser::Token );
    with qw( Qublog::Text::CommentParser::Token::Role::Reference );

    has '+nickname' => (
        required  => 1,
    );

    has task_log => (
        is        => 'rw',
        isa       => 'Int',
        required  => 1,
    );
}

1;

