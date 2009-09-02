package Qublog::Schema::Result::Task;
use strict;
use warnings;
use base qw( DBIx::Class );

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('tasks');
__PACKAGE__->add_columns(
    id             => { data_type => 'int' },
    task_type      => { data_type => 'text' },
    child_handling => { data_type => 'text' },
    status         => { data_type => 'text' },
    created_on     => { data_type => 'datetime' },
    completed_on   => { data_type => 'datetime' },
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
__PACKAGE__->resultset_class('Qublog::Schema::ResultSet::Task');

1;
