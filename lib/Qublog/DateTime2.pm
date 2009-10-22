package Qublog::DateTime;
use MooseX::Singleton;

use DateTime;
use DateTime::TimeZone;
use DateTime::Format::Natural;
use DateTime::Format::SQLite;
use Scalar::Util qw( blessed );

# Homo Sapiens formats
use constant HS_FULL_DATE_FORMAT  => 'eeee, MMMM d, yyy';
use constant HS_MONTH_DATE_FORMAT => 'eeee, MMMM d';
use constant HS_WEEK_DATE_FORMAT  => 'eeee';
use constant HS_TIME_FORMAT       => 'h:mm a';
use constant HS_DATETIME_FORMAT  => HS_FULL_DATE_FORMAT . ' ' . HS_TIME_FORMAT;

# JavaScript formats
use constant JS_DATETIME_FORMAT => 'eee MMM dd HH:mm:ss zzz yyy';

has sql_formatter => (
    is        => 'rw',
    lazy      => 1,
    required  => 1,
    default   => sub { 'DateTime::Format::SQLite' },
);

has last_human_formatter => (
    is        => 'rw',
    isa       => 'DateTime::Format::Natural',
    predicate => 'has_last_human_formatter',
    handles   => {
        human_success => 'success',
        human_error   => 'error',
    },
);

sub human_formatter {
    my ($self, $tz) = @_;
    $tz = $tz->name if blessed $tz and $tz->isa('DateTime::TimeZone');

    my $df = DateTime::Format::Natural->new(
        time_zone => $tz,
    );

    $self->last_human_formatter($df);

    return $df;
}

sub parse_human_datetime {
    my ($self, $date_str, $tz) = @_;
    my $df = $self->human_formatter($tz);
    return $df->parse_datetime($date_str);
}

sub parse_human_time {
    my ($self, $time_str, $tz, $context_date) = @_;
    $context_date ||= DateTime->now( time_zone => $tz );
    my $df = $self->human_formatter($tz);
    return $df->parse_datetime($context_date->ymd . ' ' . $time_str)
        ->set_time_zone($tz);
}

sub format_human_date {
    my ($self, $date, $tz) = @_;
    $date = $date->clone->set_time_zone( $tz );

    my $today = DateTime->now( time_zone => $tz );
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
    my ($self, $date, $tz) = @_;

    if ($date) {
        $date = $date->clone->set_time_zone($tz);
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

sub parse_sql_datetime {
    my ($self, $str) = @_;
    return $self->sql_formatter->parse_datetime($str);
}

sub format_sql_date {
    my ($self, $date) = @_;
    return $self->sql_formatter->format_date($date);
}

sub format_sql_datetime {
    my ($self, $date) = @_;
    return $self->sql_formatter->format_datetime($date);
}

sub format_precise_datetime {
    my ($self, $date) = @_;
    return $date->clone->set_time_zone('UTC')->datetime;
}

sub now {
    return DateTime->now( time_zone => 'UTC' );
}

1;
