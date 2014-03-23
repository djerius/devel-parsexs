package Devel::XS::AST::Module;

use strict;
use warnings;

use base 'Devel::XS::AST::Element';

use Class::Tiny qw[ module package prefix packid ];

sub BUILD {

    my $self = shift;

    $self->package( '' ) unless defined $self->package;
    $self->prefix(
        defined $self->prefix
        ? quotemeta( $self->prefix )
        : ''
    );

    ( my $packid = $self->package ) =~ tr/:/_/;

    $self->packid( $packid );

    return;
}

1;
