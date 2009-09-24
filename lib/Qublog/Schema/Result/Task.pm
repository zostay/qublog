package Qublog::Schema::Result::Task;
use Moose;
extends qw( DBIx::Class );

with qw( Qublog::Schema::Role::Itemized );

use Moose::Util::TypeConstraints;

enum 'Qublog::Schema::Result::Task::Status' => qw( open done nix );
enum 'Qublog::Schema::Result::Task::ChildHandling' => qw( serial parallel );
enum 'Qublog::Schema::Result::Task::Type' => qw( project group action );

no Moose::Util::TypeConstraints;

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('tasks');
__PACKAGE__->add_columns(
    id             => { data_type => 'int' },
    task_type      => { data_type => 'text' },
    child_handling => { data_type => 'text' },
    status         => { data_type => 'text' },
    created_on     => { data_type => 'datetime', timezone => 'UTC' },
    completed_on   => { data_type => 'datetime', timezone => 'UTC' },
    order_by       => { data_type => 'int' },
    project        => { data_type => 'int' },
    parent         => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( project => 'Qublog::Schema::Result::Task' );
__PACKAGE__->belongs_to( parent => 'Qublog::Schema::Result::Task' );
__PACKAGE__->has_many( children => 'Qublog::Schema::Result::Task', 'parent' );
__PACKAGE__->has_many( journal_entries => 'Qublog::Schema::Result::JournalEntry', 'project' );
__PACKAGE__->has_many( task_logs => 'Qublog::Schema::Result::TaskLog', 'task' );
__PACKAGE__->has_many( task_tags => 'Qublog::Schema::Result::TaskTag', 'task' );
__PACKAGE__->many_to_many( tags => task_tags => 'tag' );
__PACKAGE__->many_to_many( comments => task_logs => 'comment' );
__PACKAGE__->resultset_class('Qublog::Schema::ResultSet::Task');

sub as_journal_item {}

sub list_journal_item_resultsets {
    my ($self, $c) = @_;
    return [ $self->comments ];
}

1;
