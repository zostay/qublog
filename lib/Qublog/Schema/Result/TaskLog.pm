package Qublog::Schema::Result::TaskLog;
use strict;
use warnings;
use base qw( DBIx::Class );

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('task_logs');
__PACKAGE__->add_columns(
    id         => { data_type => 'int' },
    task       => { data_type => 'int' },
    log_type   => { data_type => 'text' },
    created_on => { data_type => 'datetime' },
    comment    => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( task => 'Qublog::Schema::Result::Task' );
__PACKAGE__->belongs_to( comment => 'Qublog::Schema::Result::Comment' );
__PACKAGE__->has_many( task_changes => 'Qublog::Schema::Result::TaskChange', 'task_log' );

1;
