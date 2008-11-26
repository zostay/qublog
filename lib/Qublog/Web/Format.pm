use strict;
use warnings;

package Qublog::Web::Format;

use Qublog::Web ();

require Exporter;
our @ISA = qw/ Exporter /;

our @EXPORT = qw/ apply_format /;

=head1 NAME

Qublog::Web::Format - format helpers for generic templating

=head1 SYNOPSIS

  use Qublog::Web::Format;

  my $formatted_text = apply_format($text, [ 
      'htmlify', 
      { 
          format    => 'wrap', 
          arguments => { element => 'div' } 
      } 
  ]);

=head1 DESCRIPTION

A helper to format text. As of this implementation each format is handled as a function within this class, but the implementation may vary in the future.

=head1 METHODS

=head2 apply_format

This function takes a variable list of arguments. First, exactly one scalar (possibly a reference) should be passed to this function. This will be transformed by the given formats. The next (and last) argument is an array reference which contains the formats to apply to transform the scalar into a formatted string.

A format is either a string, representing the name of the format to apply, or a hash reference containing two keys:

=over

=item format

This is the name of the format to use.

=item options

This is the options to pass to the format. See the L</FORMATS> below for information on arguments the formats may take. These are generally passed as a hash reference.

=back

Here are some examples:

  my $html_text   = format($text, [ 'htmlify' ]);
  my $pretty_date = format($datetime, [ 'date', 'p' ]);
  my $links       = format(\@links, [ 
      'links', 
      { 
          format  => 'wrap', 
          options => { 
              tag   => 'div', 
              class => 'pretty-links' 
          } 
      } 
  ]);

The formats are applied in the order given. In the second call in the example above, the "date" format is applied first, followed by the "p" format.

=cut

sub apply_format {
    my ($scalar, $formats) = @_;

    $formats = [ $formats ] unless ref $formats eq 'ARRAY';

    FORMAT: for my $format (@$formats) {
        my ($function, $options);

        if (ref $format) {
            $function = $format->{format};
            $options  = $format->{options};
        }
        
        else {
            $function = $format;
        }

        if (length $function == 0 || $function =~ /\W/) {
            warn qq{The format "$function" is invalid.};
            next FORMAT;
        }

        no strict 'refs';
        $scalar = $function->($scalar, $options);
    }

    return $scalar;
}

=head1 FORMATS

=head2 htmlify

This converts the scalar to HTML using L<Qublog::Web/htmlify>. This format takes the following options:

=over

=item logs

This is a L<Qublog::Model::TaskLogCollection> object.

=back

=cut

sub htmlify {
    my ($scalar, $options) = @_;
    return Qublog::Web::htmlify($scalar, $options->{logs});
}

=head2 time

This converts a L<DateTime> object to a time using L<Qublog::Web/format_time>.This format takes no options.

=cut

sub time {
    my $datetime = shift;
    return Qublog::Web::format_time($datetime);
}

=head2 date

This converts a L<DateTime> object to a date using L<Qublog::Web/format_date>. This format takes no options.

=cut

sub date {
    my $datetime = shift;
    return Qublog::Web::format_date($datetime);
}

=head2 wrap

This wraps the scalar within a single HTML tag. This format takes the following options:

=over

=item tag

This is the name of the tag to use. If not given, this will be "div".

=item anything else

Any other options will be taken to mean attribute names.

=back

=cut

sub _generate_wrap {
    my $default = shift;
    return sub {
        my ($text, $opts) = @_;
        my %options = %{ $opts || {} }; # avoid side-effects
        my $tag = delete $options{tag} || $default;

        my $result = "<$tag";
        while (my ($attr, $value) = each %options) {
            $result .= qq{ $attr="$value"};
        }
        $result .= ">$text</$tag>";
        return $result;
    }
}

*wrap = _generate_wrap('div');
for my $tag (qw( div p span )) {
    no strict 'refs';
    *{$tag} = _generate_wrap($tag);
}

=head2 div

This is a synonym for L</wrap>.

=head2 p

This is a synonym for L</wrap>, except that the default tag name is "P".

=head2 span

This is a synonym for L</wrap>, except that the default tag name is "span".

=head2 links

This uses L<Qublog::Web/format_links> to take an array reference of link definitions (hash references) into a list of links. This format takes no options.

=cut

sub links {
    my $links = shift;
    return Qublog::Web::format_links(@$links);
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< hanenkamp@cpan.org >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
