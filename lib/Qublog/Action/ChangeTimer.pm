use strict;
use warnings;

=head1 NAME

Qublog::Action::ChangeTimer - change the stop/start time

=head1 SYNOPSIS

  my $timer = Qublog::Model::JournalTimer->new;
  $timer->load($some_id);

  my $change_timer = Jifty->web->new_action(
      class     => 'ChangeTimer',
      record    => $timer,
      arguments => {
          which       => 'start',
          new_time    => '4:42 PM',
          change_date => 0,
      },
  );
  $change_timer->run;

=head1 DESCRIPTION

Updates the start or stop time of a timer.

=head1 PARAMETERS

=head2 which

This is the timer to change, either "start" or "stop".

=head2 new_time

This is the string containing the new time to set the timer to. This can be just about any time format you can think of.

=head2 change_date

This is a boolean/checkbox that allows you to change the date of the timer too. This is an unusual thing to want to do, but sometimes useful. When this is done, a date is expected as well as a time.

=cut

package Qublog::Action::ChangeTimer;
use base qw/Qublog::Action::Record::Delete/;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param which =>
        render as 'hidden',
        valid_values are qw/ start stop /,
        is mandatory,
        ;

    param new_time =>
        render as 'text',
        label is 'New time',
        is mandatory,
        ;

    param change_date =>
        render as 'checkbox',
        label is 'Change date too?',
        is mandatory,
        default is 0,
        ;
};

use Hash::Merge qw/ merge /;

sub record_class { 'Qublog::Model::JournalTimer' }

sub arguments {
    my $self = shift;
    return merge( $self->SUPER::arguments, $self->PARAMS );
}

sub _compute_new_time {
    my ($self, $new_time) = @_;

    if (not $self->argument_value('change_date')) {
        my $old_time = $self->argument_value('which') eq 'start' 
                                                    ? $self->record->start_time
                     :                                $self->record->stop_time
                     ;

        $new_time = $old_time->ymd.' '.$new_time;
    }

    return Jifty::DateTime->new_from_string($new_time);
}

=head1 METHODS

=head2 take_action

Performs the work of changing the start or stop time of the timer.

=cut

sub take_action {
    my $self = shift;
    
    my $new_time = $self->argument_value('new_time');
    my $datetime = $self->_compute_new_time($new_time);

    my $which = $self->argument_value('which');
    if ($which eq 'start') {
        $self->record->set_start_time($datetime);
    }
    else {
        $self->record->set_stop_time($datetime);
    }
    
    $self->report_success if not $self->result->failure;
    
    return 1;
}

=head2 report_success

Shows one of the following messages on success:

  Updated start time.
  Updated stop time.

=cut

sub report_success {
    my $self = shift;
    # Your success message here
    $self->result->message(
        _('Updated %1 time.', $self->argument_value('which'))
    );
}

=head2 validate_new_time

This is a validator that makes sure that the given time is in a valid format. If not, it will make suggestions on what kind of time/date formats to try.

=cut

sub validate_new_time {
    my ($self, $value) = @_;

    my $datetime = $self->_compute_new_time($value);
    if (not defined $datetime) {
        my $date_too = $self->argument_value('change_date');
        my $message  = $date_too ?  _('That does not look like a date.')
                     :              _('That does not look like a time. '
                                     .'Should be like "15:45" or "8:30pm".')
                     ;

        return $self->validation_error(new_time => $message);
    }

    my $which = $self->argument_value('which');
    if ($which eq 'start') {
        return $self->validation_error(
            _('New time cannot come after stop time.')
        ) if defined $self->record->stop_time 
         and $datetime > $self->record->stop_time;
    }

    else {
        return $self->validation_error(
            _('New time cannto come before start time.')
        ) if $datetime < $self->record->start_time;
    }

    return $self->validation_ok('new_time');
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< hanenkamp@cpan.org >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;

