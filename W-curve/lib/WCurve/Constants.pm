
package WCurve::Constants;

use v5.10;
use strict;
use vars
(
    qw
    (
        $PI
        $TINY
        $ZERO
        $SMALL
        $gap_window    
        $snp_window

        $angle_div
        $small_angle
        $radius_div
    )
);

use Exporter::Proxy
(
    qw
    (
        PI
        TINY
        ZERO
        SMALL

        cornerz
        anglz

        gap_window
        snp_window

        angle_div
        small_angle
        radius_div
    )
);

*PI         = \( 4 * ( atan2 1, 1 ) );
*ZERO       = \ 2 ** -30;
*TINY       = \ 2 ** -18;
*SMALL      = \ 0.075;

# edges: ta, ag, gc, ct

our %cornerz = 
(
    # CT and AT adjacent on one set of edges,
    # GA and CT on the other.

    t   => [  1.0,  0.0 ],
    a   => [  0.0,  1.0 ],

    g   => [ -1.0,  0.0 ],
    c   => [  0.0, -1.0 ],
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

# use for limits in integer conversion
# angle div == angle at which r * dr * da == small for
# max radius == 1 this is simply the angle == small.
# the full circle must be divided into twice that many
# segments for reasonable computation.
#
# this works out to 128 for $SMALL == 0.075.
#
# the radius division is 1 / ( 2 & $SMALL ) == 6.67

$angle_div      = 2 ** ( 1 + int ( log ( 2 * $PI / $SMALL ) / log 2 ) );
$small_angle    = 2 * $PI / $angle_div;

# the smallest radius division is half the 
# $SMALL value used to compare distances.

$radius_div     = 1 / ( 2 * $SMALL );

# keep require happy

1

__END__
