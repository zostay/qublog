use strict;
use warnings;

package Qublog::Dispatcher;
use Jifty::Dispatcher -base;

use Jifty::DateTime;

=head1 NAME

Qublog::Dispatcher - request dispatcher for the application

=head1 RULES

=head2 before **

Makes sure the L<Qublog::Action::GoToDate> action is allowed and updates the navigation.

=cut

before '**' => run {
    # Configure the navigation menu
    my $top = Jifty->web->navigation;

    $top->child( Home   => url        => '/journal',
                           label      => 'Journal',
                           sort_order => 0 );

    if (Jifty->web->current_user->id) {
        $top->child( Tasks    => url        => '/project',
                                 sort_order => 10 );
        $top->child( Tags     => url        => '/tag',
                                 sort_order => 20 );
    }

    else {
        $top->child( Register => url        => '/user/register',
                                 sort_order => 10 );
    }

    # Allow some actions
    Jifty->api->allow('GoToDate'); 
};

=head2 on **

Makes sure there's a registered user available and starts the login process if
login is required.

=cut

on '**' => run {
    my $path = $1;
    next_rule if $path =~ m[^user/];

    my $users = Qublog::Model::UserCollection->new;
    $users->unlimit;
    if ($users->count_all == 0) {
        tangent '/user/register';
    }

    my $current_user = Jifty->web->current_user;
    if (not $current_user->id) {
        tangent '/user/login';
    }
};

=head2 on ''

=head2 on index

=head2 on index.html

Redispatches to C<journal>.

=cut

on [ '', 'index', 'index.html' ] => dispatch 'journal';

=head2 on journal

=head2 on journal/list

=head2 on journal/new_comment_entry

=head2 on journal/summary

Parses the C<date> request parameter to load the requested L<Qublog::Model::JournalDay> object. This will default to today if no such parameter has been set.

=cut

sub parse_date {
    my $str_date = get 'date';

    my $date;
    if ($str_date) {
        $date = Jifty::DateTime->new_from_string($str_date);

        if (!$date) {
            Jifty->web->response->error(
                _(qq{Could not understand "$str_date".\n}));
            abort 500;
        }
    }

    else {
        $date = Jifty::DateTime->today;
    }

    my $day = Qublog::Model::JournalDay->new;
    $day->for_date( $date );

    set date => $date;
    set day  => $day;
}

on 'journal'                   => \&parse_date;
on 'journal/list'              => \&parse_date;
on 'journal/new_comment_entry' => \&parse_date;
on 'journal/summary'           => \&parse_date;

=head2 on journal/popup/edit_comment

Loads the L<Qublog::Model::Comment> object needed to handle the request.

=cut

on 'journal/popup/edit_comment' => run {
    my $comment_id = get 'comment_id';
    if ($comment_id) {
        my $comment = Qublog::Model::Comment->new;
        $comment->load($comment_id);

        set comment => $comment;
    }
};

=head2 on journal/popup/edit_entry

=head2 on journal/popup/change_start_stop

=head2 on journal/popup/show_tasks

Loads the L<Qublog::Model::JournalEntry> and L<Qublog::Model::JournalTimer> object needed to handle the request.

=cut

sub load_entry {
    my $entry_id = get 'entry_id';
    if ($entry_id) {
        my $entry = Qublog::Model::JournalEntry->new;
        $entry->load($entry_id);

        set entry => $entry;
    }

    my $timer_id = get 'timer_id';
    if ($timer_id) {
        my $timer = Qublog::Model::JournalTimer->new;
        $timer->load($timer_id);

        set timer => $timer;
    }
}

on 'journal/popup/edit_entry'        => \&load_entry;
on 'journal/popup/change_start_stop' => \&load_entry;
on 'journal/popup/show_tasks'        => \&load_entry;

=head2 on journal/thingy_button

Ajax helper to see what the button should read for a given value of C<task_entry>. See L<Qublog::Action::CreateJournalThingy>.

=cut

on 'journal/thingy_button' => run {
    Jifty->web->response->add_header('Content-type' => 'text/plain');

    my $create_thingy = Jifty->web->new_action(
        class     => 'CreateJournalThingy',
        arguments => {
            task_entry => get 'task_entry',
        },
    );
    Jifty->web->out($create_thingy->thingy_button);

    last_rule;
};

=head2 on project/edit/*

Loads the L<Qublog::Model::Task> named by the wildcard parameter.

=cut

on 'project/edit/*' => run {
    my $nickname = $1;

    my $task = Qublog::Model::Task->new;
    $task->load_by_tag_name($nickname);

    last_rule unless $task->id;

    set task => $task;
    show 'project/view';
};

=head2 on tag/view/*

Loads the L<Qublog::Model::Tag> named by the wildcard parameter.

=cut

on 'tag/view/*' => run {
    my $nickname = $1;

    my $tag = Qublog::Model::Tag->new;
    $tag->load_by_cols( name => $nickname );

    set tag_name => $nickname;
    set tag      => $tag;
    show 'tag/view';
};

=head2 on logout

Logout.

=cut

on 'logout' => run {
    my $logout = Jifty->web->new_action('Logout');
    $logout->run;

    redirect '/';
};

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
