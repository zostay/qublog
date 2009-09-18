package Qublog::DateTime;
use MooseX::Singleton;

use DateTime;
use DateTime::TimeZone;
use DateTime::Format::Natural;
use DateTime::Format::SQLite;

# Homo Sapiens formats
use constant HS_FULL_DATE_FORMAT  => 'eeee, MMMM d, yyy';
use constant HS_MONTH_DATE_FORMAT => 'eeee, MMMM d';
use constant HS_WEEK_DATE_FORMAT  => 'eeee';
use constant HS_TIME_FORMAT       => 'h:mm a';
use constant HS_DATETIME_FORMAT  => HS_FULL_DATE_FORMAT . ' ' . HS_TIME_FORMAT;

# JavaScript formats
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

has sql_formatter => (
    is        => 'rw',
    lazy      => 1,
    required  => 1,
    default   => sub { 'DateTime::Format::SQLite' },
);

sub parse_human_datetime {
    my ($self, $date_str) = @_;
    my $df = $self->human_formatter;
    return $df->parse_datetime($date_str);
}

sub format_human_date {
    my ($self, $date) = @_;

    my $today = $self->today;
    my $days  = $today->delta_days($date)->delta_days
              * ($today > $date) ? 1 : -1
              ; 

    if (($days < 0 or $days >= 7) and $today->year == $date->year) {
        return $date->format_cldr(HS_MONTH_DATE_FORMAT);
    }
    elsif ($days < 0) {
        return $date->format_cldr(HS_FULL_DATE_FORMAT);
    }
    elsif ($days == 0) {
        return 'Today';
    }
    elsif ($days < 7) {
        return $date->format_cldr(HS_WEEK_DATE_FORMAT);
    }
    else {
        return $date->format_cldr(HS_FULL_DATE_FORMAT);
    }
}

sub format_human_time {
    my ($self, $date) = @_;

    if ($date) {
        return $date->format_cldr(HS_TIME_FORMAT);
    }

    else {
        return '-:--';
    }
}

sub format_js_datetime {
    my ($self, $date) = @_;

    return $date->format_cldr(JS_DATETIME_FORMAT);
}

sub format_sql_date {
    my ($self, $date) = @_;
    return $self->sql_formatter->format_date($date);
}

sub format_sql_datetime {
    my ($self, $date) = @_;
    return $self->sql_formatter->format_datetime($date);
}

sub now {
    return DateTime->now( time_zone => 'UTC' );
}

sub today {
    return DateTime->today( time_zone => 'UTC' );
}

1;
