package Devel::ParseXS::Data;

use base 'Devel::ParseXS::Element';

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

    return join( '', @{ $self->contents } );
}

1;
