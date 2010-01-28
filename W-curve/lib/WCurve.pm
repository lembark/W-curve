########################################################################
# housekeeping
########################################################################

package WCurve;

use v5.10;
use strict;

use Carp;

use Symbol          qw( qualify qualify_to_ref );
use Scalar::Util    qw( blessed looks_like_number refaddr );

use WCurve::Compare;
use WCurve::Constants;
use WCurve::Generate;
use WCurve::Output;
use WCurve::ReadSeq;
use WCurve::Score;

use WCurve::Floating;
#use WCurve::Integer;

# propagate values from constants.

use Exporter::Proxy
qw
(
    anglz
    cornerz
);

########################################################################
# overloading
########################################################################

my $switch
= sub
{
    $_[2] ? @_[1,0] : @_[0,1]
};

use overload
(
    q{<=>}   =>
    sub
    {
        my ( $a, $b ) = &$switch;

        ( $a + 0 ) <=> ( $b + 0 )
    },

    q{+}    =>
    sub
    {
        # ignore the switch, addition is commutative.

        my( $wc, $x ) = @_;

        $wc->[1] + $x
    },

    q{bool} =>
    sub
    {
        defined $_[0]
    },

    q{0+}   =>
    sub
    {
        # the length

        $_[0]->[1] || 0;
    },

    q{""}   =>
    sub
    {
        # whatever the caller stored there...

        $_[0]->[2] // ''
    },
);

########################################################################
# package variables
########################################################################

our $VERSION    = 0.001;

########################################################################
# methods
########################################################################

sub new
{
    my $wc  = &construct;

    $wc->generate( @_ );

    $wc
}

sub construct
{
    my $proto   = shift;

    my $pkg     = blessed $proto;

    $pkg
    ||= do
    {
        my $module  = shift;

        qualify $module, $proto
    };
    
    bless [], $pkg
}

# avoid problems due to long sequences blowing up in 
# perl's recursive deallocator.

DESTROY
{
    my $wc  = shift;

    # expanding arrays avoids segfault in 5.10.1.
    # using $wc = $wc->[0] while @$wc->[0] gets sig11.

    @$wc    = @{ $wc->[0] }
    while $wc->[0];

    return
}

# extract contents of the linked list into an array.
# map avoids problems with push over-extending the
# resulting array.

sub array
{
    my $wc      = shift;

    my $node    = $wc->[0];

    my @array
    = map
    {
        my $a   = [];

        ( $node, @$a ) = @$node;

        $a
    }
    ( 1 .. $wc );

    wantarray
    ?  @array
    : \@array
}

1

__END__


=head1 NAME

WCurve - DNA sequence comparision using the W-curve.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 COPYRIGHT

Copyright (C) 2009-2010 Steven Lembark.

=head1 LICENSE

This code is released under the same terms as Perl 5.10.
