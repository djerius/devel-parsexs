package Devel::ParseXS;

use 5.006;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.01_01';

use Carp;

use Safe::Isa;

use ExtUtils::Typemaps;

use Devel::ParseXS::Stream;

use Devel::XS::AST::Boot;
use Devel::XS::AST::Element::Container;
use Devel::XS::AST::Comment;
use Devel::XS::AST::CPP;
use Devel::XS::AST::Data;
use Devel::XS::AST::Keyword;
use Devel::XS::AST::Module;
use Devel::XS::AST::Pod;
use Devel::XS::AST::Typemap;
use Devel::XS::AST::XSub;
use Devel::XS::AST::XSub::Arg;
use Devel::XS::AST::XSub::Section;

our %Re = (

    COMMENT => qr/^\s*#/,

    # CPP directives:
    #    ANSI:    if ifdef ifndef elif else endif define undef
    #             line error pragma include
    #     gcc:    warning include_next
    #   obj-c:    import
    #  others:    ident (gcc notes that some cpps have this one)
    CPP =>
      qr/^#[ \t]*(?:(?:if|ifn?def|elif|else|endif|define|undef|pragma|error|warning|line\s+\d+|ident)\b|(?:include(?:_next)?|import)\s*["<].*[>"])/,

    POD => qr/^=/,

    MODULE =>
      qr/^MODULE\s*=\s*([\w:]+)(?:\s+PACKAGE\s*=\s*([\w:]+))?(?:\s+PREFIX\s*=\s*(\S+))?\s*$/,

    GKEYWORDS =>
      qr/BOOT|REQUIRE|PROTOTYPES|EXPORT_XSUB_SYMBOLS|FALLBACK|VERSIONCHECK|INCLUDE(?:_COMMAND)?|SCOPE|TYPEMAP/,

    XSUB_SECTION =>
      qr/ALIAS|C_ARGS|CASE|CLEANUP|CODE|INIT|INPUT|INTERFACE(?:_MACRO)?|OVERLOAD|OUTPUT|PPCODE|PREINIT|POSTCALL|PROTOTYPE/,

    # in ExtUtils::ParseXS, a parameter may be within a "C group",
    # where a group is essentially anything in (possibly) nested ({[
    # pairs.  (Actually, they don't have to be paired, just balanced,
    # so [foo) is ok.)  This is its definition:

    #     # Group in C (no support for comments or literals)
    #     $C_group_rex = qr/ [({\[]
    #                  (?: (?> [^()\[\]{}]+ ) | (??{ $C_group_rex }) )*
    #                  [)}\]] /x;

    # I'm not sure _why_ one would write a function declaration as
    #   func_name( [char* name], ( int foo ) )

    # Rather than cargo-cult this, I'm leaving it out until it's
    # proven necessary.

    # here's the definition of a parameter (technically it's a
    # parameter, not an argument)

    #    # Chunk in C without comma at toplevel (no comments):
    #    $C_arg = qr/ (?: (?> [^()\[\]{},"']+ )
    #           |   (??{ $C_group_rex })
    #           |   " (?: (?> [^\\"]+ )
    #             |   \\.
    #             )* "        # String literal
    #                  |   ' (?: (?> [^\\']+ ) | \\. )* ' # Char literal
    #           )* /xs;

    # this isn't that strict (for example, a parameter of 1-2+3/2 would pass),
    # but that's (hopefully) caught later.

    # Removing the $C_group_rex and simplifying the first group, which seems
    # to be a bit more complicated than needed just so that $C_group_rex will be
    # recognized, this is

    XSUB_PARAMETER => qr/ (?:
		    (?> [^,"']+ )                 # not a quoted or a separator
	      |   " (?: (?> [^\\"]+ ) | \\. )* "  # String literal
	      |   ' (?: (?> [^\\']+ ) | \\. )* '  # Char literal
	      )* /xs,


    XSUB_PARAMETER_INOUT =>
      qr/^\s* (IN(?:_OUTLIST|_OUT)? | OUT(?:LIST)?) \b \s*/x,

    BLANK_LINE => qr/^\s*$/

);

use Class::Tiny
  qw[ fh module _context ],
  {
    fh       => sub { Devel::ParseXS::Stream->new },
    tree     => sub { Devel::XS::AST::Element::Container->new },
    _context => sub { [undef] },
  };


sub BUILD {

    my $self = shift;

    $self->context( $self->tree );

}

sub push_context {

    push @{ $_[0]->_context }, $_[1];

    return;
}

sub pop_context {

    my $self = shift;

    my $context = pop @{ $self->_context };

    my $sub = $context->attr->{postprocess}
      && $self->can( $context->attr->{postprocess} );

    $sub->( $self, $context )
      if $sub;


    return;
}

sub context {

    my $self = shift;

    my $context = $self->_context->[-1];

    $self->_context->[-1] = $_[0] if @_;

    return $context;
}


sub stash {

    my $self = shift;

    @_ > 1 && $self->error( 0, "illegal stash of more than one object\n" );

    $self->context->push( $_[0] );

    return;
}

sub stash_data {

    my $self = shift;

    my $context = $self->context;

    my $data;

    if ( $context->last->$_isa( 'Devel::XS::AST::Data' ) ) {

	$data = $context->last;

    }

    else {

        $data = $self->create_ast_element(
            'Data',
            {
                attr     => {
                    lineno => $self->fh->lineno,
                    stream => $self->fh->stream,
                },
            } );

        $self->stash( $data );
    }

    $data->push( @_ );

    return $data;
}

sub parse_file {

    my ( $self, $file ) = @_;

    $self->fh->open( $file );
    $self->parse_header;
    $self->parse_body;

    return;
}

sub parse_header {

    my $self = shift;

    my $fh = $self->fh;

    my $found_module;

    # read until EOF or we hit a MODULE keyword
    while ( $fh->readline ) {

        next if $self->parse_pod;

        $found_module = 1, last if $self->parse_MODULE;

        $self->stash_data( $_ );

    }

    $self->error( 0, "Didn't find a 'MODULE ... PACKAGE ... PREFIX' line\n" )
      unless $found_module;

    return;
}

sub parse_body {

    my $self = shift;

    my $fh = $self->fh;

    # not in an XSUB in this code, so only parse what's legal
    while ( $fh->readline ) {

        next if /^\s*$/;

        next if $self->parse_pod;

        next if $self->parse_comment;

        next if $self->parse_cpp;

        next if $self->parse_keyword;

        next if $self->parse_MODULE;

        # we're now handling an XSUB

        $self->parse_xsub;

    }

    return;
}

sub parse_xsub {

    my $self = shift;

    my $fh = $self->fh;

    my $xsub = $self->create_ast_element(
        'XSub',
        {
            attr => {
                lineno => $fh->lineno,
                stream => $fh->stream,
            },
        } );

    # pay attention to continuation lines. Current line was
    # not read in with the stream set to read logical records; first
    # continue it if it needs it.
    $fh->readline( { continue_record => 1 } );
    $fh->logical_record( 1 );

    $self->parse_declaration( $xsub );

    $self->stash( $xsub );
    $self->push_context( $xsub );

    # first section is implicitly INPUT
    my $input = $self->create_ast_element(
        'XSub::INPUT',
        {
            attr => {
                lineno      => $fh->lineno,
                stream      => $fh->stream,
                postprocess => 'process_INPUT',
            },
        } );
    $self->stash( $input );
    $self->push_context( $input );


    # the next XSUB may start as:
    #
    # <blank line>
    # OPTIONAL <comment>
    # <left adjusted XSUB code>

    # so, keep track of blank lines followed by comments or pod
    my $saw_blank_line = $fh->line =~ $Re{BLANK_LINE};

    while ( $fh->readline ) {

        $fh->ungetline && last if /^\S/ && $saw_blank_line;

        next if $self->parse_pod;

        next if $self->parse_comment;

	$saw_blank_line = $_ =~ $Re{BLANK_LINE};;

        if ( /^\s*($Re{XSUB_SECTION})\s*:\s*(?:#.*)?(.*)/ ) {

            my $section = $self->create_ast_element(
                "XSub::$1",
                {
                    attr => {
                        lineno      => $fh->lineno,
                        stream      => $fh->stream,
                        postprocess => "process_$1",
                    },
                    value => $2
                } );

            $self->pop_context;
            $self->stash( $section );
            $self->push_context( $section );
            next;
        }

        $self->stash_data( $_ );
    }

    # pops XSUB keyword context. either the first implicit INPUT, or
    # one that follows
    $self->pop_context;

    # XSUB context
    $self->pop_context;

    # stop paying attention to continuation lines
    $fh->logical_record( 0 );

    return;
}

sub parse_declaration {

    my ( $self, $xsub ) = ( shift, shift );

    # we accept (in pseudo-regexp)

    #  (NO_OUTPUT\s+)?return_type
    #  (\n)?
    #  ( func_name\( args \) )?


    $xsub->no_return( 1 ) if s/^\s*NO_OUTPUT\s+//;

    # follow ExtUtils::ParseXS's lead of cleaning up the return type
    # before checking for func_name(... )
    my $return_type = ExtUtils::Typemaps::tidy_type( $_ );

    # Try to parse as <return_type> func_name(...)
    # RE's from ExtUtils:ParseXS
    if (
        $return_type =~ /^(.*?\w.*?)          # return type
			 \s*\b(\w+\s*\(.*)   # func_name( args )
			/x
      )
    {

        $return_type = $1;
        # replace original line with func_name(...). this keeps the
        # correct line number
        $self->fh->pushline( $2 );
    }
    $xsub->externC( 1 ) if $return_type =~ s/^extern "C"\s+//;
    $xsub->static( 1 )  if $return_type =~ s/^static\s+//;

    $xsub->return_type( $return_type );

    $self->fh->readline( { clean_record => 1 } )
      or $self->error( 0, "function definition too short\n" );

    # parse class? func_name( parameters ) (const)?
    my $matched = my ( $class, $func_name, $parameters, $const ) = /^
     (?:([\w:]*)::)?  	   # C++ class
     (\w+)            	   # name
     \s*
     \(\s* (.*?) \s*\)     # parameters
     \s*
     (const)?        	   # C++ const
     \s*(;\s*)?      	   # trailing scruff
     $/sx;

    $self->error( 0, "not a function declaration: $_\n" )
      unless $matched;

    $class = "$const $class" if $const;

    $xsub->class( $class );
    $xsub->func_name( $func_name );

    # remove possible prefix and add package name
    ( my $clean_func_name = $func_name ) =~ s/^(@{[ $self->module->prefix ]})?//;
    $xsub->perl_name( join( '::', $self->module->package || (), $clean_func_name ) );
    $xsub->full_func_name( join( '_', $self->module->packid, $clean_func_name ) );

    $self->parse_function_parameters( $xsub, $parameters )
      if $parameters =~ /\S/;

    return;
}

# parse function parameters. passed one big string
sub parse_function_parameters {

    my ( $self, $xsub, $parameters ) = @_;

    my $saved_parameters = $parameters;

    # to make the parsing easier
    $parameters .= ' ,';

    # ExtUtils::ParseXS splits out processing ANSI-C style
    # vs. old-style declarations; the code should be robust enough to
    # handle either.

    if ( $parameters !~ /( $Re{XSUB_PARAMETER} , )* $/x && $parameters =~ /\S/ )
    {

        $self->error( 0,
            "Unable to parse function declarations: $parameters\n" );
    }

    for ( $parameters =~ m/\G ( $Re{XSUB_PARAMETER} ) , /xg ) {

        my $save = $_;

        my ( $inout_type ) = s/$Re{XSUB_PARAMETER_INOUT}//x;
        $inout_type ||= 'IN';

        # param may be assigned a default; strip that out, as
        # well as any extra whitespace
        s/^\s* ( [^=]*? ) \s* (?: = \s* (.*?)\s* )?$/$1/x;
        my $default = $2;

        # param may be 'type (&)?name | name | length(name)'
        my ( $c_type, $pass_addr, $name, $length_name ) = /
		    (.*?)                         # C type
		    \s*
		    (\&?)   			  # pass addr
		    \s*\b (?:
			(\w+)                     # name
		    | length\( \s*(\w+)\s* \)     # length( name )
		    ) \s* $ /x;

        $self->error( 0, "invalid variable definition: $save\n" )
          if length( $pass_addr ) && !( length( $c_type ) && defined $name );

        my %argp = (
            inout_type => $inout_type,
            attr       => {
                lineno => $self->fh->lineno,
                stream => $self->fh->stream,
            },
        );

        if ( defined( $argp{name} = $name ) ) {

            if ( defined $default ) {

                if ( $default eq 'NO_INIT' ) {

                    $argp{optional} = 1;

                }

                elsif ( length $default ) {

                    $argp{default} = $default;

                }

                else {
                    $self->error( 0,
                        "incomplete default specification for '$name'\n" );
                }

            }

            if ( length $c_type ) {
                $argp{c_type} = ExtUtils::Typemaps::tidy_type( $c_type );
                $argp{in_declaration} = 1;
                $argp{pass_addr}      = $pass_addr;
            }

        }
        elsif ( defined( $argp{length_name} = $length_name ) ) {

            $self->error( 0, "Default value on length() argument: '$save'" )
              if defined $default;

        }

        elsif ( $_ eq '...' ) {

            $argp{varargs} = 1;

        }
        else {

            # can we actually get here?
            $self->error( 0,
                "internal error: can't find type or name in argument: '$save'"
            );

        }

        $xsub->push_arg( $self->create_ast_element( 'XSub::Arg', \%argp ) );
    }

    return;
}

sub parse_pod {

    my $self = shift;

    return unless $_ =~ $Re{POD};

    my @pod = ( $_ );

    my $fh = $self->fh;

    my %attr = (
        lineno => $fh->lineno,
        stream => $fh->stream
    );
    while ( $fh->readline ) {
        push @pod, $_;
        last if /^=cut\s*$/;
    }

    $self->error( $attr{lineno}, "unterminated pod starting here\n" )
      if !defined $_;

    $self->stash(
        $self->create_ast_element(
            'Pod',
            {
                attr     => \%attr,
                contents => \@pod
            } ) );

    return 1;
}

sub parse_comment {

    my $self = shift;

    my @comments;

    my $fh = $self->fh;

    my %attr = (
        lineno => $fh->lineno,
        stream => $fh->stream
    );

  LOOP:
    {
        do {

            last if $_ !~ $Re{COMMENT} || $_ =~ $Re{CPP};

            push @comments, $_;

        } while ( $fh->readline );
    }

    if ( @comments ) {
        $self->stash(
            $self->create_ast_element(
                'Comment',
                {
                    attr     => \%attr,
                    contents => \@comments,
                } ) );

        # last line wasn't a comment; put it back
        $fh->ungetline;
        return 1;
    }

    return;
}

sub parse_cpp {

    my $self = shift;

    my $fh = $self->fh;

    my %attr = (
        lineno => $fh->lineno,
        stream => $fh->stream
    );

    if ( $_ =~ $Re{CPP} ) {

        # read logical line if it's there
        $fh->readline( { continue_record => 1 } );

        $self->stash(
            $self->create_ast_element(
                'CPP',
                {
                    attr     => \%attr,
                    contents => [$_],
                } ) );

        return 1;
    }

    return;
}

sub parse_keyword {

    my ( $self, $re ) = @_;

    $re = $Re{GKEYWORDS}
	unless defined $re;

    return
      unless my ( $kwd, $arg ) = /^\s*($re)\s*:\s*(?:#.*)?(.*)/;

    my $handler = 'handle_' . $kwd;

    return $self->$handler( $arg )
      if $self->can( $handler );

    $self->stash(
        $self->create_ast_element(
            'Keyword',
            {
                attr => {
                    lineno => $self->fh->lineno,
                    stream => $self->fh->stream,
                },
                keyword => $kwd,
                arg     => $arg,
            } ) );

    return 1;
}

sub parse_MODULE {

    my $self = shift;

    return
      unless my ( $module, $package, $prefix ) = $_ =~ $Re{MODULE};

    my %attr = (
        lineno => $self->fh->lineno,
        stream => $self->fh->stream
    );

    $self->module(
        $self->create_ast_element(
            'Module',
            {
                attr    => \%attr,
                module  => $module,
                package => $package,
                prefix  => $prefix,
            } ) );

    $self->stash( $self->module );

    return 1;
}

sub handle_BOOT {

    # ignore any arguments
    my $self = shift;

    my $fh = $self->fh;

    my $boot = $self->create_ast_element(
        'Boot',
        {
            attr => {
                lineno => $fh->lineno,
                stream => $fh->stream
              }

        } );

    $self->stash( $boot );
    $self->push_context( $boot );

    # According to perlxs:
    #
    #   The first blank line after the keyword will terminate the code
    #   block.
    #
    # Too bad that's not what happens out in the field.  In reality,
    # it's 
    #   1. A blank line
    #   2. followed by an optional POD section
    #   3. followed by an optional TYPEMAP section
    #   4. followed by a left justified line.

    # keep track of last non-POD, TYPEMAP line
    my $data;

    while ( $fh->readline ) {

        next if $self->parse_pod;
        next if $self->parse_comment;

	next if $self->parse_keyword( 'TYPEMAP' );

	if ( /^\S/ && $data && $data->last =~ $Re{BLANK_LINE} ) {

	    $fh->ungetline;
	    last;
	}
        $data = $self->stash_data( $_ );
    }

    $self->pop_context;

    return 1;
}

sub handle_TYPEMAP {

    my ( $self, $arg ) = @_;

    my $fh = $self->fh;

    my %attr = (
        lineno => $fh->lineno,
        stream => $fh->stream
    );

    $arg =~ /^<<\s*
		(?:
		    (["'])(.+?)\1  # balanced quoted token
		   |([^\s'"]+)     # unquoted token
		)
		\s*
		;?                 # possible trailing ;
		\s*$/x;

    my $end_marker = quotemeta( defined( $1 ) ? $2 : $3 );

    my @contents;
    while ( $fh->readline ) {

        last if /^$end_marker\s*$/;
        push @contents, $_;
    }

    $self->error( 0, "Unterminated typemap" )
      if !defined $_;

    $self->stash(
        $self->create_ast_element(
            'Typemap',
            {
                attr     => \%attr,
                contents => \@contents,
            } ) );

    return 1;
}

sub process_INPUT {

    my ( $self, $input ) = @_;

    my $xsub = $self->context;

    $self->error( $input->attr->{lineno},
        "internal error; popped(INPUT) but context is not XSub\n" )
      unless $xsub->isa( 'Devel::XS::AST::XSub' );

    local $_;

    for my $element ( @{ $input->contents } ) {

        next unless $element->isa( 'Devel::XS::AST::Data' );

        my $lineno = $element->attr->{lineno};

        for ( @{ $element->contents } ) {

            my $ln = $_;

            s/^\s*|\s*$//g;

            next unless length;

            # by default initialize the argument, either implicitly
            # from the Perl stack, or explicitly from a value
            # specified in the argument specification.

            my $init_arg = 1;
            my ( $init_type, $init_value );
            # extract possible initialization symbol and value;
            if ( s/\s*([=;+])(.*)$// ) {

                $init_type = {
                    '=' => 'replace',
                    ';' => 'replace_later',
                    '+' => 'add_later'
                }->{$1};

                ( $init_value = $2 ) =~ s/^\s*|\s*$//g;

                # if the init_type is ';', a zero length init_value means
                # it's just a semi-colon, nothing more
                unless ( length( $init_value ) ) {

                    $self->error( $lineno, "missing variable initialization" )
                      unless ';' eq $init_type;

                    undef $init_type;
                }

                if ( $init_value eq 'NO_INIT' ) {

                    $self->error( $lineno,
                        "an initialization value of '+ NO_INIT' makes no sense\n"
                    ) if $init_type eq 'add_later';

                    undef $init_value;
                    $init_arg = 0;
                }

            }

            my ( $c_type, $pass_addr, $name ) = /^
	     (.*?)        # C type
	     \s*
	     (\&?)        # pass addr
	     \s*\b
	     (\w+)        # variable name
	     $/sx
              or $self->error( $lineno, "invalid parameter definition '$ln'" );

            $c_type = ExtUtils::Typemaps::tidy_type( $c_type );

            $self->error( 0, "invalid variable definition: $_\n" )
              unless length( $c_type ) && length( $name );

            # if the variable name matches something in the
            # declaration, check it against the declaration.
            # otherwise it's something we don't care about.
            #
            # FIXME: is this really true?  From perlxs:
            #
            #    Since INPUT sections allow declaration of C variables
            #    which do not appear in the parameter list of a
            #    subroutine...
            #
            # If those variables have initialization code, is it
            # parsed (and eval'd) or is it just left up to the C
            # compiler?

            if ( defined( my $arg = $xsub->arg( $name ) ) ) {

                if ( defined $arg->c_type ) {

                    my ( $ofile, $olineno );

                    if ( $arg->in_declaration ) {
                        $ofile   = $arg->attr->{stream}->filename;
                        $olineno = $arg->attr->{lineno};
                    }

                    else {

                        $ofile   = $arg->input->attr->{stream}->filename;
                        $olineno = $arg->attr->{input_lineno};
                    }

                    $self->error(
                        $lineno,
                        "duplicate definition of '$name'. ",
                        "original is at $ofile: $olineno\n"
                      )

                }

                else {

                    $arg->c_type( $c_type );
                    $arg->pass_addr( $pass_addr );
                    $arg->input( $input );
                    $arg->attr->{input_lineno} = $lineno;
                    $arg->init_arg( $init_arg );
                    $arg->init_type( $init_type );
                    $arg->init_value( $init_value );
                }

            }

        }

        continue {

            $lineno++;

        }

    }

}

sub error {

    my ( $self, $lineno ) = ( shift, shift );

    croak( $self->fh->filename, ': ', $lineno || $self->fh->lineno, ': ', @_ );
}

sub warn {

    my ( $self, $lineno ) = ( shift, shift );

    carp( $self->fh->filename, ': ', $lineno || $self->fh->lineno, ': ', @_ );
}

sub create_ast_element {

    my ( $self, $class, $attr ) = @_;

    $class = 'Devel::XS::AST::' . $class;

    my @missing = grep { !defined $attr->{attr}{$_} } qw[ lineno stream ];

    $self->error( 0,
        "missing attribute(s) for object of class $class: @missing\n" )
      if @missing;

    return $class->new( $attr );
}


1;    # End of Devel::ParseXS
