use strict;
use warnings;

package Qublog::TimedCollection;
use base qw/ Qublog::Collection /;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    $self->order_by({ column => 'start_time', order => 'DES' });

    return $self;
}

sub _fix_tz {
    my ($self, $date) = @_;

    $date->set_time_zone( $self->current_user->user_object->time_zone );
    $date->set_time_zone( 'UTC' );
}

sub limit_by_day {
    my ($self, $date) = @_;

    my $start_date = $date->clone->truncate( to => 'day' );
    my $end_date   = $start_date->clone->add( days => 1 );

    # XXX Hackery around Jifty::DateTime's policy regarding floating TZ and
    # dates truncated to day
    $self->_fix_tz($start_date);
    $self->_fix_tz($end_date);

    $self->open_paren('by_day');

    $self->open_paren('by_day');

    $self->limit(
        column    => 'stop_time',
        operator  => '>=',
        value     => $start_date->format_cldr('YYYY-MM-dd HH:mm:ss'),
        subclause => 'by_day',
        entry_aggregator => 'AND',
    );

    $self->limit(
        column    => 'stop_time',
        operator  => '<=',
        value     => $end_date->format_cldr('YYYY-MM-dd HH:mm:ss'),
        subclause => 'by_day',
        entry_aggregator => 'AND',
    );

    $self->close_paren('by_day');

    $self->limit(
        column    => 'stop_time',
        operator  => 'IS',
        value     => 'NULL',
        subclause => 'by_day',
        entry_aggregator => 'OR',
    );


    $self->close_paren('by_day');

    return $self;
}

sub limit_by_running {
    my $self = shift;
    my $running = shift || 1;

    $self->limit(
        column   => 'stop_time',
        operator => ($running ? 'IS' : 'IS NOT'),
        value    => 'NULL',
    );

    return $self;
}

1;
