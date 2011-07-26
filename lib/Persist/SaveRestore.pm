########################################################################
# housekeeping
########################################################################

package WCurve::SaveRestore;

use v5.10;
use strict;

use Carp;
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

    $path   //= "$wc.dump.gz";

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
    local $Data::Dumper::Deepcopy         = 1;
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

    # validate 

    -e $path    or croak "Bogus restore: non-existant '$path'";
    -r _        or croak "Bogus restore: non-readable '$path'";

    # these are all small enough to slurp, and eval, that
    # both require the entire content anyway.

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

    # note: pre-reading the content avoids issues with
    # file_magic croaking if the file is unreadable.

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

=head1 NAME

WCurve::Persist - Storable or Dumper persistence for WCurves.

=head1 SYNOPSIS

    my $wc0 = WCurve->new( $format => $dna, $name );

    $wc0->save( storable => $path ); # fast, compact
    $wc0->save( dumper   => $path ); # mainly useful for viewing

    my $wc1 = WCurve->new;

    $wc1->restore( $path );

=head1 DESCRIPTION

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

=head1 COPYRIGHT

Copyright (C) 2009-2010, Steven Lembark. All rights reserved.

=head1 LICENSE

This code can be used and re-distributed under the
same terms as Perl-5.10.1 itself.

