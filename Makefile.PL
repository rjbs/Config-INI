use inc::Module::Install;

all_from('lib/Config/INI.pm');
requires('Carp'       => 0.000); # sure, it's core, but let's be thorough
requires('Mixin::Linewise::Readers' => 0.001); # first version
requires('Mixin::Linewise::Writers' => 0.001); # first version

extra_tests;

WriteAll;
