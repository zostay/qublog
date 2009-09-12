package Qublog::Schema::Result::Tag;
use Moose;
extends qw( DBIx::Class );
with qw( Qublog::Schema::Role::Itemized );

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('tags');
__PACKAGE__->add_columns(
    id   => { data_type => 'int' },
    name => { data_type => 'text' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many( task_tags => 'Qublog::Schema::Result::TaskTag', 'tag' );
__PACKAGE__->has_many( comment_tags => 'Qublog::Schema::Result::CommentTag', 'tag' );
__PACKAGE__->has_many( journal_entry_tags => 'Qublog::Schema::Result::JournalEntryTag', 'tag' );
__PACKAGE__->many_to_many( tasks => task_tags => 'task' );
__PACKAGE__->many_to_many( comments => comment_tags => 'comment' );
__PACKAGE__->many_to_many( journal_entries => journal_entry_tags => 'journal_entry' );

sub as_journal_item { }

sub list_journal_item_resultsets {
    my ($self, $c) = @_;
    
    my @result_sets;
    push @result_sets, $self->comments;
    push @result_sets, $self->tasks;
    push @result_sets, $self->journal_entries;

    return [ grep { $_ } @result_sets ];
}

1;
