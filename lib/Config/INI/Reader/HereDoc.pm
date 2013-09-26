use strict;
use warnings;
package Config::INI::Reader::HereDoc;
# ABSTRACT: subclassed .ini-file parser, with here-doc support

use parent qw(Config::INI::Reader);

=head1 SYNOPSIS

If F<family.ini> contains:

  admin = rosey

  [judy]
  awesome = yes
  height = 5' 7"

  [astro]
  awesome = totally
  height = 23"

  [george]
  awesome = << EOH
  Totally!
  He had a flying car!
  EOH
  height = 5' 10"

Then when your program contains:

  my $hash = Config::INI::Reader::HereDoc->read_file('family.ini');

C<$hash> will contain:

  {
    '_'  => { admin => 'rosey' },
    judy => {
      awesome => 'yes',
      height  => q{5' 7"},
    },
    astro   => {
      awesome => 'totally',
      height  => '23"',
    },
    george   => {
      awesome => "Totally!\nHe had a flying car!",
      height  => '5' 10"',
    },
  }

=head1 DESCRIPTION

Config::INI::Reader::HereDoc is a simple subclass of L<Config::INI::Reader>.
It extends the basic reader by adding support for here-doc style value
assignments.

=cut

=head1 SUBCLASSED METHODS

These methods extend behavior from L<Config::INI::Reader>.

=head2 parse_value_assignment

  my ($name, $value) = $reader->parse_value_assignment($line, $handle);

Given a line of input, this method decides whether the line is a property
value assignment.  If it is, it returns the name of the property and the value
being assigned to it.  If the line is not a property assignment, the method
returns false.

=cut

sub parse_value_assignment {
  my($self, $line) = @_;
  my($name, $value);

  ($name, $value) =
      $self->parse_heredoc_assignment($line);
  return ($name, $value) if $name;
  ($name, $value) =
      $self->SUPER::parse_value_assignment($line);
  return ($name, $value) if $name;
  return;
}

=head1 METHODS

=head2 parse_heredoc_assignment

  my ($name, $value) = $reader->parse_heredoc_assignment($line, $handle);

Given a line of input, this method decides whether the line is a
heredoc style property value assignment.  If it is, it returns the
name of the property and the value being assigned to it.  If the line
is not a property assignment, the method returns false.

This method will die with a useful error message if it runs out of
input without finding the heredoc terminator.

=cut

sub parse_heredoc_assignment {
  my ($self, $line) = @_;
  my $handle = $self->{handle};
  my $heredoc_starting_line_number = $handle->input_line_number;

  return unless $line =~ /^\s*([^=\s][^=]*?)\s*=\s*<<\s*([^\s]*?)\s*$/;
  my ($name, $terminator) = ($1, $2);

  my $value = '';
  my $saw_terminator;
 HEREDOC:
  while (my $line = $handle->getline) {
    last HEREDOC
      if ($saw_terminator = $self->match_heredoc_terminator($line, $terminator));
    $value .= $line;
  }
  chomp($value);

  die "Ran out of input without finding heredoc terminator (\"$terminator\")," .
    " heredoc began at line $heredoc_starting_line_number"
    unless $saw_terminator;

  return ($name, $value);
}

=head2 match_heredoc_terminator

  my $matched = $reader->match_heredoc_terminator($line, $terminator);

Given a line of input and a terminator string, this method decides
whether the line matches the terminator.  It returns true if the line
matches the terminator, false otherwise.

=cut

sub match_heredoc_terminator {
  return $_[1] =~ /$_[2]$/;
}


1;
