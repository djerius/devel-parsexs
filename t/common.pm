package t::common;

use lib 't/lib';

use File::Spec::Functions qw[ catfile ];

use Exporter 'import';
our @EXPORT_OK = qw[

  datafile
  data

];

sub psplice {

    my ( $array ) = shift;

    if ( @_ ) {

	my $offset = shift;

	unless ( @_ )  {

	    splice( @{$array}, $offset );

	}

	else {

	    my $length = shift;

	    unless ( @_ ) {

		splice( @{$array}, $offset, $length );

	    }
	    else {

		splice( @{$array}, $offset, $length, @_ );

	    }

	}

    }

}


sub datafile {

    my $package = ( caller )[0];

    my @path = split( '::', $package );

    psplice( \@path, @{ shift() } )
	if 'ARRAY' eq ref $_[0];

    return catfile( @path, @_ );
}


sub data {

    my $package = ( caller )[0];

    return $package->section_data( @_ ) ;

}

1;
