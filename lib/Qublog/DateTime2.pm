package Qublog::DateTime;
use MooseX::Singleton;

use DateTime;
use DateTime::TimeZone;
use DateTime::Format::Natural;

use constant JS_DATETIME_FORMAT => 'eee MMM dd HH:mm:ss zzz yyy';

has human_formatter => (
    is        => 'rw',
    lazy      => 1,
    required  => 1,
    default   => sub {
        DateTime::Format::Natural->new( 
            time_zone => 'UTC' 
        ),
    },
);

sub parse_human_datetime {
    my ($self, $date_str) = @_;
    my $df = $self->human_formatter;
    return $df->parse_datetime($date_str);
}

sub format_human_date {
    my ($self, $date) = @_;

    # TODO Make smarter. Dis id reel dumm.
    return $date->ymd;
}

sub format_human_time {
    my ($self, $date) = @_;

    # TODO Make smarter. DIs id reel dumm.
    return $date->hms;
}

sub format_js_datetime {
    my ($self, $date) = @_;

    return $date->format_cldr(JS_DATETIME_FORMAT);
}

sub now {
    return DateTime->now( time_zone => 'UTC' );
}

sub today {
    return DateTime->today( time_zone => 'UTC' );
}

1;
