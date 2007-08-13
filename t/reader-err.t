#!perl

use strict;
use warnings;

use Config::INI::Reader;

use Test::More tests => 5;

eval { Config::INI::Reader->read_file; };
like($@, qr/no filename specified/i, 'read_file without args');

{
  my $filename = q{something that's very unlikely to exist};
  eval { Config::INI::Reader->read_file($filename); };
  like(
    $@,
    qr/file '$filename' does not exist/i,
    'read_file with non-existent file'
  );
}

{
  my $filename = 'lib';

  eval { Config::INI::Reader->read_file($filename); };
  like($@, qr/'$filename' is not a plain file/i, 'read_file on non-plain-file');
}

eval { Config::INI::Reader->read_string; };
like($@, qr/no string provided/i, 'read_string without args');

{
  my $input = 'foo bar moo';
  eval { Config::INI::Reader->read_string($input); };
  like($@, qr/Syntax error at line 1: '$input'/i, 'syntax error');
}
