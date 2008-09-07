use inc::Module::Install;

name        'Qublog';
all_from    'lib/Qublog.pm';

requires    'DateTime';
requires    'Hash::Merge';
requires    'Jifty' => '0.80408';
requires    'Lingua::EN::Inflect';
requires    'Math::BaseCalc';
requires    'Moose';
requires    'Test::MockModule';
requires    'Text::Markdown';
requires    'Text::Typography';

WriteAll;
