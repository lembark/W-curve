########################################################################
# housekeeping
########################################################################

package WCurve::Compare::MatchingPeaks;

use v5.12;
use strict;

use parent qw( WCurve::Compare );

use Carp;

use Exporter::Proxy qw( matching_peaks );
use Scalar::Util    qw( looks_like_number );
use Symbol          qw( qualify_to_ref );

use WCurve::Values;
use WCurve::Util::DumperConfig;
use WCurve::Compare::MatchingPeaks::NodeOps;

########################################################################
# package variables
########################################################################

our $VERSION    = v0.0.2;

my $gap_window  = 16;

my %defaultz =
(
    verbose     =>  0,
    debug       =>  '',
    payload    =>
    {
        radius              => 0.50,    # 0.528,
        verbose             => 0,

        snp_window          => $ENV{ SNP_WINDOW },  # no default
        gap_window          => $ENV{ GAP_WINDOW }   || 16,

        composite_margin    => $ENV{ CMP_MARGIN }   || 5,
        symmetric_margin    => $ENV{ SYM_MARGIN }   || 4,

        symmetric_window    => 2 * $gap_window,
    },
);

########################################################################
# utility subs
########################################################################

my $dispatch
= sub
{
    state $dist = qualify_to_ref 'distance';
    state $div  = qualify_to_ref 'diverge';

    my ( $comp, $align_type, $frag0, $frag1, $node_op ) = @_;

    print "Compare: $node_op ($align_type)"
    if $comp->verbose;

    my $handler = WCurve::Compare::MatchingPeaks::NodeOps->can( $node_op )
    or croak "Bogus dispatch: unknown '$node_op'";

    # cannot use head here since we may be aligning one
    # of the fragments mid-sequence.

    $frag0  or confess "Bogus $node_op: false fragment-0 on stack";
    $frag1  or confess "Bogus $node_op: false fragment-1 on stack";

    @$frag0 or confess "Bogus $node_op: empty fragment-0 on stack";
    @$frag1 or confess "Bogus $node_op: empty fragment-1 on stack";

    my $node0   = $frag0->node
    or confess "Bogus compare: Uninitialized list '$frag0'";

    my $node1   = $frag1->node
    or confess "Bogus compare: Uninitialized list '$frag1'";

    my $z0   = $node0->[3];
    my $z1   = $node1->[3];

    my $e0  = $frag0->stop;
    my $e1  = $frag1->stop;

    # grab values from the fragment, see sanity checks
    # below. assigning the local values here is optimistic,
    # but it is reasonable

    my $parmz   = $comp->payload;

    local $parmz->{ snp_window } //= $frag0->snp_window;

    my $verbose = $parmz->{ verbose } ||= 0;

    local $parmz->{ debug } = $verbose > 1;
    local $parmz->{ trace } = $verbose > 2;

    local *{ $div   }   = $frag0->diverge_handler ( $parmz->{ trace } );
    local *{ $dist  }   = $frag0->distance_handler( $parmz->{ trace } );

    printf "\n%16.16s\n    [%5d .. %5d] (%5d) %s\n    [%5d .. %5d] (%5d) %s\n",
    'Matching Peaks:',
    $z0, $e0, $e0 - $z0, "$frag0",
    $z1, $e1, $e1 - $z1, "$frag1",
    ;

    $_->add_skip_chain( $parmz->{ radius } )
    for ( $frag0, $frag1 );

    for my $defz ( $defaultz{ payload } )
    {
        $parmz->{ $_ } //= $defz->{ $_ }
        for keys %$defz;
    }

    print Dumper( $parmz ), "\n"
    if $comp->debug;

$DB::single = 1 if $comp->debug;

    setup_compare $parmz;

    $handler->( $align_type, $node0, $node1, $e0, $e1 )
};

########################################################################
# public interface
########################################################################

########################################################################
# validate the radius, verbosity

sub initialize
{
    my ( $comp, %parmz ) = @_;

    $parmz{ $_ } //= $defaultz{ $_ }
    for keys %defaultz;

    for( $comp->attributes )
    {
        $parmz{ $_ } // next;

        $comp->$_( $parmz{$_} );
    }

    return
}

########################################################################
# top_half of the comaprision: prepare the curves by adding skip chains,
# set radius, verbose/debug/trace level.
#
# compare_fragments is dispatched from WCurve::Compare.
#
# note that these have to make a point of *not* modifying
# the node positions in order to allow for daisy-chained
# comparisions of smaller fragments within a larger one.
# net result: do not call head and leave the nodes at the
# end-of-comparision; use clone to directly modify the node
# position.

sub compare_fragments
{
    push @_, 'compare_nodes';

    goto &$dispatch
}

sub align_fragments
{
    push @_, 'initial_alignment';

    goto &$dispatch
}


# keep require happy

1

__END__
