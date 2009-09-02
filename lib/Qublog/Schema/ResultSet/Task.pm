package Qublog::Schema::ResultSet::Task;
use strict;
use warnings;
use base qw( DBIx::Class::ResultSet );

sub find_by_tag_name {
    my ($self, $tag_name) = @_;
    return $self->find({ 
        'task_tags.nickname' => 1, 
        'tag.name' => $tag_name 
    }, { join => [ 'task_tags', 'tag' ] });
}

1;
