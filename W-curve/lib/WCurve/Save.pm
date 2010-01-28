########################################################################
# housekeeping
########################################################################

package WCurve::Save;

use v5.10;
use strict;

use IO::File;

use Exporter::Proxy qw( dispatch=save );

use Data::Dumper;
use Storable        qw( store_fd );

########################################################################
# package variables
########################################################################

########################################################################
# utility subs
########################################################################

sub storable
{
    my ( $wc, $path ) = @_;

    my $fh 
    = '-' eq $path
    ? *STDOUT{ IO }
    : $path =~ /[.]gz$/
    ? IO::File->new( "| gzip -9 > $path" )
    : IO::File->new( "> $path" )
    ;

    store_fd $wc, $fh;

    return
}

sub dumper
{
    my ( $wc, $path ) = @_;

    my $fh 
    = '-' eq $path
    ? *STDOUT{ IO }
    : $path =~ /[.]gz$/
    ? IO::File->new( "| gzip -9 > $path" )
    : IO::File->new( "> $path" )
    ;

    local $Data::Dumper::Purity           = 1;
    local $Data::Dumper::Terse            = 1;
    local $Data::Dumper::Indent           = 1;
    local $Data::Dumper::Deepcopy         = 0;
    local $Data::Dumper::Quotekeys        = 0;

    $fh->printflush
    (
        "\n# $wc\n",

        Dumper $wc
    );

    return
}

sub restore
{
    my ( undef, $path ) = @_;

    -e $path    or die "Bogus restore: non-existant '$path'";
    -r _        or die "Bogus restore: non-readable '$path'";

    my $buffer
    = do
    {
        my $fh
        = $path =~ /[.]gz$/
        ? IO::File->new( "gzip -dc $path |" )
        : IO::File->new( "< $path" )
        ;

        local $/;

        <$fh>
    };

    Storable::file_magic $buffer
    ? thaw $buffer
    : eval "$buffer"
}

########################################################################
# public interface
########################################################################

# keep require happy

1

__END__
