########################################################################
# housekeeping
########################################################################
package WCurve::ReadSeq;

use v5.10;
use strict;

use Carp;
use IO::File;

use Exporter::Proxy qw( read_seq );

########################################################################
# package variables
########################################################################

my $generic_filter  = qr{.};


########################################################################
# utility subs
########################################################################

########################################################################
# > identifier
# sequence ...

sub fasta
{
    print STDERR "Reading: fasta\n";

    my ( $proto, $fh ) = splice @_, 0, 2;

    # filters are on the stack.

    my @curvz   = ();

    my $filter
    = @_
    ? do{ $a = join '|', @_; qr{^(?:$a) \b}xo }
    : $generic_filter
    ;

    my $id  = '';

    while( <$fh> )
    {
        chomp;

        $_ ~~ $filter
        or next;

        # grab the remaining blocks and split them 
        # into identifier + sequence.
        #
        # logic discards initial runt read before 
        # the fisrt '>'.

        my ( $head, $seq ) = split /\n/, $_, 2;

        my ( $acc ) = $head =~ m{ (\w+) }x;

        $seq    =~ s{ \W+ }{}xg;

        if( my @junk = $seq =~ m{ [^catgCATG] }x )
        {
            print STDERR "Skip: $id", "Junk in sequence: @junk";

            next;
        };

        print STDERR $head, "\n";

        push @curvz, $proto->new( $seq, $acc );
    }

    wantarray
    ?  @curvz
    : \@curvz
}

########################################################################
# @ident
# sequence ...
# +
# Phreds ...
# @ident

sub fastq
{
    print STDERR "Reading: fastq\n";

    my ( $proto, $fh ) = splice @_, 0, 2;

    my @curvz   = ();

    while( <$fh> )
    {
        chomp;

        # grab the remaining blocks and split them 
        # into identifier + sequence.
        #
        # ignore the phred scores for now.

        my ( $a, $phred ) = split /^ [+] $/, $_, 2;

        my ( $id, $seq ) = split /\n/, $a, 2;

        if( @_ )
        {
            my $acc
            = do
            {
                my $i   = index $id, ' ';

                $i
                ? substr $id, 0, $i
                : $id
            };

            $acc ~~ @_
            or next;

            print STDERR "\t$id ($acc)\n";
        }
        else
        {
            print STDERR "\t$id\n";
        }

        print STDERR "\t$id\n";

        push @curvz, $proto->generate( $seq, $id );
    };

    wantarray
    ?  @curvz
    : \@curvz
}


########################################################################
# public interface
########################################################################

sub read_seq
{
    state $handlerz = 
    {
        '>' => __PACKAGE__->can( 'fasta' ),
        '@' => __PACKAGE__->can( 'fastq' ),
    };

    local $/    = '';

    my ( $proto, $path ) = @_;

    my $fh
    = do
    {
        if( $path eq '-' )
        {
            *STDIN{ IO }
        }
        else
        {
            print STDERR "\nSequence from: '$path'\n";


            $path       or croak 'Bogus read_seq: false path';
            -e $path    or croak 'Bogus read_seq: non-existant path';
            -r _        or croak 'Bogus read_seq: non-readable path';
            -s _        or croak 'Bogus read_seq: empty path';

            $path =~ m{ [.]gz $ }x
            ? IO::File->new( "gzip -dc < $path |" )
            : IO::File->new( "< $path" )
        }
    };

    read $fh, $/, 1
    or croak "Bogus read_seq: failed read '$/', $!";

    print STDERR "Magic character: '$/'\n";

    my $handler = $handlerz->{ $/ }
    or croak "Bogus input: '$path' starts with '$/'";

    splice @_, 1, 1, $fh;

    print STDERR join "\n\t", 'Sequences:', @_[2..$#_], ''
    if @_ > 2;

    &$handler
}

# keep require happy

1

__END__
