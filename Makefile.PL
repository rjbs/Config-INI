use inc::Module::Install;

all_from       ('lib/Config/INI.pm');
requires       ('Carp'       => 0.000); # sure, it's core, but let's be thorough
requires       ('IO::File'   => 0.000); # minimum version unknown
requires       ('IO::String' => 0.000); # minimum version unknown

extra_tests;

WriteAll;
