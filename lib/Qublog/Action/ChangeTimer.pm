use strict;
use warnings;

=head1 NAME

Qublog::Action::ChangeTimer

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

=head2 take_action

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

=cut

sub report_success {
    my $self = shift;
    # Your success message here
    $self->result->message(
        _('Updated %1 time.', $self->argument_value('which'))
    );
}

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

1;

