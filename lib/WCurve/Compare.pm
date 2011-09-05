########################################################################
# housekeeping
########################################################################

package WCurve::Compare;

use v5.12;
use strict;
use ArrayObj;

use Carp;

use List::Util      qw( max min sum );

use WCurve::Util::DumperConfig;

use WCurve::Compare::PrintResults;

__PACKAGE__->init_attr
(
    qw
    (
        verbose
        debug
        catenate
        payload
    )
);

########################################################################
# package variables
########################################################################

our $VERSION    = 0.02;

########################################################################
# utility subs
########################################################################

########################################################################
# public interface
########################################################################

# initialize: default is to use composite curves 
# for multi-fragment ($wc->composite) curves. 
# the multiple fragments can return concatenated 
# results using multi type of 

sub initialize
{
    my $comp    = shift;

    $comp->$_( '' ) 
    for qw( catenate );

    $comp
}

sub payload
{
    state $p    = __PACKAGE__->payload_offset;

    my $comp    = shift;

    if( ref $_[0] )
    {
        $comp->[ $p ] = shift
    }
    elsif( @_ )
    {
        my %new  = @_;
        my $pass = $comp->[ $p ] ||= {};

        @$pass{ keys %new } = values %new;

        $pass
    }
    else
    {
        $comp->[ $p ] ||= {}
    }
}

########################################################################
# comparision iterators. 
# these determine which combnations of fragments from which
# of the WC's get compared to which other ones and what the
# output will be (e.g., square or upper-triangular matrix).
########################################################################

########################################################################
# bulk comparision: extract all of the fragments, validate their
# base storage type and compare them all to each other, ignoring
# the wc's entirely.

my $sanity_check
= sub
{
    my $type    = $_[0]->fragment_type;

    my @bogus
    = map
    {
        my $t   = $_->fragment_type;

        $type ne $t
        ? "$_ ($t)"
        : ()
    }
    @_
    or return;

    local $"    = ' ';

    confess "Bogus compare: non-'$type' fragments in: @bogus"
};

sub compare_list
{
    my ( $comp, $wc0 ) = splice @_, 0, 2;

    my @resultz 
    = map 
    {
        scalar $comp->compare( $wc0, $_ ) 
    }
    @_;

    wantarray
    ?  @resultz
    : \@resultz
}

sub upper_tri
{
    my $comp    = shift;

    &$sanity_check;

    my @resultz
    = map
    {
        my $wc0 = shift;

        scalar $comp->compare_row( $wc0, @_ )
    }
    ( 1 .. @_ );

    wantarray
    ?  @resultz
    : \@resultz
}

########################################################################
# iterate the contents of the W-curve as either single or not.

sub compare_type
{
    sum map { $_->composite } @_[1,2]
}

sub compare
{
    $#_ = 2;

    $sanity_check->( @_[1,2] );

    $_->reset for @_[1,2];

    given( compare_type @_ )
    {
        when( 0 ) { goto &single_single }
        when( 1 ) { goto &single_multi  }
        when( 2 ) { goto &multi_multi   }
    }
}

sub single_single
{
    my ( $comp, $wc0, $wc1 ) = @_;

    print "\nCompare: [ $wc0 : $wc1 ]\n"
    if $comp->verbose;

    my @fragz   = map { ( $_->fragments )[0] } ( $wc0, $wc1 );

$DB::single = 1 if $comp->debug;

    my @resultz = $comp->compare_fragments
    (
        symmetric => @fragz
    );

    $comp->print_results( $wc0, $wc1, @resultz )
    if $comp->verbose;

    wantarray
    ?   @resultz
    :  \@resultz
}

sub single_multi
{
    my $comp    = shift;

    my ( $wc0, $wc1 ) 
    = sort { $a->composite <=> $b->composite } @_[0,1];

    my $name0       = $wc0->name;
    my $name1       = $wc1->name;

    print "\nCompare: '$name0' : '$name1'\n";

    my ( $frag0 )   = $wc0->fragments;

    my $prior       = 0;
    my @resultz     = ();

    my $verbose     = $comp->verbose;

    for my $frag1 ( $wc1->fragments )
    {
        print "\n\t[ $frag0 : $frag1 ]\n";

        if( ! $frag0 )
        {
            # exhausted the single-sequence curve: 
            # there is nothing left to compare.

            last
        }
        elsif( ! $frag1 )
        {
            # caller didn't reset things properly
            # on the way in. they'll notice the false
            # value for a non-filler fragment on the
            # way out.
            #
            # there may be a reason for having empty
            # fragments, not sure (yet) if this is an
            # exception.

            push @resultz, -1;

            next
        }
        else
        {
            my @chunkz
            = eval 
            {
                $comp->compare_fragments
                (
                    composite => $frag0, $frag1
                )
            };

            if( $@ )
            {
                warn;
                print "\nFailed: [ $frag0 : $frag1 ], $@\n"
            }
            elsif( @chunkz )
            {
                undef $chunkz[0][0]
                if $frag1->filler;

                my $after   = $chunkz[-1][1];

                my $advance = $after - $prior;

                $frag0->list->next( $advance );

                $prior      = $after;

                if( $verbose )
                {
                    print
                    $frag1->filler
                    ? "\nFiller: $name1 $frag1\n"
                    : "\nChunks: $name0 : $name1 $frag1\n", Dumper \@chunkz
                }
            }
            elsif( $comp->verbose )
            {
                $comp->botched
                (
                    compare_fragments   => 'No alignment',
                    composite           => $frag0, $frag1
                );
            }
            else
            {
                print "\nNo alignment: [ $frag0 : $frag1 ]\n";
            }

            push @resultz, \@chunkz;
        }
    }

    $comp->print_results( $wc0, $wc1, @resultz )
    if $comp->verbose;

    # note that @resultz may be a runt list
    # if $frag0 is false -- the caller can
    # check that for themselves.

    wantarray
    ?  @resultz
    : \@resultz
}

sub multi_multi
{
    my ( $comp, $wc0, $wc1 ) = @_;

    my @fragz0  = $wc0->fragments;
    my @fragz1  = $wc1->fragments;

    my $last    = min $#fragz0, $#fragz1;

    my $a       = join ' ', map { "$_" } $wc0, ':', @fragz0;
    my $b       = join ' ', map { "$_" } $wc1, ':', @fragz1;

    print "Comparing:\n\t$a\n\t$b\n";

    my $cat     = $comp->catenate;

$DB::single = 1 if $comp->debug;

    my @resultz
    = map
    {
        my $frag0   = $fragz0[$_];
        my $frag1   = $fragz1[$_];

        $frag0->filler || $frag1->filler
        ? ()
        : do 
        {
            print "Compare: [ $frag0 : $frag1 ]\n";

            my @chunkz
            = $comp->compare_fragments
            (
                symmetric =>
                $frag0,
                $frag1,
            );

            $cat
            ? @chunkz
            : \@chunkz
        }
    }
    ( 0 .. $last );

    $comp->print_results( $wc0, $wc1, @resultz )
    if $comp->verbose;

    wantarray
    ?  @resultz
    : \@resultz
}

########################################################################
# use the comparison engine to generate alignments for partitioning
# a single curve into a composite.
########################################################################

sub partition
{
    my ( $comp, $wc, $template ) = @_;

    print "\nPartition: '$wc' using '$template'\n";

    $wc->composite 
    and confess "Bogus partition: '$wc' already composite";

    my @resultz = $comp->compare( $wc, $template )
    or return;

    print "\nAlignments:\n";

    $comp->print_results( partition => $wc, $template, @resultz );

    print "\nFragments:\n";

    my ( $old ) = $wc->fragments;

    $old->root;
    $old->drop_skip;

    my @new_fragz   = ();
    my $i           = 0;

    for( $template->fragments )
    {
        my $top     = $old->next_data->[2];

        my $chunkz  = $resultz[ $i   ];
        my $next    = $resultz[ $i+1 ];

        my ( $start, $stop )
        = do 
        {
            if( $chunkz && @$chunkz )
            {
                ( $chunkz->[1][1], $chunkz->[-1][1] )
            }
            elsif( $next && @$next )
            {
                # start of the next section may be higher
                # up due to mismatch in the curves, use 
                # the minimum of template size or the next
                # start as the boundry.

                my $a   = $next->[1][1];
                my $b   = $top + $_->size;

                ( $top, ( min $a, $b ) - $_->snp_window )
            }
            else
            {
                # best guess is the template.

                ( $top, $top + $_->size - $_->snp_window );
            }
        };

$DB::single = 1 if $top   > $start;
$DB::single = 1 if $start > $stop;

        my $cruft   = $start - $top;
        my $length  = $stop - $start + 1;

        $old->splice( $cruft );

        my $list    = $old->splice( $length );

        my $new     = $old->new( $list, "$_", $start, $stop );

        $new->filler( $_->filler );

        push @new_fragz, $new;

        ++$i;
    }

    $wc->fragments( @new_fragz );

    return
}

########################################################################
# used for reporting failures during tests
########################################################################

my $fail
= Test::More->can( 'fail' )
|| sub
{
    local $\    = "\n";
    local $,    = "\n";

    print STDERR @_
};

sub botched
{
    local $Data::Dumper::Maxdepth   = 4;

    my ( $comp, $method, $reason ) = splice @_, 0, 3;

    $fail->( "Botched $method: $reason" );

    print "\n",
    do 
    {
        join "\n", map { (ref) ? Dumper $_ : $_ } @_;
    };

    # allows scattering progromattic breakpoints in the code.

    local $::botched  = [ $method, $reason ];

    my $v               = $comp->verbose_offset;
    local $comp->[$v]   = 2;
    local $comp->payload->{ verbose } = 2;

    eval { print "\nResults:\n", Dumper $comp->$method( @_ ) }
    or print "Failed $method: $@";

    # hand back something for 'die'.

    $reason . "\n"
}

# keep require happy

1

__END__
