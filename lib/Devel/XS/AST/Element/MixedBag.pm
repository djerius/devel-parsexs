package Devel::XS::AST::Element::MixedBag;

use strict;
use warnings;

use parent 'Devel::XS::AST::Element';

use Carp;
use Safe::Isa;


use Class::Tiny
    {
	contents => sub { [] },
    };

sub BUILD {

    my $self = shift;

    'ARRAY' eq ref $self->contents
	or croak( "contents attribute must be an arrayref\n" )

}

sub push {

    my $self = CORE::shift;

    push @{ $self->contents }, @_;

    return;
}

sub shift {

    my $self = CORE::shift;

    return CORE::shift  @{ $self->contents };
}

sub pop {

    my $self = CORE::shift;

    return pop @{ $self->contents };
}

sub unshift {

    my $self = CORE::shift;

    CORE::unshift @{ $self->contents }, @_;

    return;
}


sub first {

    return $_[0]->contents->[0];

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

Devel::XS::AST::Element::MixedBag - A heterogeneous bag of stuff

=head1 SYNOPSIS

  use Devel::XS::AST::Element::MixedBag;
  $c = Devel::XS::AST::Element::MixedBag->new( contents => \@contents );

  $c->push( $element );


=head1 DESCRIPTION

B<Devel::XS::AST::Element::MixedBag> is a subclass of
B<L<Devel::XS::AST::Element>> which is meant to contain a heterogeneous bag
of things.  No restrictions are placed on the contents of the bag.

The contained elements are stored in first-in, last-out order.

=head1 METHODS

Please don't make any use or assumptions about anything which isn't
documented here.  Instead, please contact the author.

=head2 new

  $c = Devel::XS::AST::Element::MixedBag->new( attributes );

Construct a new object from the passed I<attributes>, which may be
either a hashref or a list of key-value pairs.

In addition to the attributes provided by
B<L<Devel::XS::AST::Element>>, the following are available:

=over

=item contents

A arrayref containing stuff.

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

