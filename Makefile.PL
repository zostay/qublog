#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;

name 'Qublog-Server';
all_from 'lib/Qublog/Server.pm';
license  'agpl';

requires 'Catalyst::Runtime' => '5.80011';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'parent';
requires 'Config::General'; # This should reflect the config file format you've chosen

requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::View::Template::Declare';

requires 'Crypt::Rijndael';
requires 'DBIx::Class';
requires 'DateTime';
requires 'DateTime::Format::Natural';
requires 'DateTime::Format::SQLite';
requires 'DateTime::Span';
requires 'DateTime::TimeZone';
requires 'Digest';
requires 'Digest::MD5';
requires 'Email::Valid';
requires 'File::Slurp';
requires 'Form::Factory' => 0.013;
requires 'Hash::Merge';
requires 'HTML::Element';
requires 'Lingua::EN::Inflect';
requires 'List::MoreUtils';
requires 'Moose';
requires 'MooseX::ClassAttribute';
requires 'MooseX::Singleton';
requires 'Number::RecordLocator';
requires 'Parse::RecDescent';
requires 'Storable';
requires 'Template::Declare';
requires 'Text::Emoticon';
requires 'Text::Markdown';
requires 'Text::Typography';

                 # See Catalyst::Plugin::ConfigLoader for supported formats
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
