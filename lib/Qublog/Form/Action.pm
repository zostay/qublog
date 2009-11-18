package Qublog::Form::Action;
use Moose::Role;

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

has result => (
    is        => 'ro',
    isa       => 'Qublog::Form::Result::Single',
    required  => 1,
    lazy      => 1,
    default   => sub { Qublog::Form::Result::Single->new },
    handles   => [ qw(
        is_valid is_success is_failure

        messages field_messages
        info_messages warning_messages error_messages
        field_info_messages field_warning_messagesw field_error_messages

        add_message
        info warning error
        field_info field_warning field_error

        success failure
    ) ],
);

has controls => (
    is        => 'ro',
    isa       => 'HashRef',
    required  => 1,
    lazy      => 1,
    builder   => '_build_controls',
);

sub _build_controls {
    my $self = shift;
    my $factory = $self->form_factory;

    my %controls;
    my $meta_controls = $self->meta->get_controls;
    for my $meta_control (@{ $meta_controls }) {
        my $control = $factory->new_control($meta_control->control => {
            name => $meta_control->name,
            %{ $meta_control->options },
        });

        my $meta_features = $meta_control->features;
        for my $feature_name (keys %$meta_features) {
            my $feature_class = 'Qublog::Form::Feature::' 
                              . class_name_from_name($feature_name);
            Class::MOP::load_class($feature_class);

            my $feature = $feature_class->new($meta_features->{$feature_name});
            $control->add_feature($feature);
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
}

sub render {
    my $self = shift;
    my @names = @_ > 0 ? @_ : map { $_->name } @{ $self->meta->get_controls };

    my $content  = '';
    my $controls = $self->controls;
    $content    .= $controls->{$_}->render for @names;

    return $content;
}

sub render_control {
    my ($self, $name, $options) = @_;
    return $self->form_factory->new_control($name => $options)->render;
}

sub clean {
    my ($self, $control_names, $cleaner_names) = @_;

    $control_names ||= [ map { $_->name } @{ $self->meta->get_controls } ];
    my $controls = $self->controls;
    for my $control_name (@$control_names) {
        $controls->{$control_name}->clean($self->result);
    }

    my $cleaners = $self->meta->cleaners;
    $cleaner_names ||= [ map { $_->{name} } @$cleaners ];
    $cleaner_names = map { { $_ => 1 } } @$cleaner_names;
    for my $cleaner (@$cleaners) {
        $cleaner->{code}->($self);
    }
}

sub check {
    my ($self, $control_names, $checker_names)  = shift;

    $control_names ||= [ map { $_->name } @{ $self->meta->get_controls } ];
    my $controls = $self->controls;
    for my $control_name (@$control_names) {
        $controls->{$control_name}->clean($self->result);
    }

    my $checkers = $self->meta->checkers;
    $checker_names ||= [ map { $_->{name} } @$checkers ];
    $checker_names = map { { $_ => 1 } } @$checker_names;
    for my $checker (@$checkers) {
        $checker->{code}->($self);
    }

    my @errors = $self->error_messages;
    $self->is_valid(@errors == 0);
}

sub process {
    my $self = shift;
    return unless $self->is_valid;

    $self->run;

    my @errors = $self->error_messages;
    $self->is_success(@errors == 0);
}

sub clean_and_check_and_process {
    my $self = shift;
    $self->clean;
    $self->check;
    $self->process;
}

1;
