package Qublog::Schema::Result::Comment;
use strict;
use warnings;
use base qw( DBIx::Class );

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('comments');
__PACKAGE__->add_columns(
    id            => { data_type => 'int' },
    journal_day   => { data_type => 'int' },
    journal_timer => { data_type => 'int' },
    created_on    => { data_type => 'datetime' },
    name          => { data_type => 'text' },
));
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( journal_day => 'Qublog::Schema::Result::JournalDay' );
__PACKAGE__->belongs_to( journal_timer => 'Qublog::Schema::Result::JournalTimer' );
__PACKAGE__->has_many( task_logs => 'Qublog::Schema::Result::TaskLog', 'comment' );
__PACKAGE__->has_many( comment_tags => 'Qublog::Schema::Result::CommentTag', 'comment' );
__PACKAGE__->many_to_many( tags => comment_tags => 'tag' );

1;
