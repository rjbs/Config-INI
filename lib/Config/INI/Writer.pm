
use strict;
use warnings;

package Config::INI::Writer;

use IO::File;

sub new {
  my ($class) = @_;

  my $self = bless { did_section => {} } => $class;

  return $self;
}

sub write_file {
  my ($invocant, $data, $filename) = @_;
}

sub write_string {
  my ($invocant, $data) = @_;

  my $output = '';

  my $self = ref $invocant ? $invocant : $invocant->new;

  $data = $self->preprocess_data($data);

  my $starting_section_name = $self->starting_section;

  SECTION: for (my $i = 0; $i < $#$data; $i += 2) {
    my ($section_name, $section_data) = @$data[ $i, $i + 1 ];

    $self->change_section($section_name);
    $output .= $self->stringify_section($section_data);
    $self->finish_section($section_name);
  }

  return $output;
}

sub write_handle {
  my ($invocant, $data, $handle) = @_;
}

sub preprocess_data {
  my ($self, $data) = @_;

  return $data if ref $data eq 'ARRAY';

  my @new_data;

  my $starting_section_name = $self->starting_section;

  for (
    $starting_section_name,
    grep { $_ ne $starting_section_name } keys %$data
  ) {
    push @new_data,
      ($_ => (ref $data->{$_} eq 'HASH') ? [ %{ $data->{$_} } ] : $data->{$_});
  }

  return \@new_data;
}

sub change_section {
  my ($self, $section_name) = @_;

  $self->{current_section} = $section_name;
}

sub finish_section {
  my ($self, $section_name) = @_;
  return $self->{did_section}{ $section_name }++;
}

sub did_section {
  my ($self, $section_name) = @_;
  return $self->{did_section}{ $section_name };
}

sub done_sections {
  my ($self) = @_;
  return keys %{ $self->{did_section} };
}

sub current_section {
  my ($self) = @_;
  return $self->{current_section};
}

sub stringify_section {
  my ($self, $section_data) = @_;

  my $output = '';

  my $current_section_name  = $self->current_section;
  my $starting_section_name = $self->starting_section;

  unless (
    $starting_section_name
    and $starting_section_name eq $current_section_name
    and ! $self->done_sections
    and ! $self->explicit_starting_header
  ) {
    $output .= $self->stringify_section_header($self->current_section);
  }

  $output .= $self->stringify_section_data($section_data);

  return $output;
}

sub stringify_section_data {
  my ($self, $values) = @_;

  my $output = '';

  for (my $i = 0; $i < $#$values; $i += 2) {
    $output .= $self->stringify_value_assignment(@$values[ $i, $i + 1]);
  }

  return $output;
}

sub stringify_value_assignment {
  my ($self, $name, $value) = @_;

  return '' unless defined $value;
  return $name . ' = ' . $self->stringify_value($value) . "\n";
}

sub stringify_value {
  my ($self, $value) = @_;

  return defined $value ? $value : '';
}

sub stringify_section_header {
  my ($self, $section_name) = @_;

  my $output  = '';
     $output .= "\n" if $self->done_sections;
     $output .= "[$section_name]\n";

  return $output;
}

sub starting_section { return '_' }

sub explicit_starting_header { 0 }

1;