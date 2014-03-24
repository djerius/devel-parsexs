package Devel::XS::AST::XSub;

use strict;
use warnings;

use base 'Devel::XS::AST::Element::Container';
use Devel::XS::AST::Element::ArgList;

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
    args    => sub { Devel::XS::AST::Element::ArgList->new; },
    _argh    => sub { {} },
    no_return => 0,
  };

sub BUILD {

    my $self = shift;

    if ( $self->args->count ) {

	$self->_register_arg( $self->args->element( $_ ), $_ )
	    for 0 .. ($self->args->count - 1);

    }


}


sub _register_arg {


    my ( $self, $arg, $idx ) = @_;

    $arg->idx( $idx );

    # not all arguments have names (e.g. length() arguments, or
    # varargs). for those that do make it easy to find them for later tweaking
    # in INPUT sections.
    $self->_argh->{$arg->name} = $arg
	if defined $arg->name;

    return;
}


sub push_arg {

    my ( $self, $arg ) = @_;

    $self->_register_arg( $arg, $self->args->count );

    $self->args->push( $arg );

    return;
}

sub arg {

    my ( $self, $name ) = @_;

    return $self->_argh->{$name};
}

1;
