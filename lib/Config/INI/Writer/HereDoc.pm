use strict;
use warnings;
package Config::INI::Writer::HereDoc;
# ABSTRACT: a Config::INI::Writer subclass that handles heredoc-style values.

use parent qw(Config::INI::Writer);

=head1 SYNOPSIS

If <$hash> contains:

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

Then when your program contains:

  Config::INI::Writer::HereDoc->write_file($hash, 'family.ini');

F<family.ini> will contains:

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

=head1 DESCRIPTION

Config::INI::Writer::HereDoc is a subclass of L<Config::INI::Writer> that
handles values with embedded newlines by writing them out in heredoc format.

=head1 SUBCLASSED METHODS

These methods extend behavior from L<Config::INI::Writer>.

=head2 invalid_value_regexp

  Carp::croak "value contains illegal character"
    if $value =~ $writer->invalid_value_regexp();

=cut

sub invalid_value_regexp { qr/(?:\s;|^\s|\s$)/ }

=head2 stringify_value_assignment

  my $string = $writer->stringify_value_assignment($name => $value);

This method returns a string that assigns a value to a named property.  If the
value is undefined, an empty string is returned.

=cut

sub stringify_value_assignment {
  my ($self, $name, $value) = @_;

  return '' unless defined $value;

  return $name . ' = ' . $self->stringify_value_as_heredoc($value) . "\n"
    unless (index($value, "\n") < 0);
  
  return $self->SUPER::stringify_value_assignment($name, $value);
}

=head1 METHODS

=head2 next_heredoc_terminator

  my $terminator = $writer->next_heredoc_terminator();

This method returns a unique string that can be used to terminate a
heredoc.

=cut

our $_heredoc_id = 0;
sub next_heredoc_terminator {
  return "EOH_" . $_heredoc_id++;
}

=head2 stringify_value_as_heredoc

  my $string = $writer->stringify_value_as_heredoc($value);

This method returns the string, in heredoc format, that will represent
the given value in a property assignment.

It uses the L<next_heredoc_terminator> method to generate a unique
heredoc terminator.

=cut

sub stringify_value_as_heredoc {
  my ($self, $value) = @_;
  my $terminator = $self->next_heredoc_terminator;
  return "<< $terminator\n$value\n$terminator";
}

1;
