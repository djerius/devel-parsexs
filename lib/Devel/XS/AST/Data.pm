package Devel::XS::AST::Data;

use strict;
use warnings;

use base 'Devel::XS::AST::Element';

use Class::Tiny  {
    contents => sub { [] }
};

sub push {

    my $self = shift;

    push @{$self->contents}, @_;

    return;
}


sub as_string {

    my $self = shift;

    return join( "\n", @{ $self->contents }, @{$self->contents} ? '' : ()  );
}

1;
