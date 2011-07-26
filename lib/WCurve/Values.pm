
package WCurve::Values;

use v5.10;
use strict;
use vars
(
    qw
    (
        $PI
        $two_pi

        $TINY
        $ZERO
    )
);

use Exporter::Proxy
(
    qw
    (
        PI
        two_pi

        TINY
        ZERO

        cornerz
        anglz
    )
);

*PI     = \( 4 * ( atan2 1, 1 ) );
*two_pi = \( 2.0 * $PI );

*TINY   = \ 2 ** -18;   # limit for sin/cos lookups.
*ZERO   = \ 2 ** -30;   # limit for floating point values.

# edges: ta, ag, gc, ct

our %cornerz = 
(
    # CT and AT adjacent on one set of edges,
    # GA and CT on the other.
    # N (unknown base) at the center.


    t   => [  1.0,  0.0 ],
    a   => [  0.0,  1.0 ],

    g   => [ -1.0,  0.0 ],
    c   => [  0.0, -1.0 ],

    n   => [  0.0,  0.0 ],
);

our %anglz
= map
{
    my ( $x, $y ) = @{ $cornerz{ $_ } };

    ( $_ => atan2 $y, $x )
    
}
keys %cornerz;

$cornerz{ "\U$_" }  = $cornerz{ $_ }
for keys %cornerz;

$anglz{ "\U$_" }    = $anglz{ $_ }
for keys %anglz;

# keep require happy

1

__END__
