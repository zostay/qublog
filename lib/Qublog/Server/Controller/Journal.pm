package Qublog::Server::Controller::Journal;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Qublog::DateTime;

=head1 NAME

Qublog::Server::Controller::Journal - Main journal controller

=head1 DESCRIPTION

This is the main controller of Qublog.

=head1 METHODS

=head2 begin

Checks to make sure the user is logged. Checks for "form" arguments and stashes
that information for later rendering.

=cut

sub begin :Private {
    my ($self, $c) = @_;

    $c->forward('/user/check');

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

Shows the journal for today.

=cut

sub index :Path {
    my ( $self, $c ) = @_;
    $c->forward('/journal/day', [ 'today' ]);
}

=head2 goto

Loads a journal for the given date. This is used by the Go box in the upper
right corner of the journal.

=cut

sub goto :Local {
    my ($self, $c) = @_;

    my $action = $c->action_form(server => 'GotoJournalDate');
    $action->unstash('journal-goto');

    $action->consume_and_clean_and_check_and_process( request => $c->request );

    $c->result_to_messages($action->results);

    return if $action->is_valid and $action->is_success;

    $action->stash('journal-goto');

    my $from_page = $action->globals->{from_page} 
                    || '/journal/day/today';
    $c->response->redirect($from_page)
}

=head2 day

This loads a journal for the named day or today if none is given.

=cut

sub day :Local :Args(1) {
    my ( $self, $c, $date_str ) = @_;

    my $date = Qublog::DateTime->parse_human_datetime($date_str, $c->time_zone) 
            || $c->today;
    my $sessions = $c->model('DB::JournalSession')->search_by_day($date);

    $c->stash->{day}      = $date;
    $c->stash->{sessions} = $sessions;

    $c->stash->{template} = '/journal/index';
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
