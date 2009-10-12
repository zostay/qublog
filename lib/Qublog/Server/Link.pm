package Qublog::Server::Link;
use Moose;

use Moose::Util::TypeConstraints;

enum 'Qublog::Server::Link::LinkType' => qw( script style );

no Moose::Util::TypeConstraints;

has type => (
    is       => 'ro',
    isa      => 'Qublog::Server::Link::LinkType',
    required => 1,
);

has code => (
    is       => 'ro',
    isa      => 'Str',
    predicate => 'is_source',
);

has file => (
    is       => 'ro',
    isa      => 'Str',
    predicate => 'is_file',
);

sub file_type {
    my $self = shift;

    return {
        script => 'js',
        style  => 'css',
    }->{ $self->type };
}

sub path {
    my $self = shift;
    return unless $self->is_file;
    return '/static/' . $self->type . '/' 
        . $self->file . '.' . $self->file_type;
}

no Moose;

1;