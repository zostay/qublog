package Qublog::Form::Processor;
use Moose;
use Moose::Exporter;

use Qublog::Form::Action;
use Qublog::Form::Action::Meta::Class;
use Qublog::Form::Action::Meta::Attribute::Control;
use Qublog::Form::Processor::DeferredValue;

Moose::Exporter->setup_import_methods(
    as_is     => [ qw( deferred_value ) ],
    with_meta => [ qw(
        has_control
        clean check pre_process post_process
    ) ],
    also      => 'Moose',
);

sub init_meta {
    my $package = shift;
    my %options = @_;

    Moose->init_meta(%options);

    my $meta = Moose::Util::MetaRole::apply_metaclass_roles(
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
    my $args = @_ == 1 ? shift : { @_ };

    $args->{is}       ||= 'ro';
    $args->{isa}      ||= 'Str';

    $args->{control}  ||= 'text';
    $args->{options}  ||= {};
    $args->{features} ||= {};
    $args->{traits}   ||= [];

    for my $value (values %{ $args->{features} }) {
        $value = {} unless ref $value;
    }

    unshift @{ $args->{traits} }, 'Form::Control';

    $meta->add_attribute( $name => $args );
}

sub deferred_value(&) {
    my $code = shift;

    return Qublog::Form::Processor::DeferredValue->new(
        code => $code,
    );
}

sub _add_feature {
    my ($type, $meta, $name, $code) = @_;
    push @{ $meta->features }, {
        name            => $name,
        $type . '_code' => $code,
    };
}

sub clean        { _add_feature('cleaner', @_) }
sub check        { _add_feature('checker', @_) }
sub pre_process  { _add_feature('pre_processor', @_) }
sub post_process { _add_feature('post_processor', @_) }

1;
