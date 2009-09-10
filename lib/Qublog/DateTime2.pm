package Qublog::DateTime;
use MooseX::Singleton;

use DateTime;
use DateTime::TimeZone;
use DateTime::Format::Natural;

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

sub now {
    return DateTime->now;
}

sub today {
    return DateTime->today;
}

1;
