#!perl

use strict;
use warnings;
use Test::More;
use Config::INI::Reader;

eval 'use Test::ClassAPI';
plan skip_all => 'Test::ClassAPI required' if $@;

Test::ClassAPI->execute;

__DATA__

Config::INI::Reader=class

[Config::INI::Reader]
new=method
read_file=method
read_string=method
read_handle=method
current_section=method
change_section=method
set_value=method
starting_section=method
ignore_line=method
preprocess_line=method
finalize=method
