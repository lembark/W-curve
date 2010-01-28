########################################################################
# housekeeping
########################################################################

package WCurve::Output;

use v5.10;
use strict;

use IO::File;

use Exporter::Proxy qw( dispatch=output );

use WCurve::Constants qw( TINY );

########################################################################
# package variables
########################################################################

########################################################################
# utility subs
########################################################################

sub ra2xy
{
    state $cos  = 0.0;
    state $sin  = 0.0;
    state $x    = 0.0;
    state $y    = 0.0;

    my ( $r, $a ) = @_;

    $sin    = sin $a;
    $cos    = cos $a;

    ( abs $_ ) > $TINY or $_ = 0.0 for $sin, $cos;

    $x      = $r * $sin;
    $y      = $r * $cos;

    ( abs $_ ) > $TINY or $_ = 0.0 for $x, $y;

    ( $x, $y )
}

sub cylindrical
{
    my ( $wc, $path ) = @_;

    my $fh 
    = '-' eq $path
    ? *STDOUT{ IO }
    : $path =~ /[.]gz$/
    ? IO::File->new( "| gzip -9 > $path" )
    : IO::File->new( "> $path" )
    ;

    my ( $node, $r, $a, $z ) = ( $wc->[0], 0.0, 0.0, 0 );

    local $\    = "\n";
    local $,    = "\t";

    # all curves start at ( 0.0, 0.0, 0 );
    # e.g., disk full, filesystem limits.

    $fh->printflush( $r, $a, $z )
    or die "Failed output: $path, $!";

    while( @$node )
    {
        ( $node, $r, $a, $z ) = @$node;

        $fh->printflush( $r, $a, $z )
        or die "printflush: $path, $!";
    }

    return
}

sub cartesian
{
    my ( $wc, $path ) = @_;

    my $fh 
    = '-' eq $path
    ? *STDOUT{ IO }
    : $path =~ /[.]gz$/
    ? IO::File->new( "| gzip -9 > $path" )
    : IO::File->new( "> $path" )
    ;

    my ( $node, $r, $a, $z ) = ( $wc->[0], 0.0, 0.0, 0 );

    my ( $x, $y )   = ( 0.0, 0.0 );

    local $\    = "\n";
    local $,    = "\t";

    # all curves start at ( 0.0, 0.0, 0 );
    # e.g., disk full, filesystem limits.

    $fh->printflush( $r, $a, $z )
    or die "Failed output: $path, $!";

    while( @$node )
    {
        ( $node, $r, $a, $z ) = @$node;

        $fh->printflush( ( ra2xy $r, $a ), $z )
        or die "printflush: $path, $!";
    }

    return
}

# use for gnuplot vector output: 6 points per vector.

sub vector
{
    my ( $wc, $path ) = @_;

    my $fh 
    = '-' eq $path
    ? *STDOUT{ IO }
    : $path =~ /[.]gz$/
    ? IO::File->new( "| gzip -9 > $path" )
    : IO::File->new( "> $path" )
    ;

    local $\    = "\n";
    local $,    = "\t";

    my $node    = $wc->[0];

    my ( $r, $a )       = ( 0.0, 0.0 );
    my ( $x, $y, $z )   = ( 0.0, 0.0, 0 );
    my ( $dx, $dy )     = ( 0.0, 0.0 );
    my ( $x1, $y1 )     = ( 0.0, 0.0 );

    while( @$node )
    {
        ( $node, $r, $a ) = @$node;

        ( $x1, $y1 ) = ra2xy $r, $a;

        $dx = $x1 - $x;
        $dy = $y1 - $y;

        $fh->printflush( $x, $y, $z, $dx, $dy, 1 )
        or die "printflush: $path, $!";

        $x  += $dx;
        $y  += $dy;
        ++$z;
    }

    return
}

sub porcupine
{
    my ( $wc, $path, $radius ) = @_;

    my $fh 
    = '-' eq $path
    ? *STDOUT{ IO }
    : $path =~ /[.]gz$/
    ? IO::File->new( "| gzip -9 > $path" )
    : IO::File->new( "> $path" )
    ;

    my ( $r, $a )       = ( 0.0, 0.0 );
    my ( $x, $y, $z )   = ( 0.0, 0.0, 0 );

    local $\    = "\n";
    local $,    = "\t";

    for my $i ( 0 .. 1 )
    {
        my $node    = $wc->[0];

        while( @$node )
        {
            ( $node, $r, $a, $z ) = @$node;

            given( $i )
            {
                when( 0 ) { $r <= $radius or next }
                when( 1 ) { $r >  $radius or next }
            }

            ( $x, $y ) = ra2xy $r, $a;

            $fh->printflush( 0, 0, $z, $x, $y, 0 )
            or die "printflush: $path, $!";
        }

        $fh->printflush( "\n" );
    }

    return
}

########################################################################
# public interface
########################################################################

# keep require happy

1

__END__
