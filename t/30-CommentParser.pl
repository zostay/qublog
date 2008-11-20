use Jifty::Everything;
Jifty->new;

use Jifty::Test;
Jifty::Test->web;

use_ok('Qublog::Util::CommentParser');

# Setup a generic project to reuse
our $project = Qublog::Model::Task->new;
$project->create( name => 'Testing' );
$project->set_parent( undef );
ok($project->id, 'Testing project created');
ok(!$project->parent->id, 'has no parent');
ok(!$project->project->id, 'has no project');
is($project->task_type, 'project', 'is a project');

1;
