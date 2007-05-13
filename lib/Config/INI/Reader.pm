
use strict;
use warnings;

package Config::INI::Reader;

=head1 NAME

Config::INI::Reader - a subclassable .ini-file parser

=head1 VERSION

version 0.004

 $Id$

=cut

our $VERSION = '0.004';

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
slightly different take on the undeniably easy to read ".ini" file format.  Its
default behavior is nearly identical to that of L<Config::Tiny>, on which it is
based.

The chief difference is that Config::INI::Reader is designed to be subclassed
to allow for side-effects and self-reconfiguration to occur during the course
of reading its input.

=head1 SUBCLASSING

There are three reader methods, C<read_string>, C<read_file>, and
C<read_handle>.  The first two are implemented in terms of the third.  It
iterates over lines in a file, calling methods on the reader when events occur.
Those events are either C<change_section>, which occurs when a C<[section]>
line is read; or C<set_value>, which occurs when a value assignment is read.

All of the reader methods return an unblessed reference to a hash.

All throw an exception when they encounter an error.

=cut

use Carp ();
use IO::File;
use IO::String;

=head1 METHODS

=head2 read_file

  my $hash_ref = Config::INI::Reader->read($filename);

Given a filename, this method returns a hashref of the contents of that file.

=cut

sub read_file {
	my ($invocant, $filename) = @_;

	# Check the file
  Carp::croak "no filename specified" unless $filename;
  Carp::croak "file '$filename' does not exist" unless -e $filename;
	Carp::croak "'$filename' is not a plain file" unless -f _;

	# Slurp in the file
  my $handle = IO::File->new($filename, '<')
    or Carp::croak "couldn't read file '$filename': $!";

	$invocant->read_handle($handle);
}

=head2 read_string

  my $hash_ref = Config::INI::Reader->read_string($string);

Given a string, this method returns a hashref of the contents of that string.

=cut

# Create an object from a string
sub read_string {
	my ($invocant, $string) = @_;

  Carp::croak "no string provided" unless defined $string;

  my $handle = IO::String->new($string);

  $invocant->read_handle($handle);
}

=head2 read_handle

  my $hash_ref = Config::INI::Reader->read_handle($io_handle);

Given an IO::Handle, this method returns a hashref of the contents of that
handle.

=cut

sub read_handle {
  my ($invocant, $handle) = @_;

  my $self = ref $invocant ? $invocant : $invocant->new;

	# parse the file
  LINE: while (local $_ = $handle->getline) {
		# Skip comments and empty lines
		next LINE if /\A\s*(?:\#|\;|$)/;

		# Remove inline comments
		s/\s+#\s.+$//g;

		# Handle section headers
		if ( /^\s*\[\s*(.+?)\s*\]\s*$/ ) {
			# Create the sub-hash if it doesn't exist.
			# Without this sections without keys will not
			# appear at all in the completed struct.
      $self->change_section($1);
			next LINE;
		}

		# Handle properties
		if ( /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ ) {
			$self->set_value($1, $2);
			next;
		}

    my $lineno = $handle->input_line_number;
		Carp::croak "Syntax error at line $lineno: '$_'";
	}

	return $self->{data};
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
  $self->{data}{$section} ||= {};
}

=head2 set_value

  $reader->set_value($name, $value);

This method is called whenever an assignment occurs in the file.  The default
behavior is to change the value of the named property to the given value.

=cut

sub set_value {
  my ($self, $name, $value) = @_;

  $self->{data}{ $self->{section} }{ $name } = $value;
}

=head2 starting_section

  my $section = Config::INI::Reader->starting_section;

This method returns the name of the starting section.  The default is: C<_>

=cut

sub starting_section { '_' }

=head2 new

  my $reader = Config::INI::Reader->new;

This method returns a new reader.  This generally does not need to be called by
anything but the various C<read_*> methods, which create a reader object only
ephemerally.

=cut

sub new {
  my ($class) = @_;

  my $self = {
    data    => {},
    section => $class->starting_section,
  };

  bless $self => $class;
}

# # Save an object to a file
# sub write {
# 	my $self = shift;
# 	my $file = shift or return $self->_error(
# 		'No file name provided'
# 		);
# 
# 	# Write it to the file
# 	open( CFG, '>' . $file ) or return $self->_error(
# 		"Failed to open file '$file' for writing: $!"
# 		);
# 	print CFG $self->write_string;
# 	close CFG;
# }
# 
# # Save an object to a string
# sub write_string {
# 	my $self = shift;
# 
# 	my $contents = '';
# 	foreach my $section ( sort { (($b eq '_') <=> ($a eq '_')) || ($a cmp $b) } keys %$self ) {
# 		my $block = $self->{$section};
# 		$contents .= "\n" if length $contents;
# 		$contents .= "[$section]\n" unless $section eq '_';
# 		foreach my $property ( sort keys %$block ) {
# 			$contents .= $self->property_string($section, $property);
# 		}
# 	}
# 	
# 	$contents;
# }
# 
# sub property_string { "$_[2]=$_[0]->{$_[1]}->{$_[2]}\n" };

=head1 TODO

=over

=item * more tests

=item * Config::INI::Writer, I guess

=back

=head1 AUTHOR

Ricardo SIGNES, C<< E<lt>rjbs@cpan.orgE<gt> >>

Based on L<Config::Tiny>, by Adam Kennedy.

=head1 BUGS

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-INI-Reader>

For other issues, or commercial enhancement or support, contact the author.

=head1 COPYRIGHT

Copyright 2007 Ricardo Signes, all rights reserved.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
