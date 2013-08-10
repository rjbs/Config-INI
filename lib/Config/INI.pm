use strict;
use warnings;
package Config::INI;
# ABSTRACT: simple .ini-file format

=head1 SYNOPSIS

Config-INI comes with code for reading F<.ini> files:

  my $config_hash = Config::INI::Reader->read_file('config.ini');

...and for writing C<.ini> files:

  Config::INI::Writer->write_file({ somekey => 'somevalue' }, 'config.ini');

See L<Config::INI::Writer> and L<Config::INI::Reader> for more examples.

=head1 GRAMMAR

This section describes the format parsed and produced by Config::INI::Reader
and ::Writer.  It is not an exhaustive and rigorously tested formal grammar,
it's just a description of this particular implementation of the
not-quite-standardized "INI" format.

  ini-file   = { <section> | <empty-line> }

  empty-line = [ <space> ] <line-ending>

  section        = <section-header> { <value-assignment> | <empty-line> }

  section-header = [ <space> ] "[" <section-name> "]" [ <space> ] <line-ending>
  section-name   = string

  value-assignment = [ <space> ] <property-name> [ <space> ]
                     "="
                     [ <space> ] <value> [ <space> ]
                     <line-ending>
  property-name    = string-without-equals
  value            = string

  comment     = <space> ";" [ <string> ]
  line-ending = [ <comment> ] <EOL>

  space = ( <TAB> | " " ) *
  string-without-equals = string - "="
  string = ? 1+ characters; not ";" or EOL; begins and ends with non-space ?

Of special note is the fact that I<no> escaping mechanism is defined, meaning
that there is no way to include an EOL or semicolon (for example) in a value,
property name, or section name.  If you need this, either subclass, wait for a
subclass to be written for you, or find one of the many other INI-style parsers
on the CPAN.

The order of sections and value assignments within a section are not
significant, except that given multiple assignments to one property name within
a section, only the final one is used.  A section name may be used more than
once; this will have the identical meaning as having all property assignments
in all sections of that name in sequence.

=head1 DON'T FORGET

The definitions above refer to the format used by the Reader and Writer classes
bundled in the Config-INI distribution.  These classes are designed for easy
subclassing, so it should be easy to replace their behavior with whatever
behavior your want.

Patches, feature requests, and bug reports are welcome -- but I'm more
interested in making sure you can write a subclass that does what you need, and
less in making Config-INI do what you want directly.

=head1 THANKS

Thanks to Florian Ragwitz for improving the subclassability of Config-INI's
modules, and for helping me do some of my first merging with git(7).

=head1 ORIGIN

Originaly derived from L<Config::Tiny>, by Adam Kennedy.

=cut

1;
