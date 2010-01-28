#!/opt/bin/perl
########################################################################
# housekeeping
########################################################################

use v5.10;
use strict;
use FindBin::libs;

use RandomDNA;
use Test::More;
use Parallel::Queue;

use WCurve;
use WCurve::Constants;

########################################################################
# package variables
########################################################################

my $base_len    
= $ENV{ EXPENSIVE_TESTS }
? 1024
:   80
;

my $base_seq    
= RandomDNA->generate_seq
(
    uniform_random => $base_len 
);

my $base_curve
= WCurve->new( Floating => $base_seq, 'Base Sequence' );

my $jobs        = $ENV{ JOBS } || 1;

my $max_gap     = 2 * $gap_window;

########################################################################
# utility subs
########################################################################

for
(
    my $gap_size    = 1         ;
    $gap_size       < $max_gap  ;
    $gap_size       += 4
)
{
    for
    (
        my $gap_offset  = 0     ;
        $gap_offset < $base_len ;
        $gap_offset += 4
    )
    {
        $0  = "single gap test x $gap_size @ $gap_offset";

        my $name    = "gap x $gap_size \@ $gap_offset";

        my $alt_seq = $base_seq;

        RandomDNA->munge_seq
        (
            insert_gap =>
            $gap_offset,
            $gap_size,
            $alt_seq
        );

        my $alt_curve   = WCurve->new( Floating => $alt_seq, $name );

        for
        (
            [ $base_curve, $alt_curve ],
            [ $alt_curve, $base_curve ],
        )
        {
            ( $a, $b ) = @$_;

            my @compare
            = $a->compare
            (
                matching_peaks => $b, 0.50
            );

            my $found   = abs( $compare[-1][3] - $compare[-1][2] );

            ok $gap_size == $found, "Gap size $found ($gap_size)";
        }
    }
}

########################################################################
# run test
########################################################################

done_testing;

# this is not a module

0

__END__
