package Qublog::Dumper;
use Moose;

use Scalar::Util qw( blessed );

extends qw( Data::Dumper Moose::Object );

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
            return $self->SUPER::_dump($val, $name);
        }
    }

    return $self->SUPER::_dump($val, $name);
}

sub Dump {
    my $class = shift;
    $class->Useperl(1);
    $class->SUPER::Dump(@_);
}

sub Dumper {
    return __PACKAGE__->Dump([@_]);
}

1;
