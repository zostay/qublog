package Qublog::Form::Processor;
use Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_meta => [ 'has_control', 'clean', 'check', ],
    also      => 'Moose',
);

sub init_meta {
    my $package = shift;
    my %options = @_;

    Moose->init_meta(%options);

    my $meta = Moose::util::MetaRole::apply_metaclass_roles(
        for_class       => $options{for_class},
        metaclass_roles => [ 'Qublog::Form::Action::Meta::Class' ],
    );

    Moose::Util::apply_all_roles(
        $options{for_class}, 'Qublog::Form::Action',
    );

    return $meta;
}

sub has_control {
    my $meta = shift;
    my $name = shift;
    my $args = @_ == 1 ? $args : { @_ };

    $args->{is}       ||= 'ro';
    $args->{isa}      ||= 'Str';

    $args->{control}  ||= 'text';
    $args->{options}  ||= {};
    $args->{features} ||= {};
    $args->{traits}   ||= []

    unshift @{ $args->{traits} }, 'Form::Control';

    $meta->add_attribute( $name => $args );
}

sub clean {
    my ($meta, $name, $code) = @_;

    push @{ $meta->cleaners }, {
        name => $name,
        code => $code,
    );
}

sub check {
    my ($meta, $name, $code) = @_;

    push @{ $meta->checkers }, {
        name => $name,
        code => $code,
    };
}

1;
