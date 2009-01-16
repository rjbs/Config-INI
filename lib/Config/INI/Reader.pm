use strict;
use warnings;
package Config::INI::Reader;
use Mixin::Linewise::Readers;

=head1 NAME

Config::INI::Reader - a subclassable .ini-file parser

=head1 VERSION

version 0.014

=cut

our $VERSION = '0.014';

=head1 SYNOPSIS

If F<family.ini> contains:

  admin = rjbs

  [rjbs]
  awesome = yes
  height = 5' 10"

  [mj]
  awesome = totally
  height = 23"

Then when your program contains:

  my $hash = Config::INI::Reader->read_file('family.ini');

C<$hash> will contain:

  {
    '_'  => { admin => 'rjbs' },
    rjbs => {
      awesome => 'yes',
      height  => q{5' 10"},
    },
    mj   => {
      awesome => 'totally',
      height  => '23"',
    },
  }

=head1 DESCRIPTION

Config::INI::Reader is I<yet another> config module implementing I<yet another>
slightly different take on the undeniably easy to read L<".ini" file
format|Config::INI>.  Its default behavior is quite similar to that of
L<Config::Tiny>, on which it is based.

The chief difference is that Config::INI::Reader is designed to be subclassed
to allow for side-effects and self-reconfiguration to occur during the course
of reading its input.

=cut

use Carp ();
use IO::File;
use IO::String;

=head1 METHODS FOR READING CONFIG

These methods are all that most users will need: they read configuration from a
source of input, then they return the data extracted from that input.  There
are three reader methods, C<read_string>, C<read_file>, and C<read_handle>.
The first two are implemented in terms of the third.  It iterates over lines in
a file, calling methods on the reader when events occur.  Those events are
detailed below in the L</METHODS FOR SUBCLASSING> section.

All of the reader methods return an unblessed reference to a hash.

All throw an exception when they encounter an error.

=head2 read_file

  my $hash_ref = Config::INI::Reader->read_file($filename);

Given a filename, this method returns a hashref of the contents of that file.

=head2 read_string

  my $hash_ref = Config::INI::Reader->read_string($string);

Given a string, this method returns a hashref of the contents of that string.

=head2 read_handle

  my $hash_ref = Config::INI::Reader->read_handle($io_handle);

Given an IO::Handle, this method returns a hashref of the contents of that
handle.

=cut

sub read_handle {
  my ($invocant, $handle) = @_;

  my $self = ref $invocant ? $invocant : $invocant->new;

  # parse the file
  LINE: while (my $line = $handle->getline) {
    next LINE if $self->can_ignore($line);

    $self->preprocess_line(\$line);

    # Handle section headers
    if (defined (my $name = $self->parse_section_header($line))) {
      # Create the sub-hash if it doesn't exist.
      # Without this sections without keys will not
      # appear at all in the completed struct.
      $self->change_section($name);
      next LINE;
    }

    if (my ($name, $value) = $self->parse_value_assignment($line)) {
      $self->set_value($name, $value);
      next;
    }

    my $lineno = $handle->input_line_number;
    Carp::croak "Syntax error at line $lineno: '$line'";
  }

  $self->finalize;

  return $self->{data};
}

=head1 METHODS FOR SUBCLASSING

These are the methods you need to understand and possibly change when
subclassing Config::INI::Reader to handle a different format of input.

=head2 current_section

  my $section_name = $reader->current_section;

This method returns the name of the current section.  If no section has yet
been set, it returns the result of calling the C<starting_section> method.

=cut

sub current_section {
  defined $_[0]->{section} ? $_[0]->{section} : $_[0]->starting_section;
}

=head2 parse_section_header

  my $name = $reader->parse_section_header($line);

Given a line of input, this method decides whether the line is a section-change
declaration.  If it is, it returns the name of the section to which to change.
If the line is not a section-change, the method returns false.

=cut

sub parse_section_header {
  return $1 if $_[1] =~ /^\s*\[\s*(.+?)\s*\]\s*$/;
  return;
}

=head2 change_section

  $reader->change_section($section_name);

This method is called whenever a section change occurs in the file.

The default implementation is to change the current section into which data is
being read and to initialize that section to an empty hashref.

=cut

sub change_section {
  my ($self, $section) = @_;

  $self->{section} = $section;

  if (!exists $self->{data}{$section}) {
    $self->{data}{$section} = {};
  }
}

=head2 parse_value_assignment

  my ($name, $value) = $reader->parse_value_assignment($line);

Given a line of input, this method decides whether the line is a property
value assignment.  If it is, it returns the name of the property and the value
being assigned to it.  If the line is not a property assignment, the method
returns false.

=cut

sub parse_value_assignment {
  return ($1, $2) if $_[1] =~ /^\s*([^=\s][^=]*?)\s*=\s*(.*?)\s*$/;
  return;
}

=head2 set_value

  $reader->set_value($name, $value);

This method is called whenever an assignment occurs in the file.  The default
behavior is to change the value of the named property to the given value.

=cut

sub set_value {
  my ($self, $name, $value) = @_;

  $self->{data}{ $self->current_section }{$name} = $value;
}

=head2 starting_section

  my $section = Config::INI::Reader->starting_section;

This method returns the name of the starting section.  The default is: C<_>

=cut

sub starting_section { q{_} }

=head2 can_ignore

  do_nothing if $reader->can_ignore($line)

This method returns true if the given line of input is safe to ignore.  The
default implementation ignores lines that contain only whitespace or comments.

=cut

sub can_ignore {
  my ($self, $line) = @_;

  # Skip comments and empty lines
  return $line =~ /\A\s*(?:;|$)/ ? 1 : 0;
}

=head2 preprocess_line

  $reader->preprocess_line(\$line);

This method is called to preprocess each line after it's read but before it's
parsed.  The default implementation just strips inline comments.  Alterations
to the line are made in place.

=cut

sub preprocess_line {
  my ($self, $line) = @_;

  # Remove inline comments
  ${$line} =~ s/\s+;.*$//g;
}

=head2 finalize

  $reader->finalize;

This method is called when the reader has finished reading in every line of the
file.

=cut

sub finalize { }

=head2 new

  my $reader = Config::INI::Reader->new;

This method returns a new reader.  This generally does not need to be called by
anything but the various C<read_*> methods, which create a reader object only
ephemerally.

=cut

sub new {
  my ($class) = @_;

  my $self = { data => {}, };

  bless $self => $class;
}

=head1 TODO

=over

=item * more tests

=back

=head1 BUGS

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-INI>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Ricardo SIGNES, C<< E<lt>rjbs@cpan.orgE<gt> >>

Originaly derived from L<Config::Tiny>, by Adam Kennedy.

=head1 COPYRIGHT

Copyright 2007, Ricardo SIGNES.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
