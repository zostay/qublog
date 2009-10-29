package Qublog::Server::View::TD::Content;
use strict;
use warnings;

use Template::Declare::Tags;
use Text::Markdown 'markdown';
use Text::Typography 'typography';

use Qublog::Server::View::Common;

=head1 NAME

Qublog::Server::View::TD::Content - templates for the content manager

=head1 DESCRIPTION

This display static content for Qublog.

=head1 TEMPLATES

=head2 content/show

Shows a static page. It expects the following stashed arguments:

=over

=item content

This is the content to format with L<Text::Typography> and L<Text::Markdown>.
The title of the page will be taken from the first heading in the file:

  # Foo Bar
  
  Some *text* here.

The initial "Foo Bar" in this example would become the title for the page. If no
title is found, the title will be "Qublog".

=back

=cut

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
