package utils;

use Exporter 'import';

use IO::All;

our @EXPORTS = qw[ filter ] ;

sub filter {

    my $file = path( 'filters' )->child( join( '-', @_ ) . '.sql' );

    my $sql = io( $file )->slurp;
    $sql =~ s/;\s*$//;
    return $sql;
}
