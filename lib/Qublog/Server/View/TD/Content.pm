package Qublog::Server::View::TD::Content;
use strict;
use warnings;

use Template::Declare::Tags;
use Text::Markdown 'markdown';
use Text::Typography 'typography';

use Qublog::Server::View::Common;

template 'content/show' => sub {
    my ($self, $c) = @_;
    my $content = $c->stash->{content};

    my $title = 'Qublog';
    if ($content =~ s/^#\s*(.*)$//m) {
        $title = $1;
    }

    $c->stash->{title} = $title;
    $c->add_style( file => 'content' );

    page { { class is 'content' }
        outs_raw typography(markdown($content));
    } $c;
};

1;
