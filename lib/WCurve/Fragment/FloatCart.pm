########################################################################
# housekeeping
########################################################################

package  WCurve::Fragment::FloatCart;

use v5.12;
use strict;
use parent  qw( WCurve::Fragment );

use Carp;

use WCurve::Values;

########################################################################
# package variables
########################################################################

our $VERSION    = 0.1;

########################################################################
# utility subs
########################################################################

########################################################################
# public interface
########################################################################

sub converge_limit  { 2 ** -2   }
sub snp_window      { 8         }

sub generate
{
    my ( $frag, $seq ) = @_;

    my ( $xc, $yc ) = ( 0, 0 );
    my ( $x,  $y  ) = ( 0, 0 );
    my $z           = 0;

    my $listh   = $frag->list->head;

    while( my $base = substr $seq, 0, 1, '' )
    {
        # cartesian co-ords of the modpoint of a line are
        # at the midpoints along x & y. this will simply be
        # the average of the sides.

        ( $xc, $yc ) = @{ $cornerz{ $base } }
        or confess "Botched sequence: unknown base '$base' at offset $z";

        $x  = ( $xc + $x ) / 2;
        $y  = ( $yc + $y ) / 2;

        $_
        = $_ >  $ZERO
        ? $_
        : $_ < -$ZERO
        ? $_
        : 0
        for $x, $y;

        $listh->push( $x, $y, ++$z );
    }

    return
}

sub add_skip_chain
{
    my $default = 0.50;

    my $frag    = shift;
    my $cutoff  = shift // $default;

    looks_like_number $cutoff
    or croak "Bogus add_skip_chain: non-numeric '$cutoff'";

    $cutoff >= 0
    or croak "Bogus add_skip_chain: negative '$cutoff'";

    unless( $frag->skip == $cutoff )
    {
        my $listh       = $frag->list->clone->head;
        my $node        = $$listh;

        my ( $x, $y, $z )   = ( 0, 0, 0 );

        for( ;; )
        {
            ( $x, $y, $z )  = $listh->each
            or last;

            $x ** 2 + $y ** 2 > $cutoff
            or next;

            my $skip        = $$listh;

            while( $node->[3] < $z )
            {
                $node->[4]   = $skip;
                $node        = $node->[0];
            }
        }

        # flag the fragment as having a chain.

        $frag->[4]  = $cutoff;
    } 

    return
}

sub distance
{
    my ( $x0, $y0 ) = @{ $_[0] }[1,2];
    my ( $x1, $y1 ) = @{ $_[1] }[1,2];

    abs( $x0 - $x1 )
    +
    abs( $y0 - $y1 )
}

sub diverge
{
    &quiet > 0.50
}

########################################################################
# use for gnuplot vector output: 6 points per vector.

sub vector
{
    my ( $frag, $path ) = @_;

    my $fh 
    = '-' eq $path
    ? *STDOUT{ IO }
    : $path =~ /[.]gz$/
    ? IO::File->new( "| gzip -9 > $path" )
    : IO::File->new( "> $path" )
    ;

    local $\    = "\n";
    local $,    = "\t";

    my @last    = ( 0, 0, 0 );
    my @curr    = ();
    my @delta   = ();

    $frag->head;

    while( @curr = $frag->each )
    {
        @delta
        = map { $curr[$_] - $last[$_] } ( 0 .. @curr );

        $fh->printflush( @last, @delta )
        or die "printflush: $path, $!";

        @last   = @curr;
    }

    return
}

sub porcupine
{
    my ( $frag, $path, $cutoff ) = @_;

    my $fh 
    = '-' eq $path
    ? *STDOUT{ IO }
    : $path =~ /[.]gz$/
    ? IO::File->new( "| gzip -9 > $path" )
    : IO::File->new( "> $path" )
    ;

    my ( $x, $y, $z )   = ( 0, 0, 0 );

    local $\    = "\n";
    local $,    = "\t";

    my @curr    = ();
    my $r       = 0;

    $cutoff     **= 2;

    for my $i ( 0 .. 1 )
    {
        $frag->head;

        while( @curr = $frag->each )
        {
            $r  = $curr[0] ** 2 + $curr[1] ** 2;

            given( $i )
            {
                when( 0 ) { $r <= $cutoff or next }
                when( 1 ) { $r >  $cutoff or next }
            }

            $fh->printflush( 0, 0, @curr[2,0,1], 0 )
            or die "printflush: $path, $!";
        }

        $fh->printflush( "\n" );
    }

    return
}

# keep require happy

1

__END__
