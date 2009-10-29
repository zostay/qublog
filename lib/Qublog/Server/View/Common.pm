package Qublog::Server::View::Common;
use Template::Declare::Tags;

use strict;
use warnings;

use Qublog::Menu;
use Qublog::Server::Link;

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

=head1 NAME

Qublog::Server::View::Common - commonly used view subroutines

=head1 SYNOPSIS

  template foo => sub {
      my ($self, $c) = @_;

      page {
          hyperlink
              label => 'Do Something',
              goto  => '/somewhere',
              ;
      } $c;
  };

=head1 DESCRIPTION

There's just a lot of common stuff that needs to happen in most views. That
common stuff goes here.

=head1 METHODS

=head2 hyperlink

Render an A-tag in a regular fashion. It comes in two forms at this point: gotos
and actions. Neither of these is very special at the moment.

To do a C<goto>, you send the C<goto> option:

  hyperlink goto => '/blah', label => 'Blah';

A goto is meant to send you to another page.

To do an C<action>, you send the C<action> option:

  hyperlink action => '/blah', label => 'Blah';

As of this writing, they are exactly the same. However, in the future, a goto
will be responsible for taking you to another page while an action will be
implemented to submit an Ajax request to handle some action like stopping a
timer.

Other options include:

=over

=item label

This is the label to give the link.

=item title

This is the tooltip to display when the user hovers the mouse cursor over the
link.

=back

Any other options will be passed as attributes on the link itself.

=cut

sub hyperlink(@) {
    my (%params) = @_;
    my $label = delete $params{label};

    $params{title} = delete $params{tooltip} if $params{tooltip};

    # A plain link to another page
    if ($params{goto}) {
        my $goto = delete $params{goto};
        a {
            attr { 
                href => $goto,
                %params,
            };
            $label;
        };
    }

    elsif ($params{action}) {
        my $action = delete $params{action};
        a {
            attr { 
                href => $action,
                %params,
            };
            $label;
        };
    }
}

=head2 render_menu_item

B<Note:> This method is not exported.

This displays a single menu item and is typically only called from
L</render_menu_items>.

=cut

sub render_menu_item($$) {
    my ($c, $item) = @_;

    return if $item->show_when eq 'anonymous' and     $c->user_exists;
    return if $item->show_when eq 'logged'    and not $c->user_exists;

    my @classes = ('item');

    # Dumb way of determining active
    my $active = 1;
    my (@active_parts) = split m{/}, $c->request->uri->path;
    my (@test_parts)   = split m{/}, $item->url;
    for my $test_part (@test_parts) {
        unless (@active_parts) {
            $active = 0;
            last;
        }

        my $next_active_part = shift @active_parts;
        if ($next_active_part ne $test_part) {
            $active = 0;
            last;
        }
    }

    push @classes, 'active' if $active;

    li { { class is join ' ', @classes }
        hyperlink
            action => $item->url,
            class  => $item->class,
            label  => $item->label,
            ;
    };
}

=head2 render_menu_items

B<Note:> This method is not exported.

This displays a submenu and is typically only called from L</render_navigation>.

=cut

sub render_menu_items($$) {
    my ($c, $items) = @_;

    ul { { class is 'menu' }
        my @items = sort { $a->sort_order <=> $b->sort_order } values %$items;
        for my $item (@items) {
            render_menu_item($c, $item);
        }
    };
}

=head2 render_navigation

B<Note:> This method is not exported.

This displays a menu and is typically only called from C</page>.

=cut

sub render_navigation($$) {
    my ($c, $menu) = @_;

    div {
        { id is 'navigation' }
        render_menu_items($c, $menu->items);
    };
}

=head2 page

  page {
      # page contents here...
  } $c;

This is a helper for rendering all the standard page template matter. This
automatically renders all the common HTML top matter and bottom matter,
including the page title, script ans style links, a standard masthead, a
standard footer, etc.

This way the main templates only have to worry about the guts.

=cut

create_wrapper page => sub {
    my ($content, $c) = @_;

    my %links;
    for my $type (qw( script style )) {
        my $links = $c->config->{'View::Common'}{$type};
        if (ref $links eq 'HASH') {
            $links = [ $links ];
        }

        my @links = map { Qublog::Server::Link->new( type => $type, %$_ ) } 
                       @{ $links };


        push @links, @{ $c->stash->{ $type } || [] };
        $links{ $type } = \@links;
    }

    html {
        head {
            title { $c->stash->{title} };

            for my $stylesheet (@{ $links{style} }) {
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

            for my $script (@{ $links{script} }) {
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

                        outs 'Hello, ';
                        hyperlink
                            label => $c->user->name,
                            goto  => '/user/profile',
                            ;

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
                                goto  => $c->uri_for('/user/logout'),
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

=head2 standard

Not a clue.

=cut

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

=head2 form_input

Unknown.

=cut

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

=head2 form_popup

Unused code ported from the Jifty version of Qublog. Not sure what will happen
with this.

=cut

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

=head2 form_textarea

Not sure.

=cut

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

=head2 form_submit

Say what?

=cut

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

=head2 render_message

This subroutine is currently neutered, but is a really nifty message renderer
when I get it re-implemented properly.

In the meantime, it's a simple but usable message renderer. To use, don't call it directly (since it's put in the standard page template). Instead, do this:

  push @{ $c->flash->{messages} }, {
      type    => 'error',
      message => 'Very bad things are happeneing.',
  };

The type is one of C<error>, C<warning>, or C<info>.

=cut

sub render_message($) {
    my ($message, $not_top) = @_;
    p { ucfirst $message . '.' };
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
#        p { { class is $class } ucfirst $message . '.' };
#    }
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 LICENSE

Qublog Personal/Professional Journaling
Copyright (C) 2009  Andrew Sterling Hanenkamp

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
