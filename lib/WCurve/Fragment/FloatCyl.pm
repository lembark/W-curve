########################################################################
# housekeeping
########################################################################

package  WCurve::Fragment::FloatCyl;

use v5.12;
use strict;
use parent qw( WCurve::Fragment );

use Carp;
use JSON::XS;

use Scalar::Util        qw( looks_like_number );

use WCurve::Values;
use WCurve::Util::ColorTable qw( cyl2rgb );

########################################################################
# package variables
########################################################################

our $VERSION    = 01;

########################################################################
# utility subs
########################################################################

my $ra2xy
= sub
{
    state $cos  = 0;
    state $sin  = 0;
    state $x    = 0;
    state $y    = 0;

    my ( $r, $a ) = @_;

    $sin    = sin $a;
    $cos    = cos $a;

    ( abs $_ ) > $TINY or $_ = 0 for $sin, $cos;

    $x      = $r * $sin;
    $y      = $r * $cos;

    ( abs $_ ) > $TINY or $_ = 0 for $x, $y;

    ( $x, $y )
};

########################################################################
# public interface
########################################################################

sub converge_limit  { 2 ** -3   }
sub snp_window      { 6         }

sub generate
{
    my ( $frag, $seq, $z ) = @_;

    $z  ||= 1;

    my ( $xc, $yc ) = ( 0, 0 );
    my ( $x,  $y  ) = ( 0, 0 );
    my ( $r,  $a  ) = ( 0, 0 );

    my $sin         = 0;

    my $listh   = $frag->list->head;

    for my $i ( 0 .. ( length $seq ) - 1 )
    {
        given( substr $seq, $i, 1 )
        {
            when( %cornerz )
            {
                # cartesian co-ords of the modpoint of a line are
                # at the midpoints along x & y. this will simply be
                # the average of the sides.

                ( $xc, $yc ) = @{ $cornerz{ $_ } };

                $x  = ( $xc + $x ) / 2;
                $y  = ( $yc + $y ) / 2;
            }

            print "Botched sequence: unknown base '$_' at offset $i\n";

            $x = $y = 0;
        }

        $a  = atan2 $y, $x;

        $a  
        = $a > +$TINY
        ? $a
        : $a < -$TINY
        ? $a
        : 0
        ;

        $sin    = sin $a;

        $r
        = abs( $sin ) > $ZERO
        ? abs( $y / $sin )
        : abs( $x )
        ;

        $r > $ZERO
        or $r = 0;

        $listh->push( $r, $a, $z++ );
    }

    return
}

sub add_skip_chain
{
    state $default = 0.25;

    my $frag    = shift;
    my $cutoff  = shift // $default;

    looks_like_number $cutoff
    or croak "Bogus add_skip_chain: non-numeric '$cutoff'";

    $cutoff >= 0
    or croak "Bogus add_skip_chain: negative '$cutoff'";

    # not that undef != $cutoff is true, which leaves 
    # the first skip chain added.

    if( $frag->skip != $cutoff )
    {
        my $node    = $frag->list->head_node;
        my $skip    = $node;

        my ( $r, $z )   = ( 0, 0 );

        for( ;; )
        {
            @$skip 
            or last;

            $skip       = $skip->[0];

            ( $r, $z )  = @$skip[1,3];

            $r > $cutoff
            or next;

            while( $node->[3] < $z )
            {
                $node->[4]   = $skip;
                $node        = $node->[0];
            }
        }

        # flag the fragment as having a chain.

        $frag->skip( $cutoff );
    } 

    return
}

sub distance
{
    my ( $node0, $node1 ) = @_;

    my ( $r0, $a0 )    = @{ $node0 }[1,2];
    my ( $r1, $a1 )    = @{ $node1 }[1,2];

    $r1 > $r0
    and ( $r0, $r1 ) = ( $r1, $r0 );

    my $a
    = $a1 > $a0
    ? $a1 - $a0
    : $a0 - $a1
    ;

    $a      = $two_pi - $a if $a > $PI;

    my $diff   = $r0 - $r1 * cos $a;

    # rounding error may leave $diff negative. 

    $diff > $TINY
    ? $diff
    : 0
}

sub diverge
{
    $_[0] > 0.25 
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

    my ( $r, $a )       = ( 0, 0 );
    my ( $x, $y, $z )   = ( 0, 0, 0 );
    my ( $dx, $dy )     = ( 0, 0 );
    my ( $x1, $y1 )     = ( 0, 0 );

    my $listh           = $frag->list;

    local $\    = "\n";
    local $,    = "\t";

    $listh->head;

    for(;;)
    {
        ( $r, $a, $z ) = $listh->each
        or last;

        ( $x1, $y1 ) = $ra2xy->( $r, $a );

        $dx = $x1 - $x;
        $dy = $y1 - $y;

        $fh->printflush( $x, $y, $z, $dx, $dy, 1 )
        or die "printflush: $path, $!";

        $x  += $dx;
        $y  += $dy;
    }

    return
}

sub porcupine
{
    my ( $frag, $path, $radius ) = @_;

    my $fh 
    = '-' eq $path
    ? *STDOUT{ IO }
    : $path =~ /[.]gz$/
    ? IO::File->new( "| gzip -9 > $path" )
    : IO::File->new( "> $path" )
    ;

    my ( $r, $a )       = ( 0, 0 );
    my ( $x, $y, $z )   = ( 0, 0, 0 );

    local $\    = "\n";
    local $,    = "\t";

    my $listh   = $frag->list;

    $listh->head;

    for(;;)
    {
        ( $r, $a, $z ) = $listh->each
        or last;

        $r >  $radius or next;

        ( $x, $y ) = $ra2xy->( $r, $a );

        $fh->printflush( 0, 0, $z, $x, $y, 0 )
        or die "printflush: $path, $!";
    }

    $fh->printflush( "\n" );

    return
}

# convert the struct to ( x, y, z, r, g, b )

sub curview
{
    my $frag   = shift;

    my $listh   = $frag->list->head;

    # name, size, [ x, y, z, r, g, b ]
    # 0 placeholder is filled in below.

    my @coordz =
    (
        "$frag",
        0,
    );

    while( my ( $radius, $angle ) = $listh->each )
    {
        # r + a to cartesian

        my $x       = $radius * sin $angle;
        my $y       = $radius * cos $angle;

        abs $_ > $TINY or $_ = 0
        for $x, $y;

        # HSV color from angle/rad to RGB

        my $color   = cyl2rgb $radius, $angle;

        # note the lack of Z-axis value.
        
        push @coordz, [ $x, $y, @$color ];
    }

    $coordz[1]  = @coordz;

    wantarray
    ?  @coordz
    : \@coordz
}

sub json
{
    my $frag    = shift;

    my $struct  = $frag->json_struct;

    encode_json $struct
}


# keep require happy

1

__END__
