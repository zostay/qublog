use strict;
use warnings;

package Qublog::Web::Emoticon;
use base qw( Text::Emoticon );

use Qublog::Web;

=head1 NAME

Qublog::Web::Emoticon - emoticons for Qublog

=head1 SYNOPSIS

  my $filter = Qublog::Web::Emoticon->new;
  print $filter->filter('Hello :^)');

=head1 DESCRIPTION

Defines the emoticons used by Qublog.

=head2 EMOTICONS

The following emoticons are supported.

  :S :-S :^S o_O O_o 
  :'( :'-( :'^( T_T 
  8) 8-) 8^) 
  >:) >:-) >:^)
  :D :-D :^D 
  XD X-D X^D
  X[ X-[ X^[ 
  :| :-| :^| :/ :-/ :^/
  :p :-p :^P :P :-P :^P 
  :$ :-$ :^$ 
  /:| /:-| /:^| 
  :( :-( :^( v_v 
  :) :-) :^) ^_^ 
  :o :-o :^o :O :-O :^O 
  >:D >:-D >:^D 
  ;) ;-) ;^) ^_~ ~_^ 
  XO X-O X^O 

=cut

my %icons = (
    confuse  => [ qw{ :S :-S :^S o_O O_o } ],
    cry      => [ qw{ :'( :'-( :'^( T_T } ],
    cool     => [ qw{ 8) 8-) 8^) } ],
    evil     => [ qw{ >:) >:-) >:^) } ],
    grin     => [ qw{ :D :-D :^D } ],
    lol      => [ qw{ XD X-D X^D } ],
    mad      => [ qw{ X[ X-[ X^[ } ],
    neutral  => [ qw{ :| :-| :^| :/ :-/ :^/ } ],
    razz     => [ qw{ :p :-p :^P :P :-P :^P } ],
    red      => [ qw{ :$ :-$ :^$ } ],
    roll     => [ qw{ /:| /:-| /:^| } ],
    sad      => [ qw{ :( :-( :^( v_v } ],
    smiley   => [ qw{ :) :-) :^) ^_^ } ],
    surprise => [ qw{ :o :-o :^o :O :-O :^O } ],
    twist    => [ qw{ >:D >:-D >:^D } ],
    wink     => [ qw{ ;) ;-) ;^) ^_~ ~_^ } ],
    yell     => [ qw{ XO X-O X^O } ],
);

my %smileys;
while (my ($icon, $smileys) = each %icons) {
    for my $smiley (@$smileys) {
        $smileys{ $smiley } = 'smiley-' . $icon . '.png';
    }
}

__PACKAGE__->register_subclass(\%smileys);

sub default_config {
    return {
        imgbase => '/static/images/icons',
        xhtml   => 1,
        class   => 'smiley',
    };
}

sub filter {
    my($self, $text) = @_;
    return unless defined $text;
    my $re = $self->pattern;
    if ($self->{strict}) {
      $text =~ s{(?<!\w)$re(?!\w)}{$self->do_filter($self->map->{$1}, $1)}eg;
    } else {
      $text =~ s{$re}{$self->do_filter($self->map->{$1}, $1)}eg;
    }
    return $text;
}

sub do_filter {
    my($self, $icon, $original) = @_;
    my $class = $self->{class} ? qq( class="$self->{class}") : "";
    my $xhtml = $self->{xhtml} ? qq( /) : "";

    $original = Qublog::Web::escape_html($original);
    return qq(<img title="$original" src="$self->{imgbase}/$icon"$class$xhtml>); 
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< hanenkamp@cpan.org >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Andrew Sterling Hanenkamp.

=cut

1;
