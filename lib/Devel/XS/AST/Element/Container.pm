package Devel::XS::AST::Element::Container;

use strict;
use warnings;

use parent 'Devel::XS::AST::Element::MixedBag';

use Carp;
use Safe::Isa;

sub CLASS { 'Devel::XS::AST::Element' }

sub BUILD {

    my $self = shift;

    croak( "contents array must contain only objects of class @{[ $self->CLASS ]}\n" )
	if grep { !$_->$_isa( $self->CLASS ) } @{ $self->contents };

    return;
}

sub push {

    my $self = shift;

    croak( "attempt to push something not an object of @{[ $self->CLASS ]}\n" )
	if grep { ! $_->$_isa( $self->CLASS ) } @_;

    $self->SUPER::push( @_ );

    return;
}

sub unshift {

    my $self = shift;

    croak( "attempt to unshift something not an object of @{[ $self->CLASS ]}\n" )
	if grep { ! $_->$_isa( $self->CLASS ) } @_;

    $self->SUPER::unshift( @_ );

    return;
}


1;

__END__


=head1 NAME

Devel::XS::AST::Element::Container - A set of Devel::XS::AST::Element objects

=head1 SYNOPSIS

  use Devel::XS::AST::Element::Container;
  $c = Devel::XS::AST::Element::Container->new( contents => \@contents );

=head1 DESCRIPTION

B<Devel::XS::AST::Element::Container> is a subclass of
B<L<Devel::XS::AST::Element::MixedBag>>.  It can only store
objects of class B<L<Devel::XS::AST::Element>>.

The contained elements are stored in first-in, last-out order.

=head1 METHODS

See B<L<Devel::XS::AST::Element::MixedBag>> for more information.

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Smithsonian Astrophysical Observatory

Copyright (C) 2014 Diab Jerius

This program is free software: you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

