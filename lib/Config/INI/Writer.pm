
use strict;
use warnings;

package Config::INI::Writer;

use IO::File;

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    return $self;
}

sub write_file {
    my ($invocant, $data, $filename) = @_;
}

sub write_string {
    my ($invocant, $data) = @_;

    my $output = '';

    my $self = ref $invocant ? $invocant : $invocant->new;
    my $root_section_name = $self->default_section;

    my @section_names = grep { $_ ne $root_section_name } keys %{ $data };
    if (my $meth = $self->can('sort_sections')) {
        @section_names = sort { $self->$meth($a, $b) } @section_names;
    }

    if (exists $data->{$root_section_name}) {
        $output .= $self->stringify_props( $data->{$root_section_name} );
    }

    SECTION: for my $section_name (@section_names) {
        my $section_data = $data->{$section_name};

        next SECTION if $self->skip_section($section_name, $section_data);

        $output .= $self->stringify_section($section_name, $section_data);
    }

    return $output;
}

sub write_handle {
    my ($invocant, $data, $handle) = @_;
}

sub stringify_section {
    my ($self, $section_name, $section_data) = @_;

    my $output = $self->stringify_section_name($section_name) . "\n";
    $output .= $self->stringify_props($section_data);

    return $output;
}

sub stringify_props {
    my ($self, $props) = @_;

    my $prop_string = '';

    my @prop_names = keys %{ $props };
    if (my $meth = $self->can('sort_props')) {
        @prop_names = sort { $self->$meth($a, $b) } @prop_names;
    }

    PROP: for my $prop_name (@prop_names) {
        my $prop_value = $props->{$prop_name};

        next PROP if $self->skip_prop($prop_name, $prop_value);

        $prop_string .= $self->stringify_prop($prop_name, $prop_value);
        $prop_string .= "\n";
    }

    return $prop_string;
}

sub stringify_prop {
    my ($self, $prop_name, $prop_value) = @_;

    return $prop_name . '=' . $prop_value;
}

sub skip_section {
    my ($self, $section_name, $section_data) = @_;

    return 0;
}

sub stringify_section_name {
    my ($self, $section_name) = @_;

    return "[${section_name}]";
}

sub skip_prop {
    my ($self, $prop_name, $prop_value) = @_;

    return 0;
}

sub default_section { return '_' }

1;
