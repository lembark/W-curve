########################################################################
# test the modules used to generate random DNA sequeneces
# for testing the WCurve modules.
########################################################################
########################################################################
# housekeeping
########################################################################

use v5.10;
use strict;
use FindBin::libs;

use Symbol;
use Test::More;

########################################################################
# package variables
########################################################################

my @checkz =
(

    [
        qw
        (

            WCurve::Test::RandomDNA::Generate
            uniform_random
            skewed_random
        )
    ],

    [
        qw
        (
            WCurve::Test::RandomDNA::Munge
            single_snp
            multiple_snp
            random_snp
            offset_replace
            random_replace
            insert_gap
        )
    ],

    [
        qw
        (
            WCurve::Test::RandomDNA
            generate
            munge
            generate_seq
            munge_seq
        )
    ],
);

my $count   = map { @$_ } @checkz;

########################################################################
# tests
########################################################################

plan tests => $count;

for( @checkz )
{
    my ( $madness, @methodz ) = @$_;

    use_ok $madness
    or BAIL_OUT "Failed use: $madness";

    ok $madness->can( $_ ), "$madness can '$_'"
    for @methodz
}

# this is not a module

0

__END__
