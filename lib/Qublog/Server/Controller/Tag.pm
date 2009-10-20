package Qublog::Server::Controller::Tag;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Qublog::Server::Controller::Tag - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my @resultsets;

    my $user_id = $c->user->get_object->id;
#    my $six_weeks_ago = Qublog::DateTime->format_sql_datetime(
#        Qublog::DateTime->now->subtract( weeks => 6 )
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
    my $now = Qublog::DateTime->now;
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

=head1 AUTHOR

Andrew Sterling Hanenkamp,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
