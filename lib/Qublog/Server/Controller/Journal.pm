package Qublog::Server::Controller::Journal;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Qublog::DateTime2;

=head1 NAME

Qublog::Server::Controller::Journal - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 begin

Checks for "form" arguments and stashes that information for later rendering.

=cut

sub begin :Private {
    my ($self, $c) = @_;

    $c->forward('/begin');

    my $form = $c->request->params->{form};
    if ($form) {
        $c->stash->{form}       = $form;
        $c->stash->{form_place} = $c->request->params->{form_place};
        $c->stash->{form_type}  = $c->request->params->{form_type} || 'drawer';

        my $entry_id = $c->request->params->{journal_entry};
        if ($entry_id) {
            my $entry = $c->model('DB::JournalEntry')->find($entry_id);
            $c->stash->{journal_entry} = $entry;
        }

        my $timer_id = $c->request->params->{journal_timer};
        if ($timer_id) {
            my $timer = $c->model('DB::JournalTimer')->find($timer_id);
            $c->stash->{journal_timer} = $timer;
        }

        my $comment_id = $c->request->params->{comment};
        if ($comment_id) {
            my $comment = $c->model('DB::Comment')->find($comment_id);
            $c->stash->{comment}   = $comment;
        }
    }
}

=head2 index

=cut

sub index :Path {
    my ( $self, $c ) = @_;
    $c->forward('/journal/day/today');
}

=head2 goto

=cut

sub goto :Local {
    my ($self, $c) = @_;

    my $date_str = $c->request->params->{date};
    my $date     = Qublog::DateTime->parse_human_datetime($date_str);

    if ($date) {
        $c->response->redirect(
            $c->uri_for('/journal/day', $date_str)
        );
    }

    else {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            field   => 'date',
            message => 'that date could not be understood, try again',
        };

        my $from_page = $c->request->params->{from_page} 
                     || '/journal/day/today';
        $c->response->redirect($c->uri_for($from_page))
    }
}

=head2 day

=cut

sub day :Local :Args(1) {
    my ( $self, $c, $date_str ) = @_;

    my $date = Qublog::DateTime->parse_human_datetime($date_str) 
            || Qublog::DateTime->today;
    my $day  = $c->model('DB')->resultset('JournalDay')->find_by_date($date);

    $c->stash->{title} = 'Journal';
    if (not $day->is_today) {
        $c->stash->{title} .= ' for ';
        $c->stash->{title} .= Qublog::DateTime->format_human_date($day->datestamp);
    }
    $c->stash->{day}      = $day;

    $c->stash->{template} = '/journal/index';
}

=head1 AUTHOR

Andrew Sterling Hanenkamp,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
