package Qublog::Menu;
use Moose;
use Moose::Util::TypeConstraints;

use Scalar::Util qw( blessed );

has url => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_url',
);

has label => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_label',
);

has class => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_class',
);

has sort_order => (
    is        => 'rw',
    isa       => 'Int',
    required  => 1,
    default   => 0,
);

enum ShowWhen => qw( always logged anonymous );
has show_when => (
    is        => 'rw',
    isa       => 'ShowWhen',
    required  => 1,
    default   => 'always',
);

has items => (
    is        => 'rw',
    isa       => 'HashRef[Qublog::Menu]',
    required  => 1,
    default   => sub { {} },
);

sub BUILDARGS {
    my $class = shift;

    my $args;
    if (@_ == 1 and ref $_[0]) {
        $args = $class->_build_from_hash(@_);
    }
    elsif (@_ == 2 and blessed $_[0] and $_[0]->isa('Catalyst')) {
        $args = $class->_build_from_config(@_);
    }
    else {
        my %params = @_;
        $args = $class->_build_from_hash(\%params);
    }

    return $args;
}

sub _build_from_config {
    my ($class, $c, $name) = @_;

    my $menu_config = $c->config->{'Menu'}{$name};
    return $class->new($menu_config);
}

sub _build_from_hash {
    my ($class, $hash) = @_;

    # do not modify the original
    my %args = %$hash;
    $args{items} = {};

    my $items = $hash->{items};
    while (my ($key, $submenu) = each %$items) {
        next if blessed $submenu;

        $args{items}{$key} = Qublog::Menu->new($submenu);
    }

    return \%args;
}

1;
