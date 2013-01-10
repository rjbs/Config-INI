#!perl -Tw

use strict;

use IO::File;
use IO::String;
use Test::More tests => 8;

# Check their perl version
use_ok('Config::INI::Reader');

# Try to read in a config
my $hashref = Config::INI::Reader->read_file( 'examples/simple.ini' );
isa_ok($hashref, 'HASH', "return of Config::INI::Reader->read_file");

# Check the structure of the config
my $expected = {
  '_' => {
    root => 'something',
  },
  section => {
    one   => 'two',
    Foo   => 'Bar',
    this  => 'Your Mother!',
    blank => '',
    moo   => 'kooh',
  },
  'Section Two' => {
    'something else' => 'blah',
    'remove' => 'whitespace',
  },
};

is_deeply($hashref, $expected, 'Config structure matches expected');

# Add some stuff to the trivial config and check write_string() for it
my $Trivial = {};
$Trivial->{_} = { root1 => 'root2' };
$Trivial->{section} = {
  foo   => 'bar',
  this  => 'that',
  blank => '',
};
$Trivial->{section2} = {
  'this little piggy' => 'went to market'
};

my $string = <<END;
root1=root2

[ section ]
blank=
foo=bar
this=that

[section2]
this little piggy=went to market
END

{ # Test read_string
  my $hashref = Config::INI::Reader->read_string( $string );
  isa_ok($hashref, 'HASH', "return of Config::INI::Reader->read_string");

  is_deeply( $hashref, $Trivial, '->read_string returns expected value' );
}

{ # Test read_handle
  my $fh = IO::File->new('examples/simple.ini', 'r');
  my $data = do { local $/ = undef; <$fh> };

  is_deeply(
    Config::INI::Reader->new->read_handle( IO::String->new($data) ),
    $expected,
    '->read_handle returns expected value'
  );
}

# Make sure that here docs work
my $here_hashref = Config::INI::Reader->read_file( 'examples/here-doc.ini' );
isa_ok($here_hashref, 'HASH', "return Config...->read_file(here-doc.ini)");

# Check the structure of the config
my $here_expected = {
  '_' => {
    root => 'something',
  },
  section => {
    zero  => "",
    one   => "one is a fine number, it is always first in line!",
    two   => "two is also a fine\nwith more than one line!",
    whitespace  => "test some whitespace around the heredoc terminator.",
    blank => '',
  },
};

is_deeply($here_hashref, $here_expected,
          'Config structure w/ heredoc matches expected');

{
  my $fubar_string = <<END;
a = b
c = <<EOH
now is the time
for something or other
END
  my $hashref;
  eval { $hashref = Config::INI::Reader->read_string( $fubar_string ); };
  like($@, qr/Ran out of input.*\("EOH"\)/,
       "Heredoc without a terminator dies as expected");
}
         

#####################################################################
# Bugs that happened we don't want to happen again

{
  # Reading in an empty file, or a defined but zero length string, should yield
  # a valid, but empty, object.
  my $empty = Config::INI::Reader->read_string('');
  is_deeply($empty, {}, "an empty string gets an empty hashref");
}

{
  # "0" is a valid section name
  my $config = Config::INI::Reader->read_string("[0]\nfoo = 1\n");
  is_deeply(
    $config,
    { 0 => { foo => 1 } },
    "we can use 0 as a section name",
  );
}
