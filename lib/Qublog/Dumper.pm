package Qublog::Dumper;
use Moose;

use Scalar::Util qw( blessed );

extends qw( Data::Dumper Moose::Object );
$Data::Dumper::Useperl = 1;

our @EXPORT = qw( Dumper );

sub _dump {
    my ($self, $val, $name) = @_;

    if (blessed $val) {
        $val->can('pp_dump')  and return $val->pp_dump;

        $val->isa('DateTime') and return 'DateTime: '.$val;
        $val->isa('DateTime::TimeZone') and return 'TimeZone: '.$val->name;

        if ($val->isa('Qublog::Schema::Result')) {
            local $val->{_source_handle} = undef;
            return $self->SUPER::_dump($val, $name);
        }

        if ($val->isa('Qublog::Schema')) {
            local $val->{storage}              = ''.$val->{storage};
            local $val->{source_registrations} = ''.$val->{source_registrations};
            local $val->{class_mappings}       = ''.$val->{class_mappings};
            return $self->SUPER::_dump($val, $name);
        }
    }

    return $self->SUPER::_dump($val, $name);
}

sub Dump {
    my $class = shift;
    $class->SUPER::Dump(@_);
}

sub Dumper {
    return __PACKAGE__->Dump([@_]);
}

1;
