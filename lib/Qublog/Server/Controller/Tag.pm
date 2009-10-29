package Qublog::Server::Controller::Tag;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Qublog::Server::Controller::Tag - Tag page

=head1 DESCRIPTION

Tags help to categorize information in Qublog, though not very well yet. This
controller handlers showing information about tags.

=head1 METHODS

=head2 begin

Check for login.

=cut

sub begin :Private {
    my ($self, $c) = @_;
    $self->forward('/user/login');
}

=head2 index

Show a tag cloud for the user's tags.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my @resultsets;

    my $user_id = $c->user->get_object->id;
#    my $six_weeks_ago = Qublog::DateTime->format_sql_datetime(
#        $c->now->subtract( weeks => 6 )
#    );

    push @resultsets, $c->model('DB::Tag')->search_rs({
        'comment.owner' => $user_id,
#        'comment.created_on' => { '>', $six_weeks_ago },
    }, {
        join   => { 'comment_tags' => 'comment' },
        select => [ 'me.name', 'comment.created_on' ],
        as     => [ 'name', 'timestamp' ],
    });
    push @resultsets, $c->model('DB::Tag')->search_rs({
        'journal_entry.owner'      => $user_id,
#        'journal_entry.start_time' => { '>', $six_weeks_ago },
    }, {
        join   => { 'journal_entry_tags' => 'journal_entry' },
        select => [ 'me.name', 'journal_entry.start_time' ],
        as     => [ 'name', 'timestamp' ],
    });
    push @resultsets, $c->model('DB::Tag')->search_rs({
        'task.owner'      => $user_id,
#        'task.created_on' => { '>', $six_weeks_ago },
    }, {
        join   => { 'task_tags' => 'task' },
        select => [ 'me.name', 'task.created_on' ],
        as     => [ 'name', 'timestamp' ],
    });

    my %tags;
    my $max_total = 1;
    my $min_total = 4_000_000_000;
    my $now = $c->now;
    for my $tag_dates (@resultsets) {
        while (my $tag_date = $tag_dates->next) {
            my $name = $tag_date->name;
            my $dt   = Qublog::DateTime->parse_sql_datetime(
                $tag_date->get_column('timestamp')
            );

            my $months = ($now->epoch - $dt->epoch) / 2_592_000;

            $tags{ $name } += 2.5 / (log(0.25 * $months + 1.5)) - 1;

            $max_total = $tags{ $name } if $tags{ $name } > $max_total;
            $min_total = $tags{ $name } if $tags{ $name } < $min_total;
        }
    }

    $c->stash->{tags}      = \%tags;
    $c->stash->{max_score} = $max_total;
    $c->stash->{min_score} = $min_total;

    $c->stash->{template}  = '/tag/index';
}

=head2 view

Show all the things related to a particular tag.

=cut

sub view :Local :Args(1) {
    my ($self, $c, $tag_name) = @_;

    my $tag = $c->model('DB::Tag')->find({ name => $tag_name });
    $c->detach('default') unless $tag;

    $c->stash->{tag}      = $tag;
    $c->stash->{template} = '/tag/view';
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
