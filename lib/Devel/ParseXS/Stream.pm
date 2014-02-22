package Devel::ParseXS::Stream;

{

    package Devel::ParseXS::Stream::Line;

    use Class::Tiny qw[ contents lineno stream ];

}

{

    package Devel::ParseXS::Stream::Base;

    use Class::Tiny qw[ fh filename path ];

    use Carp;

    sub DEMOLISH {

        my $self = shift;

        if ( $self->fh ) {
            my $fh = $self->fh( undef );
            $fh->close or croak( "unable to close @{[$self->filename]}: $!\n" );
        }
    }

}

{
    package Devel::ParseXS::Stream::File;

    use parent -norequire => 'Devel::ParseXS::Stream::Base';

    use Carp;

    sub BUILD {

        my $self = shift;

        $self->fh( IO::File->new( $self->filename, 'r' ) )
          or croak( "unable to open @{[ $self->filename ]}: $!\n" );
    }
}

{
    package Devel::ParseXS::Stream::Pipe;

    use parent -norequire => 'Devel::ParseXS::Stream::Base';

    use Carp;

    sub BUILD {

        my $self = shift;

        my $fh;

        open( $fh, '-|', $self->filename )
          or croak( "unable to open pipe to @{[ $self->filename ]}\n" );

        $self->fh( $fh );
    }
}


use Class::Tiny {
    stack    => sub { [] },
    line     => sub { Devel::ParseXS::Stream::Line->new },
    lastline => sub { Devel::ParseXS::Stream::Line->new },
};

sub stream { $_[0]->stack->[-1] }

# generic open
sub open {

    my ( $self, $src ) = @_;

    if ( $src =~ s/\s*\|\s*$// ) {

        $self->open_pipe( $src );

    }

    else {

        $self->open_file( $src );
    }

    return;
}

sub open_file {

    my ( $self, $src ) = @_;

    push @{ $self->stack },
      Devel::ParseXS::Stream::File->new( filename => $src );

    return;
}

sub open_pipe {

    my ( $self, $src ) = @_;

    push @{ $self->stack },
      Devel::ParseXS::Stream::Pipe->new( filename => $src );

    return;
}

sub swap_lines {

    my $self = shift;

    my $lastline = $self->lastline;
    $self->lastline( $self->line );
    $self->line( $lastline );

    return;
}

sub readline {

    my $self = shift;

    while ( my $stream = $self->stream ) {

        if ( my $contents = readline( $stream->fh ) ) {

            # update lastline
            $self->swap_lines;

            $self->line->contents( \$contents );
            $self->line->lineno( $stream->fh->input_line_number );
            $self->line->stream( $stream );

            ( @_ ? $_[0] : $_ ) = $contents;
            return 1;
        }

        else {

            pop @{ $self->stack };

        }
    }

    $self->swap_lines;

    # easier to just toss the old object.
    $self->line( Devel::ParseXS::Stream::Line->new );

    return $_ = undef;
}

sub lineno {

    defined $_[0]->line->lineno
      ? $_[0]->line->lineno
      : $_[0]->lastline->lineno;

}

sub filename {

        defined $_[0]->line->stream     ? $_[0]->line->stream->filename
      : defined $_[0]->lastline->stream ? $_[0]->lastline->stream->filename
      :                                   undef;

}

1;







