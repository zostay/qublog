package Qublog::Schema::ResultSet::Task;
use Moose;
extends qw( Qublog::Schema::ResultSet );

# Make this into configuration
use constant NONE_PROJECT_NAME => 'none';

=head1 NAME

Qublog::Schema::ResultSet::Task - result set helpers for tasks

=head1 DESCRIPTION

Fancy task searching.

=head1 METHODS

=head2 project_none

Find or create the "none" project for the user and return it.

=cut

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

=head2 find_by_tag_name

Find the task matching the given tag name.

=cut

sub find_by_tag_name {
    my ($self, $tag_name) = @_;
    return $self->find({ 
        'task_tags.nickname' => 1, 
        'task_tags.tag.name' => $tag_name 
    }, { join => { task_tags => [ 'tag' ] } });
}

=head2 search_current

Find all tasks that are currently open, or recently done. You need to pass a L<Qublog::Schema::Result::User> object to specify the owner.

=cut

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

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 LICENSE

Qublog Personal/Professional Journaling
Copyright (C) 2009  Andrew Sterling Hanenkamp

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
