########################################################################
# housekeeping
########################################################################

package WCurve::Score::SumChunks;

use v5.12;
use parent qw( WCurve::Score );

use Data::Dumper;

use List::Util      qw( max min sum );

use WCurve::Values;

use WCurve::Util::Print    qw( fatal );

########################################################################
# package variables
########################################################################

our $VERSION    = 0.01;

########################################################################
# public interface
########################################################################

########################################################################
# compare entries look like:
# 
# [
#   sum of diff
#   n0 initial
#   n1 initial
#   n0 final
#   n1 final
# ]
#
########################################################################

########################################################################
# if the first chunk i [ 0, 1, 1, 1, 1 ] and the second one has 
# a gap then return the second one.

sub first_chunk
{
    my $chunkz  = shift;
}

########################################################################
# utility subs
########################################################################

########################################################################
# exported interface
########################################################################
# score gaps constant * gap size.
# skips as average w/in block * size of skip.
# diffs are totalled.
#
# total score is divided by 2.0 * total bases 
# to get fraction of the worst score possible
# ( 0.0 <= score <= 1.0 ).

sub compute
{
    my ( $score, $chunkz ) = @_;

$DB::single = 1 if $score->debug;

    @$chunkz or next;

    @$chunkz > 2
    or fatal 'Bogus compute: need more than two chunks', $chunkz;

    my $first
    = $chunkz->[0][1] > 1 || $chunkz->[0][2] > 1
    ? 0
    : 1
    ;

    my ( $prior, $after )   = @{ $chunkz }[ $first, -1 ];
    my ( $p0, $p1 )         = @{ $prior  }[ 3, 4 ];

    my $icost  = $score->indel_cost;
    my $gcost  = $score->gap_cost;

    my $sum     = 0;

    for( @{ $chunkz }[ $first+1 .. $#$chunkz - 1 ] )
    {
        my ( $diff, $s0, $s1, $e0, $e1 ) = @$_;

        $sum    += $diff;

        my $i       = $s0 - $p0 - 1;
        my $j       = $s1 - $p1 - 1;

        $i || $j
        or next;

        my $indel   = min $i, $j;
        my $gap     = abs $i - $j;

        $indel || $gap
        or next;

        $sum    += $indel * $icost;
        $sum    += $gap   * $gcost;
    } 

    my $i   = $after->[1] - $prior->[1];
    my $j   = $after->[2] - $prior->[2];

    $sum / ( $i + $j )
}

# keep require happy

1

__END__
