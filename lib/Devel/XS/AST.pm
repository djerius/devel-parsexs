package Devel::XS::AST;

use strict;
use warnings;

use Carp;

use Safe::Isa;

use Class::Tiny {

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

1;
