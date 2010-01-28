########################################################################
# housekeeping
########################################################################

use v5.10;
use strict;
use FindBin::libs;

use Test::More;

use List::Util  qw( sum );

use WCurve;
use RandomDNA;

########################################################################
# package variables
########################################################################

my $base_size   = 1024;
my $base_seq
= RandomDNA->generate_seq
(
    uniform_random => $base_size
);

plan tests => 2 * $base_size;

########################################################################
# utility subs
########################################################################

########################################################################
# run test
########################################################################

my $base_curve  = WCurve->new( Floating => $base_seq, 'Base Sequence' );

for( 0 .. $base_size - 1 )
{
    my $alt_seq = $base_seq;

    RandomDNA->munge_seq( single_snp => $_, $alt_seq );

    my $name
    = do
    {
        $a  = substr $base_seq, $_, 1;
        $b  = substr $alt_seq,  $_, 1;

        "Alt: $a -> $b at $_";
    };

    my $alt_curve   = WCurve->new( Floating => $alt_seq, $name );

    my @chunkz
    = $base_curve->compare
    (
        matching_peaks => $alt_curve
    );

    my $count   = @chunkz;
    my $diff    = $chunkz[1][4] + $chunkz[2][4];

    ok 3 == @chunkz,    "Chunks: $count (3)";
    ok $diff,           "Non-zero difference ($diff)";
}

done_testing;

# this is not a module

0

__DATA__
