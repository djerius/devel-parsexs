package Devel::XS::AST::XSub::Arg;

use parent -norequire => 'Devel::XS::AST::Element';

use strict;
use warnings;

use Class::Tiny
    qw[ name c_type inout_type default length varargs];


1;


