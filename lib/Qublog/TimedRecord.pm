use strict;
use warnings;

package Qublog::TimedRecord;
use base qw/ Qublog::Record /;

use Jifty::DateTime;

=head1 NAME

Qublog::TimedRecord - A record with a timer associated with it

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

For records that have a C<start_time> and C<stop_time> field. This provides some nice extra features.

=head1 METHODS

=head2 is_running

This returns true if the timer object is currently running. This is the case when C<stop_time> is not set.

=cut

sub is_running {
    my $self = shift;
    return not $self->stop_time;
}

=head2 is_stopped

This returns true if the tiemr object is currently stopped. This is the case when C<stop_time> is set.

=cut

sub is_stopped {
    my $self = shift;
    return $self->stop_time;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
