package Devel::XS::AST::XSub;

use strict;
use warnings;

use base 'Devel::XS::AST::Element::Container';

use Class::Tiny qw[ decl return_type class func_name ],
    {
     context => sub { [] },
     args    => sub { [] },
    };

1;
