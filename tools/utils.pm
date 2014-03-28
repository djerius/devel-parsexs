package utils;

use Exporter 'import';

use FindBin qw( $Bin );
use Path::Tiny;
use IO::All;

use Types::Standard -all;
use Type::Params qw[ compile ];

our @EXPORT = qw[
  filter
  db_connect
  db_clone
];

sub filter {

    my $file
      = path( $Bin )->child( 'filters' )->child( join( '-', @_ ) . '.sql' );

    my $sql = io( $file )->slurp;
    $sql =~ s/;\s*$//;
    return $sql;
}

sub db_connect {

    my $check = compile(
        Str | InstanceOf ['Path::Tiny'],
        slurpy Dict [
            trace => Optional [Num] ] );

    my ( $db, $attr ) = $check->( @_ );

    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$db",
        {
            RaiseError          => 1,
            AutoInactiveDestroy => 1,
            AutoCommit          => 1,
        } );

    $dbh->trace( $attr->{trace} ) if $attr->{trace};

    return $dbh;
}

sub db_clone {

    my $check = compile( InstanceOf ['DBI::db'] );

    ( my $dbh ) = $check->( @_ );

    my $clone = $dbh->clone( {
        RaiseError          => 1,
        AutoCommit          => 1,
        AutoInactiveDestroy => 1,
    } );

    return $clone;
}
