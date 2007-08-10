#!perl

use strict;
use warnings;
use Test::More;
use Config::INI::Reader;

eval 'use Test::Exception';
plan skip_all => 'Test::Exception required' if $@;

plan tests => 6;

throws_ok(sub {
        Config::INI::Reader->read_file;
}, qr/no filename specified/i, 'read_file without args');

{
    my $filename = q{something that's very unlikely to exist};

    throws_ok(sub {
            Config::INI::Reader->read_file($filename);
    }, qr/file '$filename' does not exist/i, 'read_file with non-existent file');
}

{
    my $filename = 'lib';

    throws_ok(sub {
            Config::INI::Reader->read_file($filename);
    }, qr/'$filename' is not a plain file/i, q{read_file on something that's not a file});
}

SKIP: {
    eval 'use Test::MockModule';
    skip 'Test::MockModule required', 1 if $@;

    my $module = Test::MockModule->new('IO::File');
    $module->mock(open => sub { return });

    my $filename = 'pm_to_blib';

    throws_ok(sub {
            Config::INI::Reader->read_file($filename);
    }, qr/couldn't read file '$filename':/i, 'read_file fails to open input');
}

throws_ok(sub {
        Config::INI::Reader->read_string;
}, qr/no string provided/i, 'read_string without args');

{
    my $input = 'foo bar moo';

    throws_ok(sub {
            Config::INI::Reader->read_string($input);
    }, qr/Syntax error at line 1: '$input'/i, 'syntax error');
}
