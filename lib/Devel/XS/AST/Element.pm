package Devel::XS::AST::Element;

use strict;
use warnings;

use Carp;

use Class::Tiny
    {
	# additional attributes not managed by class
	attr => sub { {} },
    };

1;
