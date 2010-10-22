#!perl -Tw

use strict;

use Config::INI::Reader;

use Test::More tests => 7;

eval { Config::INI::Reader->read_file; };
like($@, qr/no filename specified/i, 'read_file without args');

{
  my $filename = q{t/does/not/exist};

  Carp::croak "unexpected file found in test directory t"
    if -e 't/does/not/exist';

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
  like($@, qr/not a plain file/i, 'read_file on non-plain-file');
}

SKIP: {
  eval "require File::Temp;" or skip "File::Temp not available", 1;

  # This could probably be limited to being required for Cygwin.
  eval "require filetest;"   or skip "filetest.pm not available", 1;
  filetest->import('access');

  my ($fh, $fn) = File::Temp::tempfile('tempXXXXX', UNLINK => 1);
  close $fh;

  chmod 0222, $fn;
  
  if (-r $fn) {
    chmod 0666, $fh;
    skip "chmoding file 0222 left it -r", 1;
  }

  eval { Config::INI::Reader->read_file($fn); };
  like($@, qr/(?:couldn't|can't) read/, "can't read an unreadable file");

  chmod 0666, $fh;
}

eval { Config::INI::Reader->read_string; };
like($@, qr/no string provided/i, 'read_string without args');

{
  my $input = 'foo bar moo';
  eval { Config::INI::Reader->read_string($input); };
  like($@, qr/Syntax error at line 1: '$input'/i, 'syntax error');
}

{
  # looks like a comment
  my $input = "[foo ; bar]\nvalue = 1\n";
  my $data  = eval { Config::INI::Reader->read_string($input); };
  like($@, qr/Syntax error at line 1:/i, 'syntax error');
}
