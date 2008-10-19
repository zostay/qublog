use strict;
use warnings;

package Qublog::Mixin::Action::CommentParser;

require Exporter;
our @ISA = qw/ Exporter /;

our @EXPORT = qw/ parse_comment_and_take_actions journal_timer /;

use Qublog::Util::CommentParser;
use Scalar::Util qw/ looks_like_number reftype /;

=head1 NAME

Qublog::Mixin::Action::CommentParser - Helper to link comments to tasks

=head1 DESCRIPTION

At this time, this class is only built for use with L<Qublog::Action::CreateComment> and L<Qublog::Action::UpdateComment>. So, unless you're modifying these, this is not very important.

This class provides the glue between L<Qublog::Util::CommentParser>, which is a more general purpose utility, and L<Qublog::Model::Comment> and L<Qublog::Model::Task>. It creates and modifies the L<Qublog::Model::TaskLog> links to make sure a new comment is attached as appropriate.

=head1 METHODS

=head2 journal_timer

This method looks at the incoming requests and makes a best effort to determine what L<Qublog::Model::JournalTimer> object should be associated with the comment.

On failure, it returns a dead L<Qublog::Model::JournalTimer> object.

=cut

sub journal_timer {
    my $self = shift;
    
    # Try from a given parameter first
    my $journal_timer_id = $self->argument_value('journal_timer');
    if (looks_like_number $journal_timer_id) {
        my $journal_timer = Qublog::Model::JournalTimer->new;
        $journal_timer->load( $journal_timer_id );
        return $journal_timer if $journal_timer->id;
    }

    # Failing that, check to see if we have a current record
    if ($self->record->id) {
        return $self->record->journal_timer;
    }

    # Otherwise, we don't have one; return a dead one
    return Qublog::Model::JournalTimer->new;
}

=head2 parse_comment_and_take_actions

This performs the actual work of linking the comment to the current timer/entry project and attaching it to the various tasks that are referenced in the comment.

=cut

sub parse_comment_and_take_actions {
    my $self    = shift;

    # Load a project if we can; might be a dead object
    my $project = $self->journal_timer->journal_entry->project;

    # Use the CommentParser to break the comment up
    my $unparsed_comment = $self->argument_value('name');
    my $parser = Qublog::Util::CommentParser->new( 
        project => $project,
        comment => $unparsed_comment,
    );
    $parser->parse;

    # Update the comment with the extra bits stripped
    $self->argument_value( name => $parser->comment );

    # Create the comment
    my $caller = caller 0;
    my $take_action = $caller . '::SUPER::take_action';
    $self->$take_action();

    # Link the project to the comment
    if ($project->id) {
        my $task_log = Qublog::Model::TaskLog->new;
        $task_log->create(
            task     => $project,
            log_type => 'note',
            comment  => $self->record,
        );
    }

    # Handle any tasks that were included in the original comment
    for my $task ($parser->created_tasks) {

        # Find the latest task log (just created) and link to it
        my $task_logs = $task->task_logs;
        $task_logs->limit( column => 'log_type', value => 'create' );
        $task_logs->order_by({ column => 'created_on', order => 'des' });
        my $task_log = $task_logs->first;
        $task_log->set_comment( $self->record );
    }

    for my $task ($parser->updated_tasks) {

        # Find the latest task log (just created) and link to it
        my $task_logs = $task->task_logs;
        $task_logs->limit( column => 'log_type', value => 'update' );
        $task_logs->order_by({ column => 'created_on', order => 'des' });
        my $task_log = $task_logs->first;
        $task_log->set_comment( $self->record );
    }

    for my $task ($parser->linked_tasks) {
        my $task_log = Qublog::Model::TaskLog->new;
        $task_log->create(
            task     => $task,
            log_type => 'note',
            comment  => $self->record,
        );
    }
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;