package Qublog::Schema::Result;
use Moose;

extends qw( DBIx::Class );

sub _dumper_hook { 
    $_[0] = bless { %{ $_[0] }, _source_handle => undef, }, ref($_[0]); 
} 

1;
