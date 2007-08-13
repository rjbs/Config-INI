#!perl -w

use strict;

use Test::More tests => 7;

my $R = 'Config::INI::Reader';
my $W = 'Config::INI::Writer';

use_ok($_) for $R, $W;

my $data = {
  _ => {
    a => 1,
    b => 2,
    c => 3,
  },
  foo => {
    bar  => 'baz',
    baz  => 'bar',
  },
};

is_deeply(
  $R->read_string($W->write_string($data)),
  $data,
  "we can round-trip hashy data",
);

my $starting_first = [
  _ => [
    a => 1,
    b => 2,
    c => 3,
  ],
  foo => [
    bar  => 'baz',
    baz  => 'bar',
    quux => undef,
  ],
];

my $expected = <<'END_INI';
a = 1
b = 2
c = 3

[foo]
bar = baz
baz = bar
END_INI

is($W->write_string($starting_first), $expected, "stringifying AOA, _ first");

{
  my $expected = <<'END_INI';
[foo]
bar = baz
baz = bar

[_]
a = 1
b = 2
c = 3

[foo]
fer = agin
END_INI

  my $starting_later = [
    foo => [
      bar  => 'baz',
      baz  => 'bar',
      quux => undef,
    ],
    _ => [
      a => 1,
      b => 2,
      c => 3,
    ],
    foo => [
      fer => 'agin',
    ],
  ];

  is($W->write_string($starting_later), $expected, "stringifying AOA, _ later");
}

eval { $W->write_string([ A => [ B => 1 ], A => [ B => 2 ] ]); };
like($@, qr/multiple/, "you can't set property B in section A more than once");

SKIP: {
  eval "require File::Temp;" or skip "File::Temp not availabe", 1;

  my ($fh, $tmpfile) = File::Temp::tempfile(UNLINK => 1);
  close $fh;

  $W->write_file($data, $tmpfile);

  my $read_in = $R->read_file($tmpfile);

  is_deeply($read_in, $data, "round-trip data->file->data");
}
