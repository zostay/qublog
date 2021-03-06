#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Qublog::Text::CommentParser;
use Test::More 'no_plan';

my $DEBUG = 0;
#$::RD_TRACE = 1;

my $parser = Qublog::Text::CommentParser->new;

sub make { goto &Qublog::Text::CommentParser::_make }

sub test_parsing_of($$$) {
    my ($text, $expected, $name) = @_;
    my $got = $parser->parse($text);
    diag(Dumper($got)) if $DEBUG;
    is_deeply($got, $expected, 'testing parse of '.$name);
}

# Empty string
test_parsing_of('', [], 'empty string');

# Just text
test_parsing_of('This is a test.', [
    make( text => 'This is a test.' ),
], 'plain string');

# Multiline text
{
    my $text = q{This is a test.
With some more text in
it than the last one
had.};

    test_parsing_of($text, [
        make( text => $text ),
    ], 'multiline string');
}

# Single line with a tag reference
{
    my $text = q{This is a #test.};
    test_parsing_of($text, [
        make( text => 'This is a ' ),
        make( tag => 'test' ),
        make( text => '.' ),
    ], 'tagged text');
}

# Single line starting with a tag reference
{
    my $text = q{#This is a test.};
    test_parsing_of($text, [
        make( tag => 'This' ), make( text => ' is a test.' ),
    ], 'start tag');
}

# Single line ending with a tag reference
{
    my $text = q{This is a #test};
    test_parsing_of($text, [
        make( text => 'This is a ' ), make( tag => 'test' ),
    ], 'end tag');
}

# Single line containing multiple tags
{
    my $text = q{#This #is#a #test};
    test_parsing_of($text, [
        make( tag => 'This' ), make( text => ' ' ),
        make( tag => 'is' ), make( tag => 'a' ),
        make( text => ' ' ), make( tag => 'test' ),
    ], 'multiple tags');
}

# One task reference
{
    my $text = q{[ ] Task 1};
    test_parsing_of($text, [
        make( task => 1, 'open', 0, undef, undef, 'Task 1' )
    ], 'a task');
}

# Multiple task references
{
    my $text = q{[ ] Task 1
-[ ] Task 2
--[ ] Task 3};
    test_parsing_of($text, [
        make( task => 1, 'open', 0, undef, undef, 'Task 1' ),
        make( task => 2, 'open', 0, undef, undef, 'Task 2' ),
        make( task => 3, 'open', 0, undef, undef, 'Task 3' ),
    ], 'multiple tasks');
}

# Different statuses
{
    my $text = q{[x] Task 4
[!] Task 5
[-] Task 6
[ ] Task 7};
    test_parsing_of($text, [
        make( task => 1, 'done', 0, undef, undef, 'Task 4' ),
        make( task => 1, 'nix', 0, undef, undef, 'Task 5' ),
        make( task => 1, undef, 0, undef, undef, 'Task 6' ),
        make( task => 1, 'open', 0, undef, undef, 'Task 7' ),
    ], 'different statuses');
}

# More variations in tasks
{
    my $text = q{[x] #1J3G
[-] #NG54: Task 7
[-] #4FFT: #foo: Task 8
-[ ] +#XYZ Task 9};
    test_parsing_of($text, [
        make( task => 1, 'done', 0, '1J3G', undef, undef ),
        make( task => 1, undef, 0, 'NG54', undef, 'Task 7'),
        make( task => 1, undef, 0, '4FFT', 'foo', 'Task 8'),
        make( task => 2, 'open', 1, 'XYZ', undef, 'Task 9'),
    ], 'more variations');
}

# Text and tasks
{
    my $text = q{Blah blah foo bar bazzle boxey boo.

[ ] #ABC: Foo
[ ] #XYZ: Bar

Blabbidy bloo bloo.};
    test_parsing_of($text, [
        make( text => "Blah blah foo bar bazzle boxey boo.\n" ),
        make( task => 1, 'open', 0, 'ABC', undef, 'Foo' ),
        make( task => 1, 'open', 0, 'XYZ', undef, 'Bar' ),
        make( text => "\n\nBlabbidy bloo bloo." ),
    ], 'text and tasks');
}

# Text and spaced tasks
{
    my $text = q{Blah blah foo bar bazzle boxey boo.

[ ] #ABC: Foo

[ ] #XYZ: Bar

Blabbidy bloo bloo.};
    test_parsing_of($text, [
        make( text => "Blah blah foo bar bazzle boxey boo.\n" ),
        make( task => 1, 'open', 0, 'ABC', undef, 'Foo' ),
        make( text => "\n" ),
        make( task => 1, 'open', 0, 'XYZ', undef, 'Bar' ),
        make( text => "\n\nBlabbidy bloo bloo." ),
    ], 'text and spaced tasks');
}

# Task log reference
{
    my $text = q{Blah blah foo bar bazzle boxey boo.
 * #ABC*123 
 * #XYZ*789 
Foobie fabbo.};
    test_parsing_of($text, [
        make( text => "Blah blah foo bar bazzle boxey boo.\n * " ),
        make( task_log => 'ABC', 123 ),
        make( text => " \n * " ),
        make( task_log => 'XYZ', 789 ),
        make( text => " \nFoobie fabbo."),
    ], 'task log references');
}

# Text and hierarchical tasks
{
    my $text = q{Blah blah foo bar bazzle boxey boo.

[ ] #ABC: Foo
[ ] #XYZ: Bar
-[ ] Baz
--[ ] #FFF: Qux

Blabbidy bloo bloo.};
    test_parsing_of($text, [
        make( text => "Blah blah foo bar bazzle boxey boo.\n" ),
        make( task => 1, 'open', 0, 'ABC', undef, 'Foo' ),
        make( task => 1, 'open', 0, 'XYZ', undef, 'Bar' ),
        make( task => 2, 'open', 0, undef, undef, 'Baz' ),
        make( task => 3, 'open', 0, 'FFF', undef, 'Qux' ),
        make( text => "\n\nBlabbidy bloo bloo." ),
    ], 'text and tasks');
}
