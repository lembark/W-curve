########################################################################
# housekeeping
########################################################################

package WCurve::Fragment;

use v5.10;
use strict;
use overload;

use List::Util  qw( min max );

use ArrayObj
qw
(
    list
    name
    start
    stop
    size
    skip
    filler
);

__PACKAGE__->overload::OVERLOAD
(
    # use the starting offset of the sequence for the numeric value.
    # this leaves fragments sorted numerically by their location on
    # the main string of dna.

    q{""}   => sub { $_[0]->name    },
    q{0+}   => sub { $_[0]->start   },
    q{int}  => sub { $_[0]->size    },

    q{bool} => sub { !! $_[0]->list },
);

use Carp;
use LinkedList::Single;

use List::Util          qw( sum );
use Scalar::Util        qw( blessed );
use Symbol              qw( qualify_to_ref );

require WCurve::Fragment::FloatCyl;
#require WCurve::Fragment::FloatCart;

########################################################################
# package variables
########################################################################

our $VERSION    = 0.01;

########################################################################
# utility subs
########################################################################

########################################################################
# public interface
########################################################################

########################################################################
# construction

sub initialize
{
    my $frag    = shift;

    # with a arguments initialize the linked
    # list, otherwise just hand back the empty
    # fragment as-is.

    if( my ( $seq, $name, $start, $stop ) = @_ )
    {
        $start  ||= 1;
        $stop   ||= $start + ( length $seq ) - 1;
        $name   ||= join ' ', $start, '-', $stop;

        # $start - 1 == start of seqeunce, add a few
        # extra bases to get the curve in sync.

        my $offset  = $start - 1;

        if( blessed $seq )
        {
            $frag->list( $seq )
        }
        else
        {
            $seq    =~ s{\W+}{}gs;

            $seq
            or confess "Bogus Fragment: empty DNA string";

            # extract the fragment's sequence from the bulk DNA.
            # --$start converts from a count to an offset, gives
            # the inclusive length.

            my $listh   = LinkedList::Single->new;

            $frag->list ( $listh );

            my $seq     = substr $seq, $offset, ( $stop - $offset )
            or confess "Bogus fragment: no sequence $start .. $stop in\n$seq";

            # an extra four bases were included: splice them off
            # the start.

            $frag->generate( $seq, $start );
            $frag->head;
        }

        $frag->name ( $name  );
        $frag->start( $start );
        $frag->stop ( $stop  );
        $frag->size ( $stop - $start + 1 );

        $frag->filler( '' );
    }

    $frag->head
}

########################################################################
# hand back the node comparison functions (not method, function) for
# the given type.

sub return_handler
{
    my ( $frag, $verbose, $name ) = @_;

    my $class   = blessed $frag;

    my $handler
    = $class->can( $name )
    or confess "Bogus compre_nodes: '$frag' ($class) cannot '$name'";

    $verbose
    ? sub
    {
        my $val = &$handler;

        print "\t$name:\t[ $_[1]->[3] : $_[2]->[3] ] => $val\n";

        $val
    }
    : $handler
}

# sanity check guarantees a verbosity setting on the stack.

sub distance_handler { $_[1] ||= 0; return_handler @_, 'distance' }
sub diverge_handler  { $_[1] ||= 0; return_handler @_, 'diverge'  }

# removing the skip chain is pretty easy.

sub drop_skip
{
    my $frag    = shift;

    my $node    = $frag->head_node;

    while( @$node )
    {
        $#$node = 3;

        $node   = $node->[0];
    }

    $frag->skip( -1 );

    $frag
}

########################################################################
# dispatch anything unknown to the linked list

our $AUTOLOAD;

AUTOLOAD
{
    my $i       = rindex $AUTOLOAD, ':';
    my $name    = substr $AUTOLOAD, ++$i;

    my $frag    = $_[0];
    my $listh   = $frag->list;

    my $handler = $listh->can( $name )
    or confess "Bogus $name: '$listh' cannot '$name'";

    my $ref     = qualify_to_ref $name;

    *$ref
    = sub
    {
        splice @_, 0, 1, $_[0]->list;

        goto &$handler
    };

    goto &{ *{ $ref } }
}

# keep require happy

1

__END__
