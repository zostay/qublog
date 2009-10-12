package Qublog::Schema::Result::TaskTag;
use Moose;
extends qw( Qublog::Schema::Result );

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('task_tags');
__PACKAGE__->add_columns(
    id       => { data_type => 'int' },
    task     => { data_type => 'int' },
    tag      => { data_type => 'int' },
    sticky   => { data_type => 'boolean' },
    nickname => { data_type => 'boolean' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( task => 'Qublog::Schema::Result::Task' );
__PACKAGE__->belongs_to( tag => 'Qublog::Schema::Result::Tag' );

sub new {
    my ($class, $attrs) = @_;

    $attrs->{sticky}   = 0 unless defined $attrs->{sticky};
    $attrs->{nickname} = 0 unless defined $attrs->{nickname};

    return $class->next::method($attrs);
}

1;
