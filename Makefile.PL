use strict;
use inc::Module::Install;

name           'Config-Tiny';
all_from       'lib/Config/Tiny.pm';
build_requires 'ExtUtils::MakeMaker' => '6.11';
build_requires 'Test::More'          => '0.47';

WriteAll;
