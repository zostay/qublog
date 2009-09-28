package Qublog::Schema::ResultSet::Task;
use strict;
use warnings;
use base qw( DBIx::Class::ResultSet );

# Make this into configuration
use constant NONE_PROJECT_NAME => 'none';

# sub project_none {
#     my ($self, $c) = @_;
# 
#     my $name = NONE_PROJECT_NAME;
# 
#     my $task = $self->search({
# }

sub find_by_tag_name {
    my ($self, $tag_name) = @_;
    return $self->find({ 
        'task_tags.nickname' => 1, 
        'task_tags.tag.name' => $tag_name 
    }, { join => { task_tags => [ 'tag' ] } });
}

1;
