########################################################################
# housekeeping
########################################################################

package WCurve::Test::Cmdline;

use v5.10;
use strict;
use FindBin::libs;

use File::Basename  qw( basename );

use Symbol  qw( qualify_to_ref );

use WCurve::Util::Getopt qw( get_options );

########################################################################
# package variables
########################################################################

my ( $comp_type, $frag_type )
= ( basename $0 ) =~ m{ ^ \d+ - (\w+) - (\w+) }x; 

my @default_valz = 
(
    passes      => 1,
    base_size   => 2**8,
    seed        => 1,

    comp_type   => $comp_type,
    frag_type   => $frag_type,

    verbose     => '',
    debug       => '',
);

my @default_optz
= qw
(
    passes=i
    base_size|size=i
    alt_size=i
    gap=i
    snp=i
    seed=i
);

########################################################################
# install the local handler as "get_options" into the caller.
########################################################################

sub import
{
    my $caller  = caller;

    my ( undef, $add_optz, $add_valz ) = @_;

    $add_optz ||= [];
    $add_valz ||= [];

    my $ref     = qualify_to_ref 'test_opts', $caller;

    my @optz    = ( @default_optz, @$add_optz );
    my %defz    = ( @default_valz, @$add_valz );

    *$ref
    = sub
    {
        my $cmdline = get_options [ @optz ], [ %defz ];

        for( keys %defz )
        {
            $cmdline->{ $_ } //= $ENV{ "\U$_" };
        }

        srand $cmdline->{ seed };

        wantarray
        ? %$cmdline
        : $cmdline
    };

    return
}

42

__END__
