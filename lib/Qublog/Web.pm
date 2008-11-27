use strict;
use warnings;

package Qublog::Web;
use Jifty::View::Declare -base;

use Text::Markdown 'markdown';
use Text::Typography 'typography';

require Exporter;
our @ISA = qw/ Exporter /;

our @EXPORT = qw/ 
    htmlify 
    format_time
    format_date
    format_links
    capture
/;

=head1 NAME

Qublog::Web - Helper subroutines for use in views

=head1 SYNOPSIS

  use Qublog::Web;

  template foo => page {
      htmlify("Some **text**.");
  };

=head1 METHODS

=head2 htmlify TEXT

=head2 htmlify TEXT, LOGS

Given a string, it uses L<Text::Markdown> to convert it into HTML, which is returned.

Prior to doing that, it also does some other things:

=over

=item 1.

Converts any C<< #nick >> into a link to the appropriate task on the projects page.

=back

The optional second argument provides some context. This should be a L<Qublog::Model::TaskLogCollection> object that provides a list of log entries that will be used to annotate the C<< #nick >> comments found.

=cut

sub _replace_task_nicknames {
    my ($nickname, $action, $status) = @_;
    $action   = join ' ', 'task-reference', ($action || '');
    $status ||= '';

    my $task = Qublog::Model::Task->new;
    $task->load_by_tag_name($nickname);

    return '#'.$nickname unless $task->id;

    my $url  = Jifty->web->url(path => '/project').'#'.$task->tag;
    my $name = $task->name;
    return qq{<span class="$action">}
          .qq{<a href="$url" class="$status">#$nickname: $name</a></span>};
}

sub _load_annotations($) {
    my $logs = shift;

    my %annotations;
    while (my $log = $logs->next) {
        my $task     = $log->task;
        my $nickname = $task->tag;

        $annotations{ $nickname } 
            = [ $log->log_type, join ' ', $task->task_type, $task->status ];
    }

    return %annotations;
}

sub htmlify($;$) {
    my ($text, $logs) = @_;

    my %annotations = _load_annotations($logs) if defined $logs;

    $text =~ s/#(\w+)/_replace_task_nicknames($1, @{ $annotations{$1} })/ge;

    return typography(markdown($text));
}

=head2 format_time DATETIME

Given a L<DateTime> object, it returns a string representing that time in C<h:mm a> format.

=cut

sub format_time($) {
    my $time = shift;
    return '-:--' unless defined $time;
    return $time->format_cldr('h:mm a');
}

=head2 format_date DATETIME

Returns the date in a pretty format.

=cut

sub format_date($) {
    my $date = Jifty::DateTime->from_epoch( epoch => shift->epoch );
    my $now  = Jifty::DateTime->now;

    my $date_str = $date->friendly_date;
    if ($date_str =~ /^\d\d\d\d-\d\d-\d\d$/) {
        my $seven_days_ago = DateTime::Duration->new( days => -7 );

        if ($date > $now + $seven_days_ago) {
            $date_str = $date->format_cldr('EEEE');
        }
        elsif ($date->year eq $now->year) {
            $date_str = $date->format_cldr('EEEE, MMMM dd');
        }
        else {
            $date_str = $date->format_cldr('EEEE, MMMM dd, YYYY');
        }
    }

    return $date_str;
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

=head2 capture CODE

This snags a L<Template::Declare> template and returns it as a string.

=cut

sub capture(&) {
    my $code = shift;

    my $content;
    Template::Declare->new_buffer_frame;
    {
        $code->();
        $content = Template::Declare->buffer->data || '';
    }
    Template::Declare->end_buffer_frame;

    return $content;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< hanenkamp@cpan.org >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
