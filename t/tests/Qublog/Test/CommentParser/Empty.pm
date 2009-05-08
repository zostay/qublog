#!/usr/bin/perl
use strict;
use warnings;

package Qublog::Test::CommentParser::Empty;
use base qw( Qublog::Test::CommentParser );

use Test::More;

# Simple test of the class using an empty comment
sub empty_comment : Test(9) {
    my $self = shift;

    my $parser = Qublog::Util::CommentParser->new( 
        comment => $self->{comment},
        text    => '',
    );

    can_ok($parser, 'project');
    can_ok($parser, 'comment');
    can_ok($parser, 'tasks');
    can_ok($parser, 'execute');
    can_ok($parser, 'htmlify');

    {
        is($parser->text, '', 'comment start empty');

        $self->number_of_task_logs_is( all => 0 );
    }

    $parser->execute;

    {
        is($parser->text, '', 'comment still empty');

        $self->number_of_task_logs_is( all => 0 );
    }
}

1;
