package Qublog::Schema::Result::Comment;
use Moose;
extends qw( Qublog::Schema::Result );

with qw( Qublog::Schema::Role::Itemized );

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('comments');
__PACKAGE__->add_columns(
    id            => { data_type => 'int' },
    journal_day   => { data_type => 'int' },
    journal_timer => { data_type => 'int' },
    created_on    => { data_type => 'datetime', timezone => 'UTC' },
    name          => { data_type => 'text' },
    processed_name_cache => { data_type => 'text' },
    owner         => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( journal_day => 'Qublog::Schema::Result::JournalDay' );
__PACKAGE__->belongs_to( journal_timer => 'Qublog::Schema::Result::JournalTimer' );
__PACKAGE__->belongs_to( owner => 'Qublog::Schema::Result::User' );
__PACKAGE__->has_many( task_logs => 'Qublog::Schema::Result::TaskLog', 'comment' );
__PACKAGE__->has_many( comment_tags => 'Qublog::Schema::Result::CommentTag', 'comment' );
__PACKAGE__->many_to_many( tags => comment_tags => 'tag' );

sub store_column {
    my ($self, $name, $value) = @_;

    # Clear the processed name cache if the name changes
    if ($name eq 'name') {
        $self->processed_name_cache(undef);
    }

    $self->next::method($name, $value);
}

sub as_journal_item {
    my ($self, $c, $items) = @_;

    my $order_priority = eval {
          $self->journal_timer->id ? $self->journal_timer->start_time->epoch
        :                            $self->created_on->epoch;
    } || 0;
    $order_priority *= 10;
    $order_priority +=  5;

    # Cache this info because not caching is expensive
    my $processed_name_cache = $self->processed_name_cache;
    unless ($processed_name_cache) {
        $processed_name_cache = Qublog::Web::htmlify($self->name, $c);
        $self->processed_name_cache($processed_name_cache);
        $self->update;
    }

    my $name = 'Comment-'.$self->id;
    $items->{$name} = {
        id             => $self->id,
        name           => $name,
        order_priority => $order_priority,

        row => {
            class => ($self->journal_timer->id ? 'timer-comment'
                     :                           'free-comment'),
        },

        timestamp => $self->created_on,
        content   => {
            content => $processed_name_cache,
            format  => [ 'div' ],
        },

        links => [
            {
                label   => 'Edit',
                class   => 'icon v-edit o-comment',
                goto    => $c->request->uri_with({
                    form       => 'edit_comment',
                    form_place => 'Comment-'.$self->id,
                    form_type  => 'replace',
                    comment    => $self->id,
                }),
            },
            {
                label   => 'Remove',
                class   => 'icon v-delete o-comment',
                action  => $c->uri_for('/compat/comment/delete', $self->id, {
                    return_to => $c->request->uri,
                }),
            },
        ],
    };
}

sub list_journal_item_resultsets { };

1;
