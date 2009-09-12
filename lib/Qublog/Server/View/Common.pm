package Qublog::Server::View::Common;
use Template::Declare::Tags;

use Qublog::Menu;

my @exports;
BEGIN {
    @exports = qw(
        page 
        standard
        form_input form_popup form_textarea form_submit
        hyperlink
        render_message
    );
}

use Sub::Exporter -setup => {
    exports => \@exports,
    groups => {
        default => \@exports,
    },
};

use Scalar::Util qw( reftype );

sub hyperlink(@) {
    my (%params) = @_;

    # A plain link to another page
    if ($params{goto}) {
        a {
            { href is $params{goto} }
            $params{label};
        };
    }

    elsif ($params{action}) {
        a {
            { href is $params{action} }
            $params{label};
        };
    }
}

sub render_menu_item($$) {
    my ($c, $item) = @_;

    return if $item->show_when eq 'anonymous' and     $c->user_exists;
    return if $item->show_when eq 'logged'    and not $c->user_exists;

    li { { class is join ' ', 'item', $item->class }
        hyperlink
            action => $item->url,
            label  => $item->label,
            ;
    };
}

sub render_menu_items($$) {
    my ($c, $items) = @_;

    ul { { class is 'menu' }
        my @items = sort { $a->sort_order <=> $b->sort_order } values %$items;
        for my $item (@items) {
            render_menu_item($c, $item);
        }
    };
}

sub render_navigation($$) {
    my ($c, $menu) = @_;

    div {
        { id is 'navigation' }
        render_menu_items($c, $menu->items);
    };
}

create_wrapper page => sub {
    my ($content, $c) = @_;

    html {
        head {
            title { $c->stash->{title} };

            for my $stylesheet (@{ $c->stash->{styles} || [] }) {
                if ($stylesheet->is_file) {
                    link { 
                        href is $stylesheet->path,
                        rel is 'stylesheet',
                        type is 'text/css',
                    };
                }
                else {
                    style { $stylesheet->code };
                }
            }

            for my $script (@{ $c->stash->{scripts} || [] }) {
                if ($script->is_file) {
                    script { src is $script->path };
                }
                else {
                    script { $script->code };
                }
            }
        };
        body {
            div {
                { id is 'masthead' }

                div {
                    { id is 'salutation' }

                    my $logged;
                    if ($c->user_exists) {
                        my $user = $c->user->get_object;

                        outs 'Hello, ' . $c->user->name;
                        $logged = 1;
                        #$logged = !$user->guest_account;
                    }
                    else {
                        outs 'No account.';
                    }

                    span {
                        outs ' (';
                        if ($logged) {
                            hyperlink
                                label => 'Sign in as someone else.',
                                goto  => $c->uri_for('/user/login'),
                                ;
                        }
                        else {
                            hyperlink
                                label => 'Sign in',
                                goto  => $c->uri_for('/user/login'),
                                ;

                            outs ' or ';

                            hyperlink
                                label => 'Register',
                                goto  => $c->uri_for('/user/register'),
                                ;
                        }
                            
                        outs ')';
                    };
                };

                render_navigation( $c, Qublog::Menu->new($c, 'main') );

                h1 { $c->stash->{title} };
            };

            div { 
                { id is 'messages' }

                for my $message (@{ $c->flash->{messages} || [] }) {
                    div { { class is $message->{type} }
                        render_message($message->{message});
                    };
                }

                delete $c->flash->{messages};
                '';
            }

            div {
                { id is 'content' }

                $content->();
            };

            p {
                { id is 'footer' }
                
                outs_raw $c->config->{footer};
            };

            if ($c->stash->{the_end}) {
                outs $c->stash->{the_end};
            }
        };
    };
};

sub standard(%) {
    my (%params) = @_;

    while (my ($name, $value) = each %params) {
        input {
            type  is 'hidden',
            class is 'form-standard',
            name  is $name,
            value is $value,
        };
    }
}

sub form_input(@) {
    my (%params) = @_;

    label {
        attr { 'for' => $params{name} };
        $params{label};
    } if $params{label};

    input {
        id    is $params{id},
        type  is ($params{type} || 'text'),
        class is $params{class},
        name  is $params{name},
        value is $params{value},
    };
}

sub form_popup(@) {
    my (%params) = @_;
    $params{value} ||= '';

    label {
        attr { 'for' => $params{name} };
        $params{label};
    } if $params{label};

    select {
        {
            id    is $params{id},
            name  is $params{name},
            class is $params{class},
            size  is 1,
        }

        for my $option (@{ $params{options} }) {
            my ($value, $label) = %$option;

            if ($value eq $params{value}) {
                option {
                    { value is $value, selected is 'selected' }
                    $label;
                };
            }
            else {
                option {
                    { value is $value }
                    $label;
                };
            }
        }
    };
}

sub form_textarea(@) {
    my (%params) = @_;

    label {
        attr { 'for' => $params{name} };
        $params{label};
    } if $params{label};

    textarea {
        id    is $params{id},
        class is $params{class},
        name  is $params{name},
        value is $params{value},
    };
}

sub form_submit(@) {
    my (%params) = @_;

    input {
        id    is $params{id},
        type  is ($params{type} || 'submit'),
        class is $params{class},
        name  is $params{name},
        value is $params{value},
    };
}

sub render_message($) {
    my ($message, $not_top) = @_;
#    my $class = ($not_type ? 'sub-message' : 'message');
#
#    if (ref $message) {
#        if ('HASH' eq reftype $message) {
#            div { { class is $class }
#                p { 'The following problems need to be corrected:' };
#                ul {
#                    for my $field (%$message) {
#                        li { render_message($message->{$field}, 1) };
#                    }
#                };
#            };
#        }
#        elsif ('ARRAY' eq reftype $message) {
#            if (@$message > 1) {
#                ul {
#                    for my $one_message (@$message) {
#                        li { render_message($one_message) };
#                    }
#                };
#            }
#            elsif (@$message == 1) {
#                render_message($message->[0]);
#            }
#        }
#    }
#
#    elsif ($message) {
        p { { class is $class } ucfirst $message . '.' };
#    }
}

1;
