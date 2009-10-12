package Qublog::Schema::Result::TaskChange;
use Moose;
extends qw( Qublog::Schema::Result );

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('task_changes');
__PACKAGE__->add_columns(
    id        => { data_type => 'int' },
    task_log  => { data_type => 'int' },
    name      => { data_type => 'text' },
    old_value => { data_type => 'text' },
    new_value => { data_type => 'text' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( task_log => 'Qublog::Schema::Result::TaskLog' );

1;
