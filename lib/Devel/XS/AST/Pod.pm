package Devel::XS::AST::Pod;

use strict;
use warnings;

use base 'Devel::XS::AST::Element';

use Class::Tiny
  { contents => sub { [] } } ;


sub as_string {

    my $self = shift;

    return join( "\n", @{ $self->contents }, @{$self->contents} ? '' : ()  );
}

1;
