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
