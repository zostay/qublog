package Qublog::Server::Controller::Compat;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Qublog::Server::Controller::Compat - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 comment/delete

Delete a comment.

=cut

sub delete_comment :Path('comment/delete') :Args(1) {
    my ($self, $c, $comment_id) = @_;

    my $comment = $c->model('DB::Comment')->find($comment_id);
    if (!$comment) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Unable to delete that comment.',
        };
        
        return $c->detach('return');
    }

    if ($comment->owner->id != $c->user->get_object->id) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'You may not delete that comment.',
        };
    }

    $comment->delete;
    $c->detach('return');
}

=head2 timer/stop

Stop the running timer.

=cut

sub stop_timer :Path('timer/stop') :Args(1) {
    my ($self, $c, $entry_id) = @_;

    my $entry = $c->model('DB::JournalEntry')->find($entry_id);
    if (!$entry) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Unable to stop that timer.',
        };
        
        return $c->detach('return');
    }

    if ($entry->owner->id != $c->user->get_object->id) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'You may not stop that timer.',
        };
    }

    $entry->stop_timer;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => sprintf('Stopped the timer for %s', $entry->name),
    };

    $c->detach('return');
}

=head2 timer/start

Stop the running timer.

=cut

sub start_timer :Path('timer/start') :Args(1) {
    my ($self, $c, $entry_id) = @_;

    my $entry = $c->model('DB::JournalEntry')->find($entry_id);
    if (!$entry) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Unable to start that timer.',
        };
        
        return $c->detach('return');
    }

    if ($entry->owner->id != $c->user->get_object->id) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'You may not start that timer.',
        };
    }

    $entry->start_timer;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => sprintf('Started the timer for %s', $entry->name),
    };

    $c->detach('return');
}

=head2 return

Private routine to redirect according to the C<return_to> parameter. Without that parameter, defaults to the main journal page.

=cut

sub return :Private {
    my ($self, $c) = @_;
    my $return_to = $c->request->params->{return_to};
    $return_to  ||= $c->uri_for('/journal');
    $c->response->redirect($c->request->params->{return_to});
}

=head1 AUTHOR

Andrew Sterling Hanenkamp,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
