########################################################################
# housekeeping
########################################################################

package WCurve;

use v5.12;
use strict;
use autodie     qw( open close );

use ArrayObj;

use Carp;
use File::Basename;

use JSON::XS        qw();
use List::Util      qw( sum );
use Scalar::Util    qw( looks_like_number reftype blessed );
use Symbol          qw( qualify qualify_to_ref );

use WCurve::Fragment;
use WCurve::Compare;
use WCurve::Score;

use WCurve::ReadSeq;
use WCurve::DistMatrix;

use overload

    q{""}   => sub { "$_[0][1]"     },

    q{int}  => sub { scalar @{ $_[0][0] }  },

    q{0+}   =>
    sub
    {
        my $wc  = shift;

        sum map { int $_ } @{ $wc->[0] }
    },
;

__PACKAGE__->init_attr
(
    qw
    (
        fragments
        name
        composite
        description
        template
        sequence
        payload
    )
);

########################################################################
# package variables
########################################################################

our $VERSION    = 0.01;

# valid curve types. note that some types may be
# aviable for testing but not generated via the
# mechanism available here.

our @valid_typz
= qw
(
    FloatCart
    FloatCyl
);

########################################################################
# install derived classes for WCurve::<frag_type>. all these really
# do is hardwire the fragment type method.

for my $type ( @valid_typz )
{
    my $wc_pkg      = qualify $type;
    my $frag_pkg    = qualify $type, 'WCurve::Fragment';

    my $isa         = qualify_to_ref 'ISA',  $wc_pkg;
    my $type_sub    = qualify_to_ref 'type', $wc_pkg;
    my $frag_sub    = qualify_to_ref 'fragment_type', $wc_pkg;
    my $version     = qualify_to_ref 'VERSION', $wc_pkg;

    *$isa           = [ qw( WCurve ) ];

    *$type_sub      = sub { $type       };  # 'Foobar'
    *$frag_sub      = sub { $frag_pkg   };  # 'WCurve::Fragment::Foobar'

    *$version   = \$VERSION;
}

########################################################################
# methods
########################################################################

# set shared verbosity setting.

sub verbose
{
    state $verbose  = $ENV{ VERBOSE };

    @_ > 1
    ? $verbose = $_[1]
    : $verbose
}

# return the valid types.
# short-circut the type looks for this class.

sub valid_types { wantarray ? @valid_typz : [ @valid_typz ] }

sub type
{
    croak "Bogus WCurve::type: untyped WC"
};

sub fragment_type
{
    croak "Bogus WCurve::fragment_type: untyped WC"
};

sub payload
{
    state $i    = __PACKAGE__->payload_offset;

    my $wc  = shift;

    $wc->[$i] ||= {}
}

########################################################################
# construct, initialize, destroy.

sub initialize
{
    my $wc  = shift;

    $wc->name( shift )
    if @_;

    if( @_ )
    {
        my @fragz
        = do
        {
            if( blessed $_[0] )
            {
                # list of fragments, use as-is

                @_
            }
            elsif( 'ARRAY' eq reftype $_[0] )
            {
                # arrayref of fragments, expand it.

                @{ $_[0] }
            }
            else
            {
                # subsequence definitions: dna followed by
                # list of fragment def's.

                my $seq     = shift;

                $wc->sequence( lc $seq );

                # at this point anything left on the stack
                # defines the subseq's, which all have the
                # same storage type.

                my $type    = $wc->type;

                map
                {
                    WCurve::Fragment->new( $type, $seq, @$_ )
                }
                sort
                {
                    # sort by begin value.

                    $a->[1] <=> $b->[1]
                }
                @_ ? @_ : []
            }
        };

        $wc->fragments  ( \@fragz       );
        $wc->composite  ( @fragz > 1    );
    }

    $wc
}

DESTROY
{
    my $wc  = shift;

    $#$wc   = -1;

    return
}

########################################################################
# attributes

sub fragments
{
    my $wc  = shift;

    if( @_ )
    {
        $wc->[0]
        = @_ > 1
        ? [ @_ ]
        : shift
        ;

        $wc->composite( $wc > 1 );
    }

    given( wantarray )
    {
        when( ''    ) { return [ @{ $wc->[0] } ]    }
        when( 1     ) { return   @{ $wc->[0] }      }
        when( undef ) { return                      }
    }
}

sub count
{
    int $_[0]
}

sub filler
{
    sum map { $_->filler } $_[0]->fragments
}

sub active
{
    my $wc  = shift;

    $wc->count - $wc->filler
}

sub reset
{
    my $wc  = shift;

    $_->head for $wc->fragments;

    $wc
}

########################################################################
# write out the fragments in template format.

sub write_template
{
    my ( $wc, $path ) = @_;

    open my $fh, '>', $path
    or die "Roadkill: $path, $!";

    local $\    = "\n";
    local $,    = "\t";

    print $fh '%' . $wc->description
    or die "Roadkill: print $path, $!";

    for my $frag ( $wc->fragments )
    {
        local $\    = ";\n";

        print $fh map { $frag->$_ } qw( name start stop )
        or die "Roadkill: print $path, $!";
    }

    for my $seq ( lc $wc->sequence )
    {
        $seq    =~ s/\W+//g;

        print $fh substr $seq, 0, 80, ''
        while $seq;
    }

    close $fh
    or die "Roadkill: $path, $!";

    $wc
}

# called from curview-interface code, this will take in a 
# fasta input (or path) and return the json-
# encoded structure. 

sub curview
{
    state $handler  = JSON::XS->can( 'encode_json' );

    my $wc  = shift;

    my @structz
    = map
    {
        scalar $_->curview
    }
    $wc->fragments;

    # check that the viewer code handles multiple curves.

    encode_json $structz[0]
}

1

__END__

=head1 NAME

WCurve - Container class for W-curve fragments.

=head1 SYNOPSIS

    # valid types are provided in @valid_typz.  # $dna can be a char string, which is used to construct
    # fragments, or a reference at which point it's taken as-is.

    # the name is used to stringify the WC.
    #
    # generate a single fragment from a dna string or multiple
    # fragments of the same dna string via additional arguments
    # to specify the fragment names, start and stop in base
    # notation (i.e., counts, with start beginning at 1).

    my $dna = 'catg....';

    my $wc  = WCurve->new( $type => $dna, $name );

    my $wc  = WCurve->new
    (
        $type => $dna_string,
        [ frag_name => frag_start,  frag_end ],
        ...
    );

    # provide the DNA object as a fragment or array
    # of fragments. references are used as-is for the
    # fragment array -- just be careful that they are
    # either fragments or at least arrayref's.

    my $dna = WCurve::Fragment::SomeType->read_seq( @pathz );

    my $wc  = WCurve->new( $type => $dna, $name );

    print "The WC is named: '$wc'";

    # reset all of the fragments to their head node.
    # use before starting a wc:wc comparision.

    $wc->head;

=head1 DESCRIPTION

WC's contain Fragments of curves, which can range from
an entire DNA sequence to an empty one. Their main use
is in grouping the Fragments together for comparision.

=head2 Methods

=head3 Configure, update the WC contents

=over 4

=item inialize

=item read_seq

=item verbose

=item add_skip_chain

=back

=head3 Information

=over 4

=item valid_types

List of valid WCurve::Fragment types (first argument to new).

=item type

Returns the type argument of the current WC (or confess if
the WC is not blessed into a derived class).

=item fragment_type

Determine the fragment's full class (or confess if
they are not blessed into a derived class).

=item name

Return the WC's name.

=item fragments

Return the array of fragments in the WC.

=item compare_nodes

Returns a subref for the node comparision utility for
the fragment type contained in the WC.

=back

=head1 AUTHOR

Steven Lembark <lembark@wrkhrs.com>

=head1 COPYRIGHT

Copyright (C) 2010, Steven Lembark all rights reserved.

=head1 LICENSE

This module is released under the same terms as Perl-5.10
itslef.
