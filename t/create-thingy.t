use strict;
use warnings;

use Data::Dumper;
use File::Find::Rule;
use File::Slurp;
use Test::More 'no_plan';

use Qublog::Schema;
use Qublog::Schema::Action::CreateThingy;

my $schema = Qublog::Schema->connect(
    'dbi:SQLite:qublogtest.db', '', ''
);

END {
    unlink 'qublogtest.db' if -f 'qublogtest.db';
}

$schema->storage->dbh_do(sub {
    my ($storage, $dbh) = @_;

    my @files = sort
        File::Find::Rule
            ->file
            ->name('*.sql')
            ->in('sql');

    for my $file (@files) {
        my $sql = read_file($file);
        my @statements = split /;/, $sql;
        for my $stmt (@statements) {
            $stmt =~ s/^\s+//; $stmt =~ s/\s+$//;
            next unless $stmt;

            #diag("RUNNING $stmt");
            $dbh->do($stmt);
        }
    }
});

my $owner = $schema->resultset('User')->create({
    name           => 'testowner',
    email          => 'sterling@hanenkamp.com',
    email_verified => 1,
    password       => '*',
});
$owner->change_password('test123');
$owner->update;

sub _test_stuff_after_run($$$) {
    my ($comment, $out_text, $name) = @_;

    ok($comment, "$name: got a comment");
    ok($comment->journal_day, "$name: got a journal day");
    ok($comment->created_on, "$name: got a created date");
    is($comment->name, $out_text, "$name: got the expected output text back");
    ok($comment->owner, "$name: we have an owner");
    is($comment->owner->id, $owner->id, "$name: we have the right owner");
}

sub test_create_thingy_for($$$) {
    my ($in_text, $out_text, $name) = @_;

    my $create_thingy = Qublog::Schema::Action::CreateThingy->new(
        schema       => $schema,
        owner        => $owner,
        comment_text => $in_text,
    );
    $create_thingy->process;

    _test_stuff_after_run(
        $create_thingy->comment,
        $out_text,
        $name,
    );

    return $create_thingy->comment;
}

sub test_update_thingy_for($$$$) {
    my ($comment, $in_text, $out_text, $name) = @_;

    my $create_thingy = Qublog::Schema::Action::CreateThingy->new(
        schema       => $schema,
        owner        => $owner,
        comment      => $comment,
        comment_text => $in_text,
    );
    $create_thingy->process;
    
    _test_stuff_after_run(
        $create_thingy->comment,
        $out_text,
        $name,
    );
}

# Basic text
{
    my $text = 'This is a test.';
    test_create_thingy_for($text, $text, 'basic');
}

# Multiline text
{
    my $text = q{This is a test.
With some more text in
it than the last one
had.};

    test_create_thingy_for($text, $text, 'multiline');
}

# Single line with a tag reference
{
    my $text = q{This is a #test.};
    test_create_thingy_for($text, $text, 'mid tag ref');
}

# Single line starting with a tag reference
{
    my $text = q{#This is a test.};
    test_create_thingy_for($text, $text, 'start tag ref');
}

# Single line ending with a tag reference
{
    my $text = q{This is a #test};
    test_create_thingy_for($text, $text, 'end tag ref');
}

# Single line containing multiple tags
{
    my $text = q{#This #is#a #test};
    test_create_thingy_for($text, $text, 'multi tag ref');
}

# One task reference
{
    my $in_text = q{[ ] Task 1};
    my $out_text = q{ * #4*2};

    test_create_thingy_for($in_text, $out_text, 'one task');
}

# Multiple task references
{
    my $in_text = q{[ ] Task 1
-[ ] Task 2
--[ ] Task 3};
    my $out_text = q{ * #5*3
  * #6*4
   * #7*5};

   test_create_thingy_for($in_text, $out_text, 'multi task');
}

# Different statuses
{
    my $in_text = q{[x] Task 4
[!] Task 5
[-] Task 6
[ ] Task 7};
    my $out_text = q{ * #8*6
 * #9*7
 * #A*8
 * #C*9};

    test_create_thingy_for($in_text, $out_text, 'diff status');
}

# Text and tasks
{
    my $in_text = q{Blah blah foo bar bazzle boxey boo.

[ ] #ABC: Foo
[ ] #XYZ: Bar

Blabbidy bloo bloo.};
    my $out_text = q{Blah blah foo bar bazzle boxey boo.

 * #D*10
 * #E*11

Blabbidy bloo bloo.};
    test_create_thingy_for($in_text, $out_text, 'text and tasks');
}

# Text and spaced tasks
{
    my $in_text = q{Blah blah foo bar bazzle boxey boo.

[ ] #ABC: Bar

[ ] #XYZ: Foo

Blabbidy bloo bloo.};
    my $out_text = q{Blah blah foo bar bazzle boxey boo.

 * #D*12

 * #E*13

Blabbidy bloo bloo.};
    test_create_thingy_for($in_text, $out_text, 'text and spaced tasks');
}

# Text and hierarchical tasks
my $comment;
{
    my $in_text = q{Blah blah foo bar bazzle boxey boo.

[ ] #ABC: Flub
[ ] #XYZ: Blub
-[ ] Baz
--[ ] #FFF: Qux

Blabbidy bloo bloo.};
    my $out_text = q{Blah blah foo bar bazzle boxey boo.

 * #D*14
 * #E*15
  * #F*16
   * #G*17

Blabbidy bloo bloo.};
    $comment = test_create_thingy_for($in_text, $out_text, 'text and hier tasks');
}

# Edit Text and hierarchical tasks
{
    my $in_text = q{Blah blah foo bar bazzle boxey boo.

 * #D*14
 * #E*15
  * #F*16
   * #G*17

Blabbidy bloo bloo.

Shlem schluppidy schultz.};
    my $out_text = q{Blah blah foo bar bazzle boxey boo.

 * #D*14
 * #E*15
  * #F*16
   * #G*17

Blabbidy bloo bloo.

Shlem schluppidy schultz.};
    test_update_thingy_for($comment, $in_text, $out_text, 'edit text and hier tasks');
}
