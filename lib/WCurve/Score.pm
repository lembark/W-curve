########################################################################
# housekeeping
########################################################################

package WCurve::Score;

use v5.10;
use strict;
use parent qw( ArrayObj );

use Carp;

use Exporter::Proxy qw( score );
use List::Util      qw( sum );
use Scalar::Util    qw( looks_like_number );
use Symbol          qw( qualify_to_ref );

use WCurve::Score::Display;
use WCurve::Score::SumChunks;

__PACKAGE__->init_attr
(
    qw
    (
        verbose
        debug

        gap_cost
        indel_cost
        prior_cost
        after_cost
        fail_score
        values

        payload
    )
);

my %defaultz
= qw
(
    fail_score  2
);

$defaultz{ $_ } //= 0
for __PACKAGE__->attributes;

########################################################################
# package variables
########################################################################

########################################################################
# public interface
########################################################################

sub initialize
{
    my ( $scoreh, %parmz ) = shift;

    $parmz{ $_ } //= $defaultz{ $_ }
    for keys %defaultz;

    # need a new payload for each object.

    $parmz{ payload } ||= {};

    @$scoreh    = @parmz{ $scoreh->attributes };

    $scoreh
}

sub output_list
{
    my $score   = shift;

    # @resultz is left on the stack.

    my @scorz   = map { $score->compute( $_ ) } @_;

    wantarray
    ?  @scorz
    : \@scorz
}

sub payload
{
    state $i    = __PACKAGE__->payload_offset;

    my $wc  = shift;

    $wc->[$i] ||= {}
}

# keep require happy

1

__END__
