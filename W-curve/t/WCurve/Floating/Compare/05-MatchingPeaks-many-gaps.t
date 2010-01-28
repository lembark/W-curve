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

use Benchmark   qw( :hireswallclock );
use List::Util  qw( max );

use WCurve;
use WCurve::Constants;

########################################################################
# package variables
########################################################################

my $verbose
= WCurve::Floating::Compare->verbose
(
    $ENV{ VERBOSE } 
);

my $gaps        = $ENV{ GAPS }      || 40;

my $seq_len     = 4096;
my $chunk       = int $seq_len / $gaps;
my $gap_max     = $chunk - 8;


my $mp
= WCurve::Floating::Compare::MatchingPeaks->can
(
    'matching_peaks' 
);

my @namz    = qw( Wild Gaps );

my @seqz
=  do
{
    my $seq = RandomDNA->generate_seq
    (
        uniform_random => $seq_len
    );

    ( $seq ) x 2
};

my @curvz
= map
{
    WCurve->new( Floating => $seqz[$_], $namz[$_]  )
}
( 0 .. $#namz );

my $base_tm
= do
{

    my $t1      = Benchmark->new;

    my @chunkz  = $mp->( @curvz );

    my $t2      = Benchmark->new;

    $t2->[0] - $t1->[0]
};

########################################################################
# utility subs
########################################################################

########################################################################
# run test
########################################################################

my $offset  = 0;
my $expect  = 0;

for( 1 .. $gaps )
{
    my $size    = 1 + int rand $gap_max;

    my $where   = $offset + int rand ($chunk - $size);

    print "\nInsert gap: $_ = $size \@ $where\n"
    if $verbose;

    RandomDNA->munge_seq
    (
        insert_gap => $where, $size, $seqz[1]
    );

    my $t0      = Benchmark->new;

    $curvz[1]   = WCurve->new( Floating => $seqz[1], $namz[1] );

    my $t1      = Benchmark->new;

    my $chunkz  = $mp->( @curvz );

    my $t2      = Benchmark->new;

    if( $verbose )
    {
        my $length  = max map { length $_ } @seqz;

        my $wall_tm = $t2->[0] - $t1->[0];
        my $seq_hz  = $seq_len / $wall_tm;

        my $inc_tm  = ( $wall_tm - $base_tm );
        my $inc_pct = 100 * $inc_tm / $base_tm;
        my $gap_pct = 100 * $inc_tm / $wall_tm;

        printf "Wallclock: %5d @ %8.6f sec (%6d Hz)\n",
        $length, $wall_tm, $seq_hz;
        
        printf "Gap Cost:  %5d @ %8.6f (%d%%, +%d%%)\n",
        $_, $inc_tm, $gap_pct, $inc_pct;
    };

    my $final   = $chunkz->[-1];
    my $found   = $final->[1] - $final->[0];

    $expect += $size;

    ok $found == $expect, "Net gap: $found ($expect)";
}
continue
{
    $offset += $chunk;
}

done_testing;

# this is not a module

0

__END__
