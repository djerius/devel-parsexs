package Devel::XS::AST::Element;

use strict;
use warnings;

use Carp;

use Class::Tiny
    {
	# additional attributes not managed by class
	attr => sub { {} },
    };


package Devel::XS::AST::Element::Container;

use strict;
use warnings;

use parent -norequire => 'Devel::XS::AST::Element';

use Carp;
use Safe::Isa;


use Class::Tiny
    {
	contents => sub { [] },
    };

sub push {

    my $self = shift;

    croak( "attempt to push a non Devel::XS::AST::Element\n" )
	if grep { ! $_->$_isa( 'Devel::XS::AST::Element' ) } @_;

    push @{ $self->contents }, @_;

    return;
}

sub last {

    return $_[0]->contents->[-1];

}

sub count {

    return scalar @{ $_[0]->contents };

}

1;
