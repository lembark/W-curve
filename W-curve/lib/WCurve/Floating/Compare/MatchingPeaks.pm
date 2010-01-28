########################################################################
# housekeeping
########################################################################

package WCurve::Floating::Compare::MatchingPeaks;

use v5.10;
use strict;
use vars
qw(

    $two_pi

    $gap_window
    $snp_window
);

use Carp;

use List::Util      qw( first reduce max min sum );
use Scalar::Util    qw( refaddr );

use Symbol          qw( qualify_to_ref );

use Exporter::Proxy
qw
(
    matching_peaks
);

use WCurve::Constants;

########################################################################
# package variables
########################################################################

*two_pi         = \( 2.0 * $PI );

*snp_window     =  \ 8; # bases
*gap_window     = \ 40; # bases

my $verbose = '';   # progress messages
my $debug   = '';   # skips, snps
my $trace   = '';   # all decision values

########################################################################
# utility subs
########################################################################

########################################################################
# peaks are a skip-chain added to the nodes that link to
# the next node with a large enough radius to align with.

sub next_peak
{
    my ( $node, $cutoff ) = @_;

    for( ;; )
    {
        $node   = $node->[0];

        $node and @$node
        or last;

        $node->[1] > $cutoff
        and return $node;
    }

    return
}

sub add_skip_chain
{
    my ( $wc, $cutoff ) = @_;

    my $node    = $wc->[0];

    my $i       = '';

    while( my $peak = next_peak $node, $cutoff )
    {
        $i  = $node->[3];

        for( $i .. $peak->[3]-1 )
        {
            $node->[4]  = $peak;

            $node       = $node->[0];
        }
    }

    $node->[4]  = '';
}

########################################################################
# compute the measure between two nodes: R - r * cos a.

sub compute_diff
{
    my ( $n0, $n1 ) = @_;

    my ( $r0, $a0 ) = @{$n0}[1,2];
    my ( $r1, $a1 ) = @{$n1}[1,2];

    ( $r0, $r1 ) = ( $r1, $r0 )
    if $r1 > $r0;

    my $a   = abs( $a0 - $a1 );
    $a      = $two_pi - $a if $a > $PI;

    my $cos     = cos $a;

    my $diff    = $r0 - $r1 * $cos;

    print
    "\t\tDifference:  [ $n0->[3], $n1->[3] ] => $diff\n"
    if $trace;

    abs( $diff ) > $TINY
    ? $diff
    : 0.0
}

# the glitch is an SNP if the curves re-align to
# within a small value w/in the $snp-window.

sub is_snp
{
    my ( $n0, $n1 ) = @_;

    print
    "\tCheck snp: ( $n0->[3], $n1->[3] )\n"
    if $debug;

    my $sum = 0;
    my $a   = 0;

    for( 0 .. $snp_window )
    {
        @$n0   or last;
        @$n1   or last;

        $a      = compute_diff $n0, $n1;

        $SMALL > $a
        or next;

        return ( $a + $sum, $n0, $n1 )
    }
    continue
    {
        $sum    += $a;

        $n0     = $n0->[0];
        $n1     = $n1->[0];
    }

    # caller gets back false: this is not an SNP.

    return
}

########################################################################
# test if the curves are close.
# sum test allows for SNP's to match.

sub short_match
{
    my ( $n0, $n1, $size ) = @_;

    $size   ||= $snp_window;

    print
    "\tShort match: [ $n0->[3] : $n1->[3] : $size ]\n"
    if $debug;

    my $sum     = 0;
    my $diff    = 0;

    for( 1 .. $size )
    {
        @$n0 && @$n1
        or return;

        $SMALL > ( $diff = compute_diff $n0, $n1 )
        or return;

        $sum += $diff;

        $n0 = $n0->[0];
        $n1 = $n1->[0];
    }

    # return defined value to indicate they match.
    # might be zero for identical sections of curve.

    if( $debug )
    {
        my $off = $n0->[3] - $n1->[3];

        print
        "\tMatched at: [ $n0->[3] : $n1->[3] ] ($off) => $diff\n";
    }

    $sum
}

########################################################################
# walk up the curves searching for short matches w/in the
# ranges given.

sub find_short_match
{
    my ( $n0, $n1, $z0, $z1 ) = @_;

    $z1 ||= $z0;

    my $p0  = $n0->[4];

    while
    (
        $p0
        &&
        @$p0
        &&
        ( $p0->[3] < $z0 )
    )
    {
        my $p1  = $n1->[4];

        while
        (
            $p1
            &&
            @$p1
            &&
            ( $p1->[3] < $z1 )
        )
        {
            short_match $p0, $p1
            and return [ $p0, $p1 ];
        }
        continue
        {
            $p1 = $p1->[0][4];
        }
    }
    continue
    {
        $p0 = $p0->[0][4];
    }

    return
};

########################################################################
# if there appears to be a gap, find the closest matching
# peaks by walking down each side.
#
# this needs some tuning as to whether it preferrs higher
# peaks (larger r) or just the next spot where the angles
# are reasonably close.
#
# two separate cases: the curves re-align at the same Z value
# later on (preferable) or a phase shift needs to be
# introduced.

sub realign_nodes
{
    state $found_limit      = 8;

    my ( $n0, $n1, $w0 ) = @_;

    $w0         ||= $gap_window;

    my $p0      = $n0->[4] or return;
    my $p1_res  = $n1->[4] or return;

    my $p1      = '';
    my $w1      = 0;
    my $z0      = 0;
    my $z1      = 0;

    my $offset  = $n0->[3] - $n1->[3];

    print
    "\tRe-align at: $n0->[3] : $n1->[3] ($w0)\n"
    if $debug;

    my $diff    = 0;

    my $sum0    = $n0->[3] + $n1->[3];
    my $dist    = 0;

    # walk first p0 then p1 down the
    # chain for N peaks looking for a match.
    # find the first closest match.

    my @found   = ();

    FOUND:
    until( @found )
    {
        for( 1 .. $w0 )
        {
            $p1 = $p1_res;
            $w1 += $w0;

            for( 1 .. $w1 )
            {
                ( $diff   = short_match $p0, $p1 )
                // next;

                # prefer the lowest offset and any ones
                # that do not change the phase between
                # the nodes.

                $z0 = $p0->[3];
                $z1 = $p1->[3];

                $dist   =  $z0 + $z1 - $sum0;

                $found_limit
                >= push @found,
                [
                    $dist,
                    $diff,
                    $z0,
                    $z1,
                    $p0,
                    $p1
                ]
                or last FOUND;
            }
            continue
            {
                # exhausted second curve: expand the window.

                $p1 = $p1->[4] or last;
            }
        }
        continue
        {
            # exhausted the first curve: give up.

            $p0 = $p0->[4] or return;
        }
    }

    # choose the best match: this preferrs any
    # aligned values on the Z-axis, otherwise
    # looks for the smallest deviance.
    
    my $match 
    = first
    {
        $_
    }
    sort
    {
        $a->[0] <=> $b->[0]
        or
        $a->[1] <=> $b->[1]
        or
        $a->[2] <=> $b->[2]
        or
        $a->[3] <=> $b->[3]
    }
    @found;

    if( $debug )
    {
        local $/    = "\n";
        local $,    = "\n\t";

        print 
        '',
        "Alignment candidates:",
        ( map{ join  ' ', "\t", @$_[0..4] } @found ),
        '',
        if $trace;

        print "\tRe-align to: @{$match}[0..3]\n";
    };

    @{ $match }[ -2, -1 ]
}


########################################################################
# compare matching chunks of curve. this will skip over
# SNP's (or small multi-NP's) but gives up if the two
# nodes must be re-aligned from their current relative
# positions.

sub compare_aligned_nodes
{
    my ( $n0, $n1 ) = @_;

    @$n0    or return;
    @$n1    or return;

    my $show_zero   = 1;

    print ''
    if $debug;

    my  ( $a, $b, $c ) = ();

    my $diff    = 0.0;
    my $sum     = 0.0;

    for( ;; )
    {
        $diff = compute_diff $n0, $n1;

        print
        "\tCompare: $n0->[3] : $n1->[3] => $diff\n"
        if $debug && ( $diff || $show_zero );

        # turn this off after the first zero to
        # avoid huge numbers of zeros in the logs.

        $show_zero  &&= $diff;

        if( $diff > $SMALL )
        {
            ( $a, $b, $c ) = is_snp $n0, $n1;

            $c // last;

            ( $diff, $n0, $n1 ) = ( $a, $b, $c );

            $show_zero  = 1;
        }

        $sum    += $diff;

        $a  = $n0->[0];
        $b  = $n1->[0];

        $#$a > 0 or last;
        $#$a > 0 or last;

        $n0 = $a;
        $n1 = $b;
    }

    # hand back the node positions
    # to start re-alignment from.

    ( $sum, $n0, $n1 )
}

########################################################################
# top half of the alignment procedure: quick check for alignment at
# [ 0 : 0 ], then check if the curves are close enough in length to
# require symmetric analysis for the starting point, and then use
# align curves to try aligning them.
#
# caller gets back ( $diff, $n0, $n1 ) with the best guess alignment
# or empty to indicate that no alignment was found.

sub iterate_align
{
    my ( $wc0, $wc1, $z0, $z1 ) = @_;

    $z1 ||= $z0;

    my $l0  = 0 + $wc0;
    my $l1  = 0 + $wc1;

    my $p0  = $wc0->[0];
    my $p1  = $wc1->[0];

    # note that the second pass could benefit from caching
    # the first -- or only examining shorter ranges that
    # have not already been checked on the second.

    for
    (
        [ $z0, $z1  ],  # try the shorter limits
        [ $l0, $l1  ],  # give up and scan it all
    )
    {

        print
        "\tAlign: $wc0 ($p0->[3] .. $_->[0]) : $wc1 ($p1->[3] .. $_->[1])"
        if $verbose;

        if( my $found = find_short_match $p0, $p1, @$_ )
        {
            return $found;
        }
    }

    print "\tNo alignment"
    if $verbose;

    return
};

sub align_curves
{
    my ( $wc0, $wc1 ) = @_;

    my $n0  = $wc0->[0];
    my $n1  = $wc1->[0];

    # if they match from the start then
    # go no further.

    if( my @snp = is_snp $n0, $n1 )
    {
        return @snp
    }

    # no match at the start, use the difference in length
    # as a window for the comparison or find the first
    # decent match along both of them.

    my $l0  = 0 + $wc0;
    my $l1  = 0 + $wc1;

    my $p0  = $n0->[4];
    my $p1  = $n1->[4];

    my $z0  = 2 * $gap_window;
    my $z1  = 2 * $gap_window;

    my $dz  = abs( $l0 - $l1 );

    my $i
    = $dz > $gap_window
    ? $l0 <=> $l1
    : 0
    ;

    my $nodz    = ();

    given( $i )
    {
        when( 1 )
        {
            # $wc1 is shorter: put the longer window on $wc0.

            my $p0  = $n0->[4];
            my $p1  = $n1->[4];

            $z0 += $p0->[3] + $dz;
            $z1 += $p1->[3];

            print
            "\tUnequal alignment: $wc1 ($z1), $wc0 ($z0)"
            if $verbose;

            $nodz
            = iterate_align $wc0, $wc1, $z0, $z1;
        }

        when( -1 )
        {
            # $wc0 is shorter: put the longer window on $wc1.

            $z0 += $p0->[3];
            $z1 += $p1->[3] + $dz;

            print
            "\tUnequal alignment: $wc0 ($z0), $wc1 ($z1)"
            if $verbose;

            $nodz
            = iterate_align $wc0, $wc1, $z0, $z1;
        }

        when(  0 )
        {
            # same length: use a wider window for both

            $z0 += $p0->[3] + $gap_window;
            $z1 += $p1->[3] + $gap_window;

            print
            "\tUnequal alignment: $wc0 ($z0), $wc1 ($z1)"
            if $verbose;

            $nodz
            = iterate_align $wc0, $wc1, $z0, $z1;
        } 
    }

    # caller gets back nada to indicate no alignment.

    $nodz ? ( 0, @$nodz ) : ()
}

########################################################################
# bottom half of the comparision: walk the nodes, return the value.
#
# walk the nodes down an entire curve.
# exits when one of the linked lists
# runs out of nodes.
#
# note that this has no idea about WCurve objects.

sub compare_curves
{
    my ( $wc0, $wc1 ) = @_;

    my ( $diff, $n0, $n1 ) = align_curves $wc0, $wc1
    or die "Failed initial alignment: $wc0 $wc1";

    $DB::single = 1 if ref $diff;

    print
    "\tInitial: [ $n0->[3] : $n1->[3] ]\n"
    if $verbose;

    my $z0  = -$snp_window + $wc0;
    my $z1  = -$snp_window + $wc1;

    my $l0  = 0 + $wc0;
    my $l1  = 0 + $wc1;

    my $max_window  = max $l0, $l1;

    my @chunkz =
    [
        0,
        0,
        $n0->[3],
        $n1->[3],
        $diff
    ];

    CHUNK: 
    for( ;; )
    {
        my @chunk   = ( $n0->[3], $n1->[3] );

        # if the curves agree then this will leave
        # both $n0 and $n1 at their terminating
        # values.

        ( $diff, $n0, $n1 ) = compare_aligned_nodes $n0, $n1;

        $DB::single = 1 if ref $diff;

        push @chunk, ( $n0->[3], $n1->[3], $diff );

        print "\tSection: @chunk\n"
        if $debug;

        push @chunkz, \@chunk;

        # quit if either of the curves has been exhausted
        # or there isn't enough space left to re-align them
        # and still process anything more.

        @$n0 && @$n1
        or last;

        $z0 >= $n0->[3] or last;
        $z1 >= $n1->[3] or last;

        # otherwise they need to be re-aligned.

        for( $gap_window, $max_window )
        {
            my @found   = realign_nodes $n0, $n1, $_
            or next;

            ( $n0, $n1 ) = @found;

            next CHUNK
        }

        last
    }

    # deal with the last few bases on the curves.

    $diff    = 0.0;

    while( @$n0 && @$n1 )
    {
        $diff   += compute_diff $n0, $n1;

        $n0     = $n0->[0];
        $n1     = $n1->[0];
    }

    $DB::single = 1 if ref $diff;

    my $final   = $chunkz[-1];

    # final step is used to comapte the gap cost of
    # any trailing sequence.

    push @chunkz,
    [
        $final->[2],
        $final->[3],
        $l0-1,
        $l1-1,
        $diff
    ];

    my $chunks  = @chunkz;

    print
    "Compare: $chunks chunks.\n"
    if $verbose;

    wantarray
    ?  @chunkz
    : \@chunkz
}

########################################################################
# public interface
########################################################################
# top_half of the comaprision: prepare the curves by adding skip chains,
# set radius, verbose/debug/trace level.
#
# normally dispatched from WCurve::Compare.

sub matching_peaks
{
    state   $chain  = \&add_skip_chain;

    local $\    = "\n";
    local $,    = "\n\t";

    my ( $wc0, $wc1, $radius ) = @_[0..2];

    $wc0
    or croak "Bogus matching_peaks: false first curve";

    $wc1
    or croak "Bogus matching_peaks: false second curve";

    @$wc0
    or croak "Bogus matching_peaks: empty first curve";

    @$wc1
    or croak "Bogus matching_peaks: empty second curve";

    $radius     //= 0.50;

    $verbose    = $_[3] // $WCurve::Floating::Compare::verbose;
    $debug      = $verbose > 1;
    $trace      = $verbose > 2;

    print
    do
    {
        my $l0      = 0 + $wc0;
        my $l1      = 0 + $wc1;

        "\nMatching Peaks: $wc0 ($l0) : $wc1 ($l1); radius = $radius"
    }
    if $verbose;

    local $0    = "matching_peaks $wc0, $wc1, $radius";

    for my $wc ( $wc0, $wc1 )
    {
        $wc->[0][4]
        or $wc->$chain( $radius );
    }

    goto &compare_curves
}

# keep require happy

1

__END__
