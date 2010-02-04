package Qublog::Types;
use Moose;

use Qublog::DateTime;
use DateTime::TimeZone;

use Moose::Util::TypeConstraints;

class_type('DateTime::TimeZone');

coerce 'DateTime::TimeZone'
    => from 'Str'
    => via { DateTime::TimeZone->new( name => $_ ) };

subtype 'DateTime::Date' => as class_type('DateTime');

coerce 'DateTime::Date'
    => from 'Str'
    => via { Qublog::DateTime->parse_human_date($_, 'floating') };

subtype 'DateTime::DateTime' => as class_type('DateTime');

coerce 'DateTime::DateTime'
    => from 'Str'
    => via { Qublog::DateTime->parse_human_datetime($_, 'floating') };

no Moose::Util::TypeConstraints;
