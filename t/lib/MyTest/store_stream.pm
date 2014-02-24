#!perl

package MyTest::store_stream;

use strict;
use warnings;


use Class::Tiny {

    dollar_    => sub { [] },
    line       => sub { [] },
    lineno     => sub { [] },
    lastline   => sub { [] },
    lastlineno => sub { [] },
};

sub store {

    my ( $self, $s ) = @_;

    push @{ $self->dollar_ },    $_;
    push @{ $self->line },       $s->line;
    push @{ $self->lineno },     $s->lineno;
    push @{ $self->lastline },   $s->lastline || "\n";
    push @{ $self->lastlineno }, $s->lastlineno || 0;

}

sub as_string {

    my $self = shift;

    return {
        dollar_    => join( '',   @{ $self->dollar_ } ),
        line       => join( '',   @{ $self->line } ),
        lineno     => join( "\n", @{ $self->lineno }, '' ),
        lastline   => join( '',   @{ $self->lastline } ),
        lastlineno => join( "\n", @{ $self->lastlineno }, '' ),
    };

}

1;

