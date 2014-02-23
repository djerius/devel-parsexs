package Devel::ParseXS::Element;

use strict;
use warnings;

use Carp;

use Class::Tiny qw[ lineno stream ];


sub BUILD {

    my $self = shift;

    my @missing = grep { ! defined $self->{$_} }
	Class::Tiny->get_all_attributes_for( __PACKAGE__ );

    croak( "missing attribute(s) for object of class @{[ ref $self ]}: @missing\n" ) if @missing;

}

1;
