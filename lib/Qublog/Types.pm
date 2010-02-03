package Qublog::Types;
use Moose;

use Qublog::DateTime;

use Moose::Util::TypeConstraints;

subtype 'Qublog::DateTime::TimeZone' => as class_type('DateTime::TimeZone');

coerce 'Qublog::DateTime::TimeZone'
    => from 'Str'
    => via { DateTime::TimeZone->new( name => $_ ) };

subtype 'Qublog::Date' => as class_type('DateTime');

coerce 'Qublog::Date'
    => from 'Str'
    => via { Qublog::DateTime->parse_human_date($_, 'UTC') };

subtype 'Qublog::Datetime' => as class_type('DateTime');

coerce 'Qublog::Datetime'
    => from 'Str'
    => via { Qublog::DateTime->parse_human_datetime($_, 'UTC') };

no Moose::Util::TypeConstraints;
