package Qublog::Form::Action;
use Moose::Role;

use Qublog::Form::Feature::Functional;
use Qublog::Util qw( class_name_from_name );

requires qw( run );

has form_factory => (
    is        => 'ro',
    does      => 'Qublog::Form::Factory',
    required  => 1,
);

has globals => (
    is        => 'ro',
    isa       => 'HashRef[Str]',
    required  => 1,
    default   => sub { {} },
);

has results => (
    is        => 'ro',
    isa       => 'Qublog::Form::Result',
    required  => 1,
    lazy      => 1,
    default   => sub { Qublog::Form::Result::Gathered->new },
    handles   => [ qw(
        is_valid is_success is_failure

        messages field_messages
        info_messages warning_messages error_messages
        field_info_messages field_warning_messages field_error_messages
    ) ],
);

has result => (
    is        => 'rw',
    isa       => 'Qublog::Form::Result',
    required  => 1,
    lazy      => 1,
    default   => sub { Qublog::Form::Result::Single->new },
);

has features => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    lazy        => 1,
    initializer => '_init_features',
    builder     => '_build_features',
);

sub _meta_features {
    my $self = shift;

    my @features;
    for my $feature_config (@{ $self->meta->features }) {
        my $feature = Qublog::Form::Feature::Functional->new(
            %$feature_config,
            action => $self,
        );
        push @features, $feature;
    }

    return \@features;
}

sub _init_features {
    my ($self, $features, $set, $attr) = @_;
    push @$features, $self->_meta_features;
    $set->($value);
}

sub _build_features {
    my $self = shift;
    return $self->_meta_features;
}

has controls => (
    is        => 'ro',
    isa       => 'HashRef',
    required  => 1,
    lazy      => 1,
    builder   => '_build_controls',
);

sub _build_controls {
    my $self = shift;
    my $factory  = $self->form_factory;
    my $features = $self->features;

    my %controls;
    my $meta_controls = $self->meta->get_controls;
    for my $meta_control (@{ $meta_controls }) {
        my $control = $factory->new_control($meta_control->control => {
            name => $meta_control->name,
            %{ $meta_control->options },
        });

        my $meta_features = $meta_control->features;
        for my $feature_name (keys %$meta_features) {
            my $feature_class = 'Qublog::Form::Feature::Control::' 
                              . class_name_from_name($feature_name);
            Class::MOP::load_class($feature_class);

            my $feature = $feature_class->new($meta_features->{$feature_name});
            push @$features, $feature;
        }

        $controls->{ $meta_control->name } = $control;
    }

    return \%controls;
}

sub stash {
    my ($self, $moniker) = @_;

    my $controls = $self->controls;
    my %controls;
    for my $control_name (keys %$controls) {
        my $control = $controls->{ $control_name };

        my $keys = $control->stashable_keys;
        for my $key (@$keys) {
            $controls{$control_name}{$key} = $control->$key;
        }
    }

    my %stash = (
        globals  => $self->globals,
        controls => \%controls,
    );

    $self->form_factory->stash($moniker => \%stash);
}

sub unstash {
    my ($self, $moniker) = @_;
    $self->clear;

    my $stash = $self->form_factory->unstash($moniker);
    return unless defined $stash;

    my $globals = $stash->{globals} || {};
    for my $key (keys %$globals) {
        $self->globals->{$key} = $globals->{$key};
    }

    my $controls       = $self->controls;
    my $controls_state = $stash->{controls} || {};
    for my $control_name (keys %$controls) {
        my $state   = $controls_state->{$control_name};
        my $control = $controls->{$control_name};
        my $keys    = $control->stashable_keys;
        for my $key (@$keys) {
            $control->$key($state->{$key});
        }
    }
}

sub clear {
    my ($self) = @_;

    for my $key (keys %$globals) {
        delete $self->globals->{$key};
    }

    my $controls       = $self->controls;
    for my $control_name (keys %$controls) {
        my $keys    = $control->stashable_keys;
        for my $key (@$keys) {
            delete $control->{$key}; # ugly
        }
    }

    $self->result->clear_results;
}

sub render {
    my $self = shift;
    my %params = @_;
    my @names  = defined $params{controls} ?    @{ delete $params{controls} } 
               :                             map { $_->name } 
                                                @{ $self->meta->get_controls }
               ;

    my $controls = $self->controls;
    $self->form_factory->render_control($controls->{$_}, %params) for @names;
}

sub render_control {
    my ($self, $name, $options, %params) = @_;

    return $self->form_factory->render_control(
        $self->form_factory->new_control($name => $options), %params
    );
}

sub consume {
    my $self   = shift;
    my %params = @_;
    my @names  = defined $params{controls} ?    @{ delete $params{controls} } 
               :                             map { $_->name } 
                                                @{ $self->meta->get_controls }
               ;

    my $controls = $self->controls;
    $self->form_factory->consume_control($controls->{$_}, %params) for @names;
}

sub clean {
    my $self = shift;

    my $features = $self->features;
    for my $feature (@$features) {
        $feature->clean;
    }

    $self->gather_results;
}

sub check {
    my $self     = shift;
    my $controls = $self->controls;

    my $features = $self->meta->features;
    for my $feature (@$features) {
        $features->check;
    }

    $self->gather_results;

    my @errors = $self->error_messages;
    $self->is_valid(@errors == 0);
}

sub process {
    my $self = shift;
    return unless $self->is_valid;

    my $features = $self->meta->features;
    for my $feature (@$features) {
        $features->pre_process;
    }

    $self->gather_results;
    return unless $self->is_success;

    $self->run;

    for my $feature (@$features) {
        $features->post_process;
    }

    $self->gather_results;

    my @errors = $self->error_messages;
    $self->is_success(@errors == 0);
}

sub clean_and_check_and_process {
    my $self = shift;
    $self->clean;
    $self->check;
    $self->process;
}

sub gather_results {
    my $self = shift;
    my $controls = $self->controls;
    $self->results->gather_results( 
        $self->result, 
        map { $_->result } @{ $self->features } 
    );
}

1;
