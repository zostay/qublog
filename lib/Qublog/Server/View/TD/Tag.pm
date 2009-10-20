package Qublog::Server::View::TD::Tag;
use strict;
use warnings;

use Qublog::Server::View::Common;

use Template::Declare::Tags;

template '/tag/index' => sub {
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

1;
