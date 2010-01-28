########################################################################
# housekeeping
########################################################################

package Testify;

use v5.10;
use strict;
use FindBin::libs;
use vars qw( %cornerz );

use Data::Dumper;
use Test::More;
use Test::Deep;

use WCurve;

########################################################################
# package variables
########################################################################

# check for rounding errors showing up in the comparisions.
# expensive tests are also useful for benchmarking and 
# memory manglement tests.

my $length
= $ENV{ EXPENSIVE_TESTS }
? 2 ** 18 
: 128
;

my $tests   = 100;

my @basz    = sort keys %WCurve::cornerz;

my $compare = WCurve::Floating->can( 'compare' )
or die "Bogus $0: WCurve::Floating cannot 'compare'";

########################################################################
# run tests
########################################################################

plan tests => $tests * 20;

for( 1 .. $tests )
{
    my $size     = 16 + int rand $length;
    my $offset   = $size - 1;
    my $seq      = ' ' x $size;
    my $expect   = 
    [
        [ ( 0 ) x 5                     ],
        [ ( 0 ) x 2, ( $offset ) x 2, 0 ],
        [ ( $offset ) x 4, 0            ],
    ];

    substr $seq, $_, 1, $basz[ rand @basz ]
    for 0 .. $offset;

    my $wc0 = WCurve->new( Floating  => $seq );
    my $wc1 = WCurve->new( Floating  => $seq );

    ok $size == $wc0,   "wc0 == $size ($_)";
    ok $size == $wc1,   "wc1 == $size ($_)";

    for
    (
        [ $wc0, 'matching_peaks', $wc0 ],
        [ $wc0, 'matching_peaks', $wc1 ],
        [ $wc1, 'matching_peaks', $wc1 ],
        [ $wc1, 'matching_peaks', $wc0 ],
    )
    {
        my $found   = $compare->( @$_ );

        ok 3 == @$found, 'Chunks = 3';

        ok $expect->[$_] ~~ $found->[$_], "Chunks match ($_)"
        for ( 0 .. 2 );
    }

    ok ! ( undef $wc0 ),  'wc0 destroyed';
    ok ! ( undef $wc1 ),  'wc1 destroyed';
}

# this is not a module

0

__END__
