#!/opt/bin/perl
########################################################################
# housekeeping
########################################################################

use v5.10;
use strict;
use FindBin::libs;

use RandomDNA;
use Test::More;

use WCurve;
use WCurve::Constants qw( snp_window );

########################################################################
# package variables
########################################################################

my $base_size   = $snp_window * ( $ENV{ EXPENSIVE_TESTS } ? 1024 : 16 );

my $base_seq
= RandomDNA->generate_seq
(
    uniform_random => $base_size 
);

my $base_curve  = WCurve->new( Floating => $base_seq, 'Fixed' );

my $alt_seq = $base_seq;

my $count   = int( $base_size / $snp_window  - 1 );
my $offset  = 0;

my $last    = 0.0;

########################################################################
# utility subs
########################################################################

########################################################################
# run test
########################################################################

plan tests => ( $count + 1 ) * 2;

for ( 0 .. $count )
{
    RandomDNA->munge_seq( single_snp => $offset, $alt_seq );

    my $name
    = do
    {
        $a  = substr $base_seq, $offset, 1;
        $b  = substr $alt_seq,  $offset, 1;

        "$a -> $b at $offset"
    };

    my $alt_curve
    = WCurve->new( Floating => $alt_seq, $name );

    my @chunkz
    = $base_curve->compare
    (
        matching_peaks => $alt_curve
    );

    my $count   = @chunkz;
    my $diff    = $chunkz[-2][-1] + $chunkz[-1][-1];

    ok 3 == @chunkz,    "Chunks: $count ($_ snps)";
    ok $diff >= $last,  "$diff > $last";

    $last   = $diff;

    $offset += $snp_window;
};

# this is not a module

0

__END__
