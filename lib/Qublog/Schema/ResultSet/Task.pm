package Qublog::Schema::ResultSet::Task;
use Moose;
extends qw( Qublog::Schema::ResultSet );

# Make this into configuration
use constant NONE_PROJECT_NAME => 'none';

sub project_none {
    my $self = shift;

    my $name = NONE_PROJECT_NAME;

    my $task = $self->find({
        name   => NONE_PROJECT_NAME,
        status => 'open',
    });

    return $task if $task;

    return $self->create({
        name    => NONE_PROJECT_NAME,
        project => 0,
    });
}

sub find_by_tag_name {
    my ($self, $tag_name) = @_;
    return $self->find({ 
        'task_tags.nickname' => 1, 
        'task_tags.tag.name' => $tag_name 
    }, { join => { task_tags => [ 'tag' ] } });
}

sub search_current {
    my ($self, $owner) = @_;

    # TODO This is very SQLite specific at the moment
    return $self->search({
        owner => $owner->id,
        -nest => [
            -and => [
                completed_on => { '>=', \"DATETIME('now','-1 hour')" },
                status       => 'done',
            ],
            -and => [
                status       => 'open',
            ],
        ],
    });
}

1;
