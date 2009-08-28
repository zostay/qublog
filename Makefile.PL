use inc::Module::Install;

name        'Qublog';
all_from    'lib/Qublog.pm';

requires    'DateTime';
requires    'DateTime::Set';
requires    'Hash::Merge';
requires    'Jifty' => '0.80408';
requires    'Lingua::EN::Inflect';
requires    'Math::BaseCalc';
requires    'Moose';
requires    'Number::RecordLocator';
requires    'Test::Class';
requires    'Test::MockModule';
requires    'Text::Emoticon';
requires    'Text::Markdown';
requires    'Text::Typography';

WriteAll;
