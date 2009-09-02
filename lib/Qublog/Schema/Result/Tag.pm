package Qublog::Schema::Result::Tag;
use strict;
use warnings;
use base qw( DBIx::Class );

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('tags');
__PACKAGE__->add_columns(
    id => { data_type => 'int' },
    name => { data_type => 'text' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many( task_tags => 'Qublog::Schema::Result::TaskTag', 'tag' );
__PACKAGE__->has_many( comment_tags => 'Qublog::Schema::Result::CommentTag', 'tag' );
__PACKAGE__->has_many( journal_entry_tags => 'Qublog::Schema::Result::JournalEntrytag', 'tag' );
__PACKAGE__->many_to_many( tasks => task_tags => 'task' );
__PACKAGE__->many_to_many( comments => comment_tags => 'comment' );
__PACKAGE__->many_to_many( journal_entries => journal_entry_tags => 'journal_entry' );

1;
