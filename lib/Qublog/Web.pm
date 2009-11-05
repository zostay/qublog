use strict;
use warnings;

package Qublog::Web;

use Qublog::Server::View::Common;
use Template::Declare::Tags;
use Qublog::Web::Format::Comment;

use Text::Markdown 'markdown';
use Text::Typography 'typography';
use Qublog::Web::Emoticon;

require Exporter;
our @ISA = qw/ Exporter /;

our @EXPORT = qw/ 
    htmlify 
    format_time
    format_date
    format_links
    escape_html
/;

=head1 NAME

Qublog::Web - Helper subroutines for use in views

=head1 SYNOPSIS

  use Qublog::Web;

  template foo => page {
      htmlify("Some **text**.");
  };

=head1 METHODS

=head2 smileyize TEXT

Converts emoticons to smileys.

=cut

sub smileyize($) {
    my $text = shift;

    my $emoticons = Qublog::Web::Emoticon->new;
    return $emoticons->filter($text);
}

=head2 htmlify TEXT

Given a string, it uses L<Text::Markdown> to convert it into HTML, which is returned.

Prior to doing that, it also does some other things:

=over

=item 1.

Converts any C<< #nick >> into a link to the appropriate task on the projects page.

=back

The optional second argument provides some context. This should be a L<Qublog::Model::TaskLogCollection> object that provides a list of log entries that will be used to annotate the C<< #nick >> comments found.

=cut

sub htmlify($;$) {
    my ($scalar, $c) = @_;
    $scalar = smileyize($scalar);

    my $formatter = Qublog::Web::Format::Comment->new(
        schema => $c->model('DB')->schema,
    );
    $scalar = $formatter->format($scalar);

    return typography(markdown($scalar));
}

=head2 format_time DATETIME

Given a L<DateTime> object, it returns a string representing that time in C<h:mm a> format.

=cut

sub format_time($;$) {
    my ($time, $c) = @_;
    return Qublog::DateTime->format_human_time($time, $c->time_zone);
}

=head2 format_date DATETIME

Returns the date in a pretty format.

=cut

sub format_date($;$) {
    my ($date, $c) = @_;
    return Qublog::DateTime->format_human_date($date, $c->time_zone);
}

=head2 show_links LINKS

This outputs the list of links given as an array in LINKS.

=cut

sub show_links(\@) {
    my $links = shift;

    div { { class is 'actions' }
        for my $link (@$links) {
            hyperlink %$link;
            outs ' ';
        }
    };
}

=head2 format_links LINKS

This formats the list of links given as an array in LINKS.

=cut

sub format_links(\@) {
    my $links = shift;

    my $content;
    Template::Declare->new_buffer_frame;
    {
        show_links @$links;
        $content = Template::Declare->buffer->data || '';
    }
    Template::Declare->end_buffer_frame;

    return $content;
}

=head2 escape_html

Taken from L<Jifty::View::Mason::Handler/escape_utf8>. Escapes various characters into HTML entities to help stop XSS.

=cut

sub escape_html {
    no warnings 'uninitialized';
    $_[0] =~ s/&/&#38;/g;
    $_[0] =~ s/</&lt;/g;
    $_[0] =~ s/>/&gt;/g;
    $_[0] =~ s/\(/&#40;/g;
    $_[0] =~ s/\)/&#41;/g;
    $_[0] =~ s/"/&#34;/g;
    $_[0] =~ s/'/&#39;/g;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< hanenkamp@cpan.org >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
