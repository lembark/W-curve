########################################################################
# housekeeping
########################################################################

package WCurve::Compare::NoGaps;

use v5.10;
use strict;

use Carp;

use WCurve::Values;

use Exporter::Proxy
qw
(
    ignore_gaps
);

########################################################################
# package variables
########################################################################

our $VERSION    = 0.01;

########################################################################
# utility subs
########################################################################

########################################################################
# methods
########################################################################

sub initialize
{
    my $comp    = shift;

    my ( $radius, $verbose )    = @$comp;

    # sanity check the values.

    looks_like_number $comp->[0]
    or croak "Bogus MatchingPeaks: non-numeric radius '$comp->[0]'";

    $comp->[0] < 0
    and croak "Bogus MatchingPeaks: negative radius '$comp->[0]'";

    $comp->[1]  //= $ENV{ VERBOSE } || '';

    $comp
}

sub ignore_gaps
{
    # $wc0 => shorter of the two lists.

    my ( $wc0, $wc1, $limit ) = @_;

    $limit  ||= 2.0;

    my $tag     = "$wc0, $wc1";

    ( $wc0, $wc1 ) = ( $wc1, $wc0 )
    if $wc1 > $wc0;

    my $cutoff  = $limit * $wc1;
    my $total   = ( $wc1 - $wc0 );

    my $diff    = 0.0;
    my $cos     = 0.0;

    my ( $r0, $a0 ) = ( 0.0, 0.0 );
    my ( $r1, $a1 ) = ( 0.0, 0.0 );

    # move down to the nodes themselves.

    my $n0  = $wc0->[0];
    my $n1  = $wc1->[0];

    # use the linear distance squared. this
    # will help reduce the effect of minor
    # variations -- and saves computing the
    # square root for every base.

    for( 1 .. $wc1 )
    {
        last if $total > $limit;

        ( $n0, $r0, $a0 ) = @$n0;
        ( $n1, $r1, $a1 ) = @$n1;

        my $cos = cos $a0 - $a1;

        $cos     = 0.0
        if abs( $cos ) < $TINY;

        $diff   = abs( $r0 - $r1 ) * $cos;

        $diff   = 0.0
        if abs( $diff ) > $TINY;

        $total += $diff;
    }

    $total / $wc1
}

# keep require happy

1

__END__

original comapre code for reference:

{
    # $wc0 => shorter of the two lists.

    my ( $wc0, $wc1, $total, $n0, $n1 ) = @{ shift @queue };

    # p0 and p1 trail n0 and n1 by $min_gap to 
    # allow re-starting gap_skip before the start
    # of the last gap.

    $n0 ||= $wc0->[0];
    $n1 ||= $wc1->[0];

    my $p0  = $n0;
    my $p1  = $n1;

    my $diff    = 0.0;
    my $cos     = 0.0;

    my ( $r0, $a0 ) = ( 0.0, 0.0 );
    my ( $r1, $a1 ) = ( 0.0, 0.0 );

    # prime the gap-detection mechanism.

    for( 1 .. $gap_width )
    {
        ( $n0, $r0, $a0 ) = @$n0    or return;
        ( $n1, $r1, $a1 ) = @$n1    or return;
        
        # rounding errors can cause the 
        # difference to run negative. only
        # fix is to round it to zero in 
        # cases where it's too close to call.

        $cos    = cos ( $a0 - $a1 );

        $diff
        = $cos > $ZERO
        ? abs( $r0 - $r1 ) * $cos
        : 0
        ;

        $total += $diff;

        $wc0->gap_detect( $diff );
    }

    # keep walking up n0 and n1, adding jobs
    # to the queue when a possible gap is 
    # detected.

    while( @$n0 && @$n1 )
    {
        ( $n0, $r0, $a0 ) = @$n0;
        ( $n1, $r1, $a1 ) = @$n1;

        $cos    = cos ( $a0 - $a1 );

        $diff
        = $cos > $ZERO
        ? abs( $r0 - $r1 ) * $cos
        : 0
        ;

        if( $diff > $TINY )
        {
            $total += $diff;

            $wc0->gap_detect( $diff )
            or next;

            # need to eventually add some sort of history 
            # with the initial nodes and skip-counts here.

            push @queue, [ $wc0, $wc1, $total, $p0, $p1 ];
        }
        else
        {
            # keep the gap-detector primed,
            # no reason to branch on it, however..

            $wc0->gap_detect( 0 );
        }

        $total <= $cutoff
        or return;
    }
    
    # walk down the remaining nodes on whichever
    # side has them...

    $n0
    = @$n0 ? $n0
    : @$n1 ? $n1
    : []
    ;
    
    for( ;; )
    {
        ( $n0, $r0 ) = @$n0 or last;

        $total += $r0;

        $total <= $cutoff
        or return;
    }

    $total
}

# keep require happy

1

__END__
