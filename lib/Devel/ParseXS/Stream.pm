package Devel::ParseXS::Stream;

use strict;
use warnings;

{

    package Devel::ParseXS::Stream::Line;

    use Class::Tiny qw[ contents lineno stream ];

}

{

    package Devel::ParseXS::Stream::Base;

    use strict;
    use warnings;

    use Class::Tiny qw[ fh filename path ];

    use Carp;

    sub close {

        my $self = shift;

	if ( $self->fh ) {
            my $fh = $self->fh;
            $self->fh( undef );
	    $fh->close
		or croak( "error closing stream @{[ $_[0]->filename ]}\n" );
	}

    }

    sub DEMOLISH {

        my $self = shift;
	$self->close;
    }

}

{
    package Devel::ParseXS::Stream::File;

    use strict;
    use warnings;

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

    use strict;
    use warnings;

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
    stack      => sub { [] },
    _line       => sub { Devel::ParseXS::Stream::Line->new },
    _lastline   => sub { Devel::ParseXS::Stream::Line->new },
    _ungetline => 0,
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

    my $lastline = $self->_lastline;
    $self->_lastline( $self->_line );
    $self->_line( $lastline );

    return;
}

sub ungetline { $_[0]->_ungetline( 1 ) }

# replace the current line buffer with the specified contents and
# unget it.
sub pushline {

    my ( $self, $contents ) = @_;

    $self->_line->contents( \$contents );
    $self->ungetline;

}

sub readline {

    my $self = $_[0];

    goto &_readline
      unless $self->_ungetline;

    $self->_ungetline( 0 );

    shift;

    if ( defined( my $contents = $self->_line->contents ) ) {
        ( @_ ? $_[0] : $_ ) = ${$contents};
        return 1;
    }

    return $_ = undef;
}


sub _readline {

    my $self = shift;

    my $contents;

    while ( my $stream = $self->stream ) {

        if ( $contents = CORE::readline( $stream->fh ) ) {

	    chomp $contents;

            # update lastline
            $self->swap_lines;

            $self->_line->contents( \$contents );
            $self->_line->lineno( $stream->fh->input_line_number );
            $self->_line->stream( $stream );

            ( @_ ? $_[0] : $_ ) = $contents;
            return 1;
        }

        else {

	    $stream->close;
            pop @{ $self->stack };

        }
    }

    $self->swap_lines;

    # easier to just toss the old object.
    $self->_line( Devel::ParseXS::Stream::Line->new );

    return $_ = undef;
}

sub lineno {

    defined $_[0]->_line->lineno
      ? $_[0]->_line->lineno
      : $_[0]->_lastline->lineno;

}

sub lastlineno {

    $_[0]->_lastline->lineno;

}

sub line {

    my $self = shift;

    if ( @_ ) {

	$_[0] = ${ $self->_line->contents };

    }

    else {

	return ${ $self->_line->contents };

    }

    return;
}

sub lastline {

    my $self = shift;

    if ( @_ ) {

	$_[0] = ${ $self->_lastline->contents || \undef };

    }

    else {

	return ${ $self->_lastline->contents || \undef };

    }

    return;
}

sub filename {

        defined $_[0]->_line->stream     ? $_[0]->_line->stream->filename
      : defined $_[0]->_lastline->stream ? $_[0]->_lastline->stream->filename
      :                                   undef;

}

1;







