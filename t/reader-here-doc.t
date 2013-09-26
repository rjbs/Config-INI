#!perl -Tw

use strict;

use IO::File;
use IO::String;
use Test::More tests => 4;

# Check their perl version
use_ok('Config::INI::Reader::HereDoc');

# Make sure that here docs work
my $here_hashref =
   Config::INI::Reader::HereDoc->read_file( 'examples/here-doc.ini' );
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
  eval { $hashref = Config::INI::Reader::HereDoc->read_string( $fubar_string ); };
  like($@, qr/Ran out of input.*\("EOH"\)/,
       "Heredoc without a terminator dies as expected");
}
