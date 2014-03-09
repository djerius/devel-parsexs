package Devel::XS::AST::Element;

use strict;
use warnings;

use Carp;

use Class::Tiny
    {
	# additional attributes not managed by class
	attr => sub { {} },
    };

1;
=head1 NAME

Devel::XS::AST::Element - A generic Devel::XS::AST component

=head1 SYNOPSIS

  use parent 'Devel::XS::AST::Element::Container';


=head1 DESCRIPTION

B<Devel::XS::AST::Element> represents a generic Devel::XS::AST
component.  It is not meant to be used directly, but as a parent
class.

=head1 METHODS

Please don't make any use or assumptions about anything which isn't
documented here.  Instead, please contact the author.

=head2 new

  $c = Devel::XS::AST::Element->new( attributes );

Construct a new object from the passed I<attributes>, which may be
either a hashref or a list of key-value pairs.

The following attributes are available:

=over

=item attr

A hashref containing arbitrary data.  Use this to store out-of-band
data, or whatever you'd like. B<Devel::XS::AST> doesn't care what goes
here.

=back


=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Smithsonian Astrophysical Observatory

Copyright (C) 2014 Diab Jerius

This program is free software: you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

