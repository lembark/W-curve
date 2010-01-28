########################################################################
# housekeeping 
########################################################################

package WCurve::Floating;

use v5.10;
use strict;
use parent qw( WCurve );

use Carp;

use WCurve::Constants;
use WCurve::Floating::Compare;

use Exporter::Proxy qw( generate );

########################################################################
# methods
########################################################################

sub generate
{
    my ( $wc, $seq ) = splice @_, 0, 2;

    # anything left in @_ is extra data the caller
    # wants stuck into the head node.

    $seq        =~ s/\W+//g;

    $seq 
    or croak "Bogus entire: empty sequence";

    my $size    = length $seq;

    @$wc        = ( [], $size, @_ );

    my $node    = $wc->[0];

    my $base    = substr $seq, 0, 1, '';

    ( $node )   = @$node = ( [], 0.5, $anglz{$base}, 0 );

    my ( $xc, $yc ) = @{ $cornerz{ $base } };

    my ( $x,  $y  ) = ( $xc/2, $yc/2 );

    my ( $r,  $a  ) = ( 0.0, 0.0 );
    my $z           = 0;
    my $sin         = 0;

    while( $base = substr $seq, 0, 1, '' )
    {
        # cartesian co-ords of the modpoint of a line are
        # at the midpoints along x & y. this will simply be
        # the average of the sides. since one side is fixed
        # a 1, the values in %cornerz are 0 and 0.5, which
        # allows direct addition to 1/2 the values taken
        # from the radius.

        $base ~~ %cornerz
        or confess "Botched sequence: unknown base '$base' at offset $z\n";

        ( $xc, $yc ) = @{ $cornerz{ $base } };

        $x      = ( $xc + $x ) / 2;
        $y      = ( $yc + $y ) / 2;

        $a      = atan2 $y, $x;

        abs( $a ) > $TINY
        or $a = 0.0;

        $sin    = sin $a;

        $r
        = abs( $sin ) > $ZERO
        ? abs( $y / $sin )
        : abs( $x )
        ;

        $r > $ZERO
        or $r = 0.0;

        ( $node )  = @$node = ( [], $r, $a, ++$z );
    }

    # at this point the WCurve has been populated and has
    # the necessary data for overloading.

    $wc
}

# keep require happy

1

__END__
