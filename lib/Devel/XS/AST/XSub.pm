package Devel::XS::AST::XSub;

use strict;
use warnings;

use base 'Devel::XS::AST::Element::Container';

use Class::Tiny
  qw[
	externC
	static
	decl
	return_type
	class
	func_name
	perl_name
	full_func_name
   ],
  {
    context => sub { [] },
    args    => sub { [] },
    no_return => 0,
  };

1;
