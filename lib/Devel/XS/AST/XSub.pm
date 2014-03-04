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
    _argh    => sub { {} },
    no_return => 0,
  };

sub push_arg {

    my $self = shift;

    my $arg = shift;

    $arg->idx( $self->args->count );

    # not all arguments have names (e.g. length() arguments, or
    # varargs). for those that do make it easy to find them for later tweaking
    # in INPUT sections.
    $self->_argh->{$arg->name} = $arg
	if defined $arg->name;

    $self->args->push( $arg );


}

sub arg {

    my ( $self, $name ) = @_;

    return $self->_argh->{$name};
}

1;
