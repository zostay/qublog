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

=head1 NAME

Qublog::DateTime - all sorts of date/time related utilities

=head1 DESCRIPTION

Dates and times are fairly important to Qublog, so I've built this little utility library to make sure that Qublog's notions of what a date or time are, are consistent.

=head1 ATTRIBUTES

=head2 sql_formatter

This is the SQL formatter to use for parsing and formatting dates.

=cut

has sql_formatter => (
    is        => 'rw',
    lazy      => 1,
    required  => 1,
    default   => sub { 'DateTime::Format::SQLite' },
);

=head2 last_human_formatter

Stores the previous format object used by this class. Each call to a human parse method will change this, so be careful.

=cut

has last_human_formatter => (
    is        => 'rw',
    isa       => 'DateTime::Format::Natural',
    predicate => 'has_last_human_formatter',
    handles   => {
        human_success => 'success',
        human_error   => 'error',
    },
);

=head1 METHODS

=head2 human_formatter

Sets up the next human formatter to use to parse something. Takes a LDateTime::TimeZone> or time zone name as the single argument.

=cut

sub human_formatter {
    my ($self, $tz) = @_;
    $tz = $tz->name if blessed $tz and $tz->isa('DateTime::TimeZone');

    my $df = DateTime::Format::Natural->new(
        time_zone => $tz,
    );

    $self->last_human_formatter($df);

    return $df;
}

=head2 parse_human_datetime

  my DateTime $datetime = Qublog::DateTime->parse_human_datetime('today', 'UTC');

Given a string to parse and a time zone, parse the string.

=cut

sub parse_human_datetime {
    my ($self, $date_str, $tz) = @_;
    my $df = $self->human_formatter($tz);
    return $df->parse_datetime($date_str);
}

=head2 parse_human_time

  my DateTime $datetime = Qublog::DateTime->parse_human_time(
      '5pm', 'UTC', Qublog::DateTime->today->subtract( weeks => 4 ),
  );

Given a string to parse, a time zone, and a context date (assumed to be today if not given), try to parse a time.

=cut

sub parse_human_time {
    my ($self, $time_str, $tz, $context_date) = @_;
    $context_date ||= DateTime->now( time_zone => $tz );
    my $df = $self->human_formatter($tz);
    return $df->parse_datetime($context_date->ymd . ' ' . $time_str)
        ->set_time_zone($tz);
}

=head2 format_human_date

  my $str = Qublog::DateTime->format_human_date($date, 'UTC');

Given a L<DateTime> and a time zone, format a human readable date.

=cut

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

=head2 format_human_time

  my $str = Qublog::DateTime->format_human_time($datetime, 'UTC');

Given a L<DateTime> and a time zone, format a human readable time. An C<undef> may be passed for the date object and a "blank" time will be output.

=cut

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

=head2 format_js_datetime

  my $str = Qublog::DateTime->format_js_datetime($datetime);

Given a L<DateTime> object, returns a date string that JavaScript can easily parse.

=cut

sub format_js_datetime {
    my ($self, $date) = @_;

    return $date->format_cldr(JS_DATETIME_FORMAT);
}

=head2 parse_sql_datetime

  my DateTime $datetime = Qublog::DateTime->parse_sql_datetime($date_str);

Given a date string returned by the database, convert it to a L<DateTime> object.

=cut

sub parse_sql_datetime {
    my ($self, $str) = @_;
    return $self->sql_formatter->parse_datetime($str);
}

=head2 parse_sql_date

  my DateTime $date = Qublog::DateTime->parse_sql_date($date_str);

Given a date string returned by the database, convert it to a L<DateTime> object.

=cut

sub format_sql_date {
    my ($self, $date) = @_;
    return $self->sql_formatter->format_date($date);
}

=head2 format_sql_datetime

  my $date_str = Qublog::DateTime->format_sql_datetime($datetime);

Given a L<DateTime> object, turn that into a date/time string that the database can understand.

=cut

sub format_sql_datetime {
    my ($self, $date) = @_;
    return $self->sql_formatter->format_datetime($date);
}

=head2 format_precise_datetime

  my $date_str = Qublog::DateTime->format_precise_datetime($datetime);

Intended for debugging and such. Just returne the ISO8601 format of the L<DateTime> object after converting it to UTC.

=cut

sub format_precise_datetime {
    my ($self, $date) = @_;
    return $date->clone->set_time_zone('UTC')->datetime;
}

=head2 now

Return the time as of right now in UTC.

=cut

sub now {
    return DateTime->now( time_zone => 'UTC' );
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 LICENSE

Qublog Personal/Professional Journaling
Copyright (C) 2009  Andrew Sterling Hanenkamp

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
