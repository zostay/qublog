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
    created_on => { data_type => 'datetime', timezone => 'UTC' },
    comment    => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( task => 'Qublog::Schema::Result::Task' );
__PACKAGE__->belongs_to( comment => 'Qublog::Schema::Result::Comment' );
__PACKAGE__->has_many( task_changes => 'Qublog::Schema::Result::TaskChange', 'task_log' );

sub fill_related_to {
    my ($self, $log_type, $task) = @_;
    $self->log_type($log_type);
    $self->task($task);
    $self->comment($task->latest_comment);
    return $self;
}

1;
