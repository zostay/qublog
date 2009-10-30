package Qublog::Server::View::TD::Tag;
use strict;
use warnings;

use Qublog::Server::View::Common;

use Template::Declare::Tags;

=head1 NAME

Qublog::Server::View::TD::Tag - Tag-related templates

=head1 DESCRIPTION

This handles the tag-related templates.

=head1 TEMPLATES

=head2 tag/index

Shows a tag cloud of the current user's tags.

=cut

template 'tag/index' => sub {
    my ($self, $c) = @_;
    my $tags = $c->stash->{tags};
    my $min  = $c->stash->{min_score};
    my $max  = $c->stash->{max_score};

    $c->stash->{title} = 'Tags';

    page {
        p {
            for my $tag_name (keys %$tags) {
                my $total = ($tags->{ $tag_name } - $min) * 3 / ($max - $min);

                span { { style is "font-size:".(0.8+$total)."em" }

                    outs ' ';
                    hyperlink
                        label => '#' . $tag_name,
                        class => 'icon center-left v-view o-tag',
                        goto  => '/tag/view/' . $tag_name,
                        ;
                    outs ' ';
                };
            }
        };
    } $c;
};

=headd2 tag/view

View everything related to a single tag.

=cut

template 'tag/view' => sub {
    my ($self, $c) = @_;
    my $tag = $c->stash->{tag};

    $c->stash->{title} = '#' . $tag->name;

    $c->add_style( file => 'tag' );
    $c->add_style( file => 'journal' );

    $c->add_script( file => 'journal' );

    page {
        p {
            hyperlink
                label => 'Back to Tags',
                class => 'icon v-return o-tag',
                goto  => '/tag',
                ;
        };

        div { { class is 'journal' }
            show '/journal/bits/items', $c, $tag;
        };
    } $c;
};

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
