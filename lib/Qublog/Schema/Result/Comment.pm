package Qublog::Schema::Result::Comment;
use Moose;
extends qw( DBIx::Class );

with qw( Qublog::Schema::Role::Itemized );

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('comments');
__PACKAGE__->add_columns(
    id            => { data_type => 'int' },
    journal_day   => { data_type => 'int' },
    journal_timer => { data_type => 'int' },
    created_on    => { data_type => 'datetime', timezone => 'UTC' },
    name          => { data_type => 'text' },
    owner         => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( journal_day => 'Qublog::Schema::Result::JournalDay' );
__PACKAGE__->belongs_to( journal_timer => 'Qublog::Schema::Result::JournalTimer' );
__PACKAGE__->belongs_to( owner => 'Qublog::Schema::Result::User' );
__PACKAGE__->has_many( task_logs => 'Qublog::Schema::Result::TaskLog', 'comment' );
__PACKAGE__->has_many( comment_tags => 'Qublog::Schema::Result::CommentTag', 'comment' );
__PACKAGE__->many_to_many( tags => comment_tags => 'tag' );

sub as_journal_item {
    my ($self, $c, $items) = @_;

    my $order_priority = eval {
          $self->journal_timer->id ? $self->journal_timer->start_time->epoch
        :                            $self->created_on->epoch;
    } || 0;
    $order_priority *= 10;
    $order_priority +=  5;

    $items->{'Comment-'.$self->id} = {
        id             => $self->id,
        order_priority => $order_priority,

        row => {
            class => ($self->journal_timer->id ? 'timer-comment'
                     :                           'free-comment'),
        },

        timestamp => $self->created_on,
        content   => $self->name,

        links => [
            {
                label   => 'Edit',
                class   => 'icon v-edit o-comment',
                onclick => {
                    open_popup   => 1,
                    replace_with => 'journal/popup/edit_comment',
                    arguments    => {
                        comment_id => $self->id,
                    },
                },
            },
            {
                label   => 'Remove',
                class   => 'icon v-delete o-comment',
                as_link => 1,
                onclick => {
                    refresh => 'journal_list',
                    confirm => 'Are you sure? This cannot be undone.',
                    submit  => new_action(
                        class  => 'DeleteComment',
                        record => $self,
                    ),
                },
            },
        ],
    };
}

sub list_journal_item_resultsets { };

1;
