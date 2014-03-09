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
    stack          => sub { [] },
    _line          => sub { Devel::ParseXS::Stream::Line->new },
    _lastline      => sub { Devel::ParseXS::Stream::Line->new },
    _ungetline     => 0,
    logical_record => 0,
    clean_record   => 0,
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
    my $attr = 'HASH' eq ref $_[-1] ? pop : {};

    if ( defined( my $contents = $self->_line->contents ) ) {
        ( @_ ? $_[0] : $_ ) = ${$contents};
        return 1;
    }

    return ( @_ ? $_[0] : $_ ) = undef;
}


sub _readline {

    my $self = shift;
    my $attr = 'HASH' eq ref $_[-1] ? pop : {};

    my %attr = ( logical_record => $self->logical_record,
		 clean_record   => $self->clean_record,
		 %$attr );

    $attr{logical_record} = 1 if $attr{continue_record};

    # if asked to extend existing line which isn't continued, just
    # return the existing one.
    if ( $attr{continue_record} && ${ $self->_line->contents } !~ /\\$/ ) {

        ( @_ ? $_[0] : $_ ) = ${ $self->_line->contents };
        return 1;

    }

    my $line;

    while ( my $stream = $self->stream ) {

        # use the last line if we're extending rather than reading in
        # a new one. because of the check above, it's guaranteed to be defined,
        # and we won't mistakenly switch to another stream.
        $line
          = $attr{continue_record}
          ? ${ $self->_line->contents } . "\n"
          : CORE::readline( $stream->fh );

        if ( $line ) {

            if ( !$attr{continue_record} ) {
                # update lastline
                $self->swap_lines;

                # save line number before reading possible continuation records
                $self->_line->lineno( $stream->fh->input_line_number );
                $self->_line->stream( $stream );
            }

            # read further lines in if they end with a \ and
            # logical_record is true
            if ( $attr{logical_record} && $line =~ /\\$/ ) {

                # avoid repeated concatenations
                my @lines;
                do {

                    push @lines, scalar CORE::readline( $stream->fh );

                } while defined $lines[-1] && $lines[-1] =~ /\\$/;

                pop @lines if !defined $lines[-1];

		if ( $attr{clean_record} ) {
		    do { s/\\$//; chomp } foreach $line, @lines;
		}

                $line = join( '', $line, @lines );
            }

            chomp $line;
            $self->_line->contents( \$line );

            ( @_ ? $_[0] : $_ ) = $line;
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

    return ( @_ ? $_[0] : $_ ) = undef;
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
      :                                    undef;

}

1;

__END__

=head1 NAME

Devel::ParseXS::Stream - manage input streams for Devel::ParseXS

=head1 SYNOPSIS

  use Devel::ParseXS::Stream;

  my $stream = Devel::ParseXS::Stream->new;

  # open a file
  $stream->open_file( $file_name );

  # open a pipe
  $stream->open_pipe( $command_string );

  # auto-detect file or pipe
  $stream->open( $input );

  # get some input
  $stream->readline;

  # reuse the last input line
  $stream->ungetline

  # update the last line read
  $stream->pushline

=head1 DESCRIPTION

B<Devel::ParseXS::Stream> handles input for B<Devel::ParseXS>,
providing transparent access to nested streams, maintaining line and
file information and allowing some manipulation of the input stack.

XS input streams may contain embedded streams (specified via the
C<INCLUDE> directive). Those streams may come from files or from the
output of another command.  Parsing the stream may require
backtracking or altering the stream's contents.  This module sees to
it that the parsing code sees a continuous input stream.

=head2 Managing streams

The C<open>, C<open_file>, or C<open_pipe> open a new stream for
input.  They do not close an existing stream, rather they switch to
the new stream.  Input is read from there until it is empty, at which
point input is read from the previous stream.  There are no limits
placed upon the number of streams open at once (other than what is
allowed by the operating system).


=head2 Logical and Physical records

The C<readline> method reads either a physical or a logical record
from the current stream.  A logical record is composed of one or more
physical records where all but the last ends in the C<\> (backslash) character.
For example:

  this is\
  a logical record consisting of\
  three lines

To read logical records, set the C<logical_record> flag.

Normally input lines are chomped; by default logical records are
chomped after the physical records are combined, leaving end-of-line markers for
the initial lines intact.  To remove all, set the C<clean_record> flag.

If a line was read in as a physical record, but a logical record
should have been read, one can read the logical record by setting the
re-reading with the C<continue_record> flag set.

=head2 Input History

B<Devel::ParseXS::Stream> keeps track of the filename (or command), line
number, and contents of the current and last lines read.

The current line may be pushed back onto the stream with B<ungetline>
so that it is reread upon the next call to B<readline>.

The B<pushline> method allows one to alter the contents of the next
line to be read (not the filename or line number).  The data for the
last line read are not affected.


=head1 METHODS

Please don't make any use or assumptions about anything which isn't
documented here.  Instead, please contact the author.

=head2 new

  $stream = Devel::ParseXS::Stream->new;

Create a new object.

=head2 open

  $stream->open( $input );

Attach an input stream.  If the passed string ends with a C<|>, it is
assumed to be a command whose output will be used as input.
Otherwise, I<$input> is assumed to be a filename.

=head2 open_file

  $stream->open( $filename );

Open the given file and use it for the subsequent reads.

=head2 open_pipe

  $stream->open_pipe( $command );

Execute the command and use its output for subsequent input.  Don't
append a C<|> to the command.

=head2 readline

  # read into $_
  $stream->readline();

  # read into $_ with attributes
  $stream->readline( $attr);

  # read into $buf
  $stream->readline( $buf );

  # read into $buf with attributes
  $stream->readline( $buf, $attr );

Read a record from the current stream.  If C<$buf> is specified, the
data are placed there, otherwise it will be available in C<$_>.
It returns C<undef> and sets either C<$buf> or C<$_> to C<undef> if
there is no more input.

Records are chomped. Logical records will still contain the
end-of-line markers between the physical records (see the
C<clean_record> attribute).

C<$attr> is a hashref which may contain one or more of the following
attributes:

=over

=item logical_record

If set, read a logical, rather than physical record.

=item clean_record

If set, physical records are individually chomped before being
assembled into a logical record.

=item continue_record

If the last line read was not the end of a logical record, continuing
reading until the end of the logical record is read, appending the
data to the current line buffer.  This will not change the last-line
buffer.

=back

=head2 lineno

  $lineno = $stream->lineno

Returns the line number for the current line.

=head2 lastlineno

  $lastlineno = $stream->lastlineno

Returns the line number for the last line.

=head2 line

  $line = $stream->line

Returns the contents of the current line.

=head2 lastline

  $lastline = $stream->lastline

Returns the contents of the last line.

=head2 filename

  $filename_or_command = $stream->filename

Returns the filename (or the command which was run) for the current
input stream.



=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Smithsonian Astrophysical Observatory

Copyright (C) 2014 Diab Jerius

This program is free software: you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
