package Devel::XS::AST::Element::Container;

use strict;
use warnings;

use parent 'Devel::XS::AST::Element';

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

__END__


=head1 NAME

Devel::XS::AST::Element::Container - A set of Devel::XS::AST::Element objects

=head1 SYNOPSIS

  use Devel::XS::AST::Element::Container;
  $c = Devel::XS::AST::Element::Container->new( contents => \@contents );

  $c->push( $element );


=head1 DESCRIPTION

B<Devel::XS::AST::Element::Container> is a subclass of
B<L<Devel::XS::AST::Element>> which is meant to contain a set of them.

The contained elements are stored in first-in, last-out order.

=head1 METHODS

Please don't make any use or assumptions about anything which isn't
documented here.  Instead, please contact the author.

=head2 new

  $c = Devel::XS::AST::Element::Container->new( attributes );

Construct a new object from the passed I<attributes>, which may be
either a hashref or a list of key-value pairs.

In addition to the attributes provided by B<L<Devel::XS::AST::Element>>, the following are available:

=over

=item contents

A arrayref containing B<Devel::XS::AST::Element> objects.

=back

=head2 count

  $n = $c->count;

The number of elements stored in the object

=head2 last

  $last = $c->last;

The last object stored in the container.

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Smithsonian Astrophysical Observatory

Copyright (C) 2014 Diab Jerius

This program is free software: you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

