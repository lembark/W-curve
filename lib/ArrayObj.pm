########################################################################
# housekeeping
#####################################M##################################

package ArrayObj;

use v5.10;
use strict;

use Carp;
use NEXT;

use Scalar::Util    qw( blessed );
use Symbol          qw( qualify qualify_to_ref );

use overload

# Basically: the object is true if populated, numeric
# op's are all passed off to the first entry, string
# conversion to the second.

    q{bool} =>
    sub
    {
        # the object is true if it is populated.

        !! @{ $_[0] }
    },

    q{<=>} =>
    sub
    {
        $_[2]
        ? ( int $_[1] ) <=> ( int $_[0] )
        : ( int $_[0] ) <=> ( int $_[1] )
    },

    q{cmp} =>
    sub
    {
        $_[2]
        ? "$_[1]" cmp "$_[0]"
        : "$_[0]" cmp "$_[1]"
    }
;

########################################################################
# package variables
########################################################################

our $VERSION    = 0.10;

########################################################################
# public interface
########################################################################

sub init_attr
{
    my ( $package, @attrz ) = @_;

    @attrz
    or return;

    # always install @attrz, attributes, and *_offset
    # methods. user can override the set/get methods.

    *{ qualify_to_ref 'attrz', $package } = \@attrz;

    for my $ref ( qualify_to_ref 'attributes', $package )
    {
        undef &{ *$ref };

        *$ref
        = sub
        {
            wantarray
            ?   @attrz
            : [ @attrz ]
        };
    }

    for my $i ( 0 .. $#attrz )
    {
        my $name    = $attrz[$i];
        my $off     = $name . '_offset';

        for my $ref ( qualify_to_ref $off, $package )
        {
            undef &{ *$ref };

            *$ref = sub { $i };
        }

        # caller can override the set/get method.

        for my $ref ( qualify_to_ref $name, $package )
        {
            *{ $ref }{ CODE }
            and next;

            *$ref
            = sub
            {
                @_ > 1
                ? $_[0]->[$i] = $_[1]
                : $_[0]->[$i]
            };
        }
    }

    return
}

sub import
{
    my $caller  = caller;

    unless( $caller->isa( __PACKAGE__ ) )
    {
        my $isa         = *{ qualify_to_ref 'ISA', $caller }{ ARRAY };

        @$isa = ( @$isa, __PACKAGE__ );
    }

    if( @_ > 1 )
    {
        splice @_, 0, 1, $caller;

        &init_attr;
    }

    return
}

sub construct
{
    my $proto   = shift;
    my $class   = blessed $proto
    || do
    {
        my $derived = shift;

        $derived
        ? qualify $derived, $proto
        : $proto
    };

    eval "require $class";

    bless [], $class
}

sub new
{
    my $aobj = &construct;

    $aobj->EVERY::LAST::initialize( @_ );

    $aobj
}

# simplifies testing.

sub initialize {}

# stub simplifies testing.

DESTROY
{
    my $aobj = shift;

    # purge the contents before the object itself.
    # note that this has no effect during global 
    # destruction.

    $#$aobj  = -1;

    return
}

# keep require happy

1

__END__

=head1 NAME

ArrayObj - simple base class for array-based objects.

=head1 SYNOPSIS

    package Mine;

    use parent qw( ArrayObj );

    __PACKAGE__->init_attr( @attribute_names );

    sub initialize
    {
        my $aobj = shift;

        # remainder of stack contains arguments passed
        # to new.
        #
        # deal with them.
        #
        # simplest case: simply store them.

        @$aobj   = @_;

        return
    }

or just

    use ArrayObj @attribute_names;


=head1 DESCRIPTION

This is a fairly generic array-based object.
In fact, aside from blessing an empty arrayref
into the requested class it does nothing.

=head2 Implements new, construct, DESTROY.

New calls construct then EVERY::LAST::initialize.

DESTROY simply empties the object.

=over 4

=item Construct 

There are two ways to use the constructor: to clone a 
type or derive one:

    $object->new( @argz )

will create a new object via blessed $object, where
using a class method allows deriving a type:

    Some::Class->new( Derived => @argz );

Creates a new object with type of Some::Class::MatchingPeaks.

This allows a parent class to contain common methods and 
easily dispatch the initialize to the proper derived class
to populate the object.

=item Initialize

This is stubbed ArrayObj and should be overridden in 
the derived classes.

=back

=head2 Overloads


=over 4

=item bool

The object is true if it is populated:

    scalar @$arrayobj;

=back

Derived classes should implement more specific 
cases.


=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 COPYRIGHT

Copyright (C) 2010, Steven Lembark, all rights reserved.

=head1 LICENSE

This module can be reused under the same terms as 
Perl-5.10 itself.
