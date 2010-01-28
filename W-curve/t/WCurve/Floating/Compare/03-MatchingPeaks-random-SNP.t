#!/opt/bin/perl
########################################################################
# housekeeping
########################################################################

use v5.10;
use strict;
use FindBin::libs;

use Test::More;

use WCurve;
use RandomDNA;
use WCurve::Constants qw( snp_window );

########################################################################
# package variables
########################################################################

my $count       = 128;
my $base_size   = $count * $snp_window + 1;
my $base_seq    
= RandomDNA->generate_seq
(
    uniform_random => $base_size 
);

my $offset  = 0;

WCurve::Floating::Compare->verbose( $ENV{ VERBOSE } );

########################################################################
# utility subs
########################################################################

########################################################################
# run test
########################################################################

my $base_curve  = WCurve->new( Floating => $base_seq, 'Base Sequence' );
my $alt_seq     = $base_seq;

for( 1 .. $count )
{
    my $offset  = int ( $offset + rand $snp_window );

    RandomDNA->munge_seq( single_snp => $offset, $alt_seq );

    my $name
    = do
    {
        my $i   = substr $base_seq, $offset, 1;
        my $j   = substr $alt_seq,  $offset, 1;

        "$i -> $j at $offset"
    };

    my $alt_curve   = WCurve->new( Floating => $alt_seq, $name );

    my @chunkz
    = $base_curve->compare
    (
        matching_peaks => $alt_curve
    );

    for my $chunk ( @chunkz )
    {
        local $"    = ', ';
        local $\    = "\n";

        print "Validate: [ @$chunk ]";

        ok
        $chunk->[0] == $chunk->[1],
        "No gap ($chunk->[0], $chunk->[1] )";

        ok
        $chunk->[2] == $chunk->[3],
        "No gap ($chunk->[2], $chunk->[3] )";
    }

    $offset += $snp_window;
}

done_testing;

# this is not a module

0

__END__
