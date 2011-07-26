########################################################################
# housekeeping
########################################################################

package WCurve::Util::Getopt;

use v5.10;
use strict;
use FindBin::libs;

use Carp;
use File::Basename;
use Getopt::Long;

use Cwd     qw( abs_path );
use Symbol  qw( qualify_to_ref );

use WCurve::Util::DumperConfig;

########################################################################
# package variables
########################################################################

my @std_optz
= qw
(
    input=s
    output=s
    payload=s@

    comp_type=s
    frag_type=s
    score_type=s

    start=i
    stop=i

    verbose+
    debug!

    help|h!
);

my @defaultz = 
(
    verbose => '',
    output  => abs_path "$FindBin::Bin/../tmp",
);

########################################################################
# process command line
########################################################################

sub import
{
    my $caller  = caller;
    my $name    = $_[1] || 'get_options';

    my $ref     = qualify_to_ref $name, $caller;

    undef &{ *$ref };

    *$ref       = __PACKAGE__->can( 'get_options' );

    return
}

sub get_options
{
    my ( $user_optz, $user_defz ) = @_;

    $_ ||= [] for $user_optz, $user_defz;

    my %cmdline = ();

    if( GetOptions \%cmdline, @$user_optz, @std_optz )
    {
        if( $cmdline{ help } )
        {
            if( my $handler = (caller)->can( 'help' ) )
            {
                $handler->( \%cmdline );
            }
            else
            {
                print 
                "\nCommand line options:\n",
                Dumper [ @$user_optz, @std_optz ];
            }

            exit 1;
        }
    }
    else
    {
        print STDERR "Valid Options:\n", Dumper [ @$user_optz, @std_optz ];

        exit 2;
    }

    my %defz    = ( @defaultz, @$user_defz );

    $cmdline{ $_ } //= $defz{ $_ }
    for keys %defz;

    $cmdline{ base } = basename $0;
    $cmdline{ Bin  } = $FindBin::Bin;

    $cmdline{ payload }
    = do
    {
        my %p
        = map
        {
            split /=/, $_, 2 
        } @{ $cmdline{ payload } };

        \%p
    };

    wantarray
    ? %cmdline
    : \%cmdline
}

# keep require happy

42

__END__
