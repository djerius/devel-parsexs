package Devel::XS::AST::Data;

use strict;
use warnings;

use base 'Devel::XS::AST::Element::MixedBag';


sub as_string {

    my $self = shift;

    return join( "\n", @{ $self->contents }, @{$self->contents} ? '' : ()  );
}

1;
