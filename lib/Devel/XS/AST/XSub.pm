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
    # list of Devel::XS::AST::XSub::Args
    args    => sub { Devel::XS::AST::Element::Container->new; },
    no_return => 0,
  };


sub push_arg {

    my $self = shift;

    $self->args->push( @_ );

}

1;
