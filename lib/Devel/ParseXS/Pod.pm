package Devel::ParseXS::Pod;

use base 'Devel::ParseXS::Element';

use Class::Tiny
  qw[ filename line_no],
  { contents => sub { [] } } ;


sub as_string {

    my $self = shift;

    return join( '', @{ $self->contents } );
}

1;
