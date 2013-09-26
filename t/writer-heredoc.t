#!perl -Tw

use strict;

use Test::More tests => 6;

my $R = 'Config::INI::Reader::HereDoc';
my $W = 'Config::INI::Writer::HereDoc';

use_ok($_) for $R, $W;

my $data = {
  _ => {
    a => 1,
    b => 2,
    c => 3,
  },
  foo => {
    bar  => 'baz',
    baz  => "bar\nbar",
  },
};

is_deeply(
  $R->read_string($W->write_string($data)),
  $data,
  'we can round-trip hashy data',
);

is_deeply(
  $R->read_string($W->new->write_string($data)),
  $data,
  'we can round-trip hashy data, object method',
);

my $starting_first = [
  _ => [
    a => 1,
    b => 2,
    c => 3,
   ],
  foo => [
    bar  => 'baz',
    baz  => "bar\nbar",
    quux => undef,
  ],
];

my $expected = qr/a = 1
b = 2
c = 3

\[foo\]
bar = baz
baz = << EOH_[\d]
bar
bar
EOH_[\d]
/;

like(
  $W->write_string($starting_first),
  $expected,
  'stringifying AOA, _ first',
);

like(
  $W->new->write_string($starting_first),
  $expected,
  'stringifying AOA, _ first, object method',
);

