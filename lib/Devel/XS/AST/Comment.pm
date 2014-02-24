package Devel::XS::AST::Comment;

use strict;
use warnings;

use base 'Devel::XS::AST::Element';

use Class::Tiny  {
    contents => sub { [] }
};

sub as_string {

    my $self = shift;

    return join( '', @{ $self->contents } );
}

1;
