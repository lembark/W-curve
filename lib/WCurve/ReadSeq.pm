########################################################################
# housekeeping
########################################################################
package WCurve::ReadSeq;

use v5.10;
use strict;

use Carp;
use File::Basename;
use IO::File;
use IO::String;

use Exporter::Proxy qw( read_seq read_template );
use Scalar::Util    qw( blessed );

use WCurve::Values  qw( cornerz );

########################################################################
# package variables
########################################################################

our $VERSION    = 0.01;

my $generic_filter  = qr{.};

my $bogus
= do
{
    my $v   = join '', sort keys %cornerz;


    qr{([^$v])}x
};

my %handlerz = 
(
    '>' => __PACKAGE__->can( 'fasta'    ),
    '@' => __PACKAGE__->can( 'fastq'    ),
    '%' => __PACKAGE__->can( 'template' ),
);

my $input_rx
= do
{
    my @sigilz  = map { quotemeta } keys %handlerz;

    local $" = '';

    qr{^ \s* [@sigilz] .+ \n .+ }x
};

########################################################################
# utility subs
########################################################################

my $partition
= sub
{
    my ( $wc, $seq, $template ) = @_;

    my $class   = $wc->type;

    $seq    =~ s{ \W+ }{}gx;
    $seq    =~ s{ [^catgCATG] }{n}xg;

    map
    {
        $_->[-1]
    }
    sort
    {
        $a->[0] <=> $b->[0]
        or 
        $a->[1] <=> $b->[1]
    }
    map
    {
        my ( $name, $start, $stop ) = split;

        my $size    = $stop - $start + 1;

        my $sigil   = substr $name, 0, 1;

        if( $sigil eq '-' )
        {
            ()
        }
        else
        {
            my $frag
            = WCurve::Fragment->new
            (
                $class,
                $seq,
                $name,
                $start,
                $stop
            );

            $frag->filler( 1 )
            if $sigil eq '+';

            [ $start, $stop, $frag ]
        }
    }
    split /\s* ; \s*/x, $template
};

########################################################################
# region spec (internal format)
# %
# identifier ; region name begin end ; region name begin end ...
# identifeir sequence
# \n\n

sub template
{
    my ( $wc, $input ) = @_;

    my $override    = $wc->payload->{ template } || '';

    $input  =~ s{ \# .+ $ }{}xgm;

    my ( $head, $seq ) = split /\n+/, $input, 2;

    my ( $id )  = $head =~ m{ (\S+) }x
    or die "Bogus fragment: no id in '$input'";

    my $i           = rindex $seq, ';';
    my $template    = substr $seq, 0, $i, ''
    if $i > 0;

    $seq =~ s{^ \W+ }{}x;

    $template       = $override
    if $override;

    print STDERR "Template:\n'$id' ($head)\n$template\n"
    if $wc->verbose;

    my @fragz   = $wc->$partition( $seq, $template );

    [ $id => \@fragz, $head, $seq ]
}

########################################################################
# > identifier
# sequence ...

sub fasta
{
    my ( $wc, $input ) = @_;

    my $class       = $wc->type;

    my ( $head, $seq ) = split /\n/, $input, 2;

    print STDERR "Fasta: $head\n"
    if $wc->verbose;

    my ( $id )  = $head =~ m{ (\S+) }x
    or die "Bogus $class fragment: no id in '$input'";

    if( my $template = $wc->payload->{ template } || '' )
    {
        $wc->$partition( $seq, $template )
    }
    else
    {
        [
            $id =>
            [ WCurve::Fragment->new ( $class, $seq, $id ) ],
            $head,
            $seq
        ]
    }
}

########################################################################
# @ident
# sequence ...
# +
# Phreds ...
# @ident

sub fastq
{
##    print STDERR "Reading: fastq\n";
##
##    my ( $proto, $fh ) = splice @_, 0, 2;
##
##    my @fragz   = ();
##
##    while( <$fh> )
##    {
##        chomp;
##
##        # grab the remaining blocks and split them 
##        # into identifier + sequence.
##        #
##        # ignore the phred scores for now.
##
##        my ( $a, $phred ) = split /^ [+] $/, $_, 2;
##
##        my ( $id, $seq ) = split /\n/, $a, 2;
##
##        if( @_ )
##        {
##            my $acc
##            = do
##            {
##                my $i   = index $id, ' ';
##
##                $i
##                ? substr $id, 0, $i
##                : $id
##            };
##
##            $acc ~~ @_
##            or next;
##
##            print STDERR "\t$id ($acc)\n";
##        }
##        else
##        {
##            print STDERR "\t$id\n";
##        }
##
##        print STDERR "\t$id\n";
##
##        push @cfrag, $proto->new( $seq, $id );
##    }
}

sub read_input
{
    my $input   = '';
    my $fh      = '';

    given( $_[0] )
    {
        when( blessed $_ )
        {
            $fh = $_
        }

        when( '-' )
        {
            $fh = *STDIN{ IO }
        }

        when( m{^ $input_rx }xo )
        {
            s{^ \s+ }{}x;

            $input  = $_;
        }

        when( -e )
        {
            -r _    or croak "Bogus read_seq: non-readable '$_'";
            -s _    or croak "Bogus read_seq: empty '$_'";

            $fh
            = m{ [.]gz $ }x
            ? IO::File->new( "gzip -dc < $_ |" )
            : IO::File->new( "< $_" )
        }

        croak "Unable to process input:\n" . $_;
    }

    $input  ||= do { local $/; <$fh> };

    my @chunkz
    = split /^ ( [%@>] ) \s* /xm, $input;

    shift @chunkz if @chunkz % 2;

    map
    {
        [ splice @chunkz, 0, 2 ]
    }
    ( 1 .. @chunkz/2 )
}

sub construct_fragments
{
    my ( $wc, $input ) = @_;

    my $handler = $handlerz{ $_->[0] }
    or croak "Bogus select_handler: unknown '$_->[0]'";

    $handler->( $wc, $_->[1] )
}

########################################################################
# public interface
########################################################################

sub read_seq
{
    my $proto   = shift;

    my $wc  
    = blessed $proto 
    ? $proto 
    : $proto->new
    ;

    @_ or @ARGV
    or confess "Bogus read_seq: no inputs on stack or program args";

    my @fragz
    = map
    {
        construct_fragments $wc, $_
    }
    map
    {
        read_input $_
    }
    @_ ? @_ : @ARGV;

    given( wantarray )
    {
        when( 1 )
        {
            # single wc for each of the definitions.

            return map
            {
                my ( $name, $fragz, $head, $seq ) = @$_;

                my $new = $wc->new( $name => $fragz );

                $new->description( $head );
                $new->sequence   ( lc $seq  );

                $new
            }
            @fragz
        }

        # no way to define a sequence if there is more
        # than one set of fragments in the input. in that
        # case dodge the sequence input and use the 
        # catenated ids.

        my ( $id, $desc, $seq )
        = do
        {
            if( @fragz > 1 )
            {
                (
                    (   join ' ', map { $_->[0] } @fragz ),
                    '',
                    ''
                )
            }
            else
            {
                (
                    @{ $fragz[0] }[0, 2, 3 ]
                )
            }
        };

        @fragz  = map { @{ $_->[1] } } @fragz;

        when( '' )
        {
            # single wc for all of the fragments.
            # this ignores the sequence if there 
            # is more than one definition.

            my $name    = $wc->name || $id;

            my $new     = $wc->new( $name => @fragz );

            $new->description( $desc    );
            $new->sequence   ( lc $seq  );

            return $new
        }

        when( undef )
        {
            # update the current wc with the fragments.

            $wc->fragments  ( \@fragz   );
            $wc->description( $desc     );
            $wc->sequence   ( lc $seq   );

            return $wc
        }
    }
}

########################################################################
# read a template and insert it into the wcurve object.

sub read_template
{
    my ( $wc, $path ) = @_;

    -e $path    or die "Bogus $0: non-existant template ($path)";
    -r _        or die "Bogus $0: non-readable template ($path)";
    -s _        or die "Bogus $0: empty template ($path)";

    my $tmpl
    = do
    {
        open my $fh, '<', $path
        or die "< $path, $!";

        local $/;

        <$fh>
    }
    or die "Roadkill: $path, $!";

    $tmpl   =~ s{ \# .* $ }{}xgm;

    $wc->payload->{ template } = $tmpl;

    $wc
}

# keep require happy

1

__END__
