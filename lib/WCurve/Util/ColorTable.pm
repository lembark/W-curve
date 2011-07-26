########################################################################
# housekeeping
########################################################################

package WCurve::Util::ColorTable;

use v5.12;

use Graphics::ColorUtils;

use List::Util  qw( first );

use WCurve::Values qw( PI two_pi );

use Exporter::Proxy
qw
(
    websafe_hex
    websafe_rgb
    radian2rgb
    cyl2rgb
);

########################################################################
# package variables
########################################################################

my @colorz = ();

########################################################################
# utility subs
########################################################################

sub extract_rgb
{
    my $color   = shift;

    my @rgb = 
    ( 
        ( ( $color & 0xFF0000 ) >> 16 ),
        ( ( $color & 0x00FF00 ) >>  8 ),
        ( ( $color & 0x0000FF ) >>  0 ),
    );

    wantarray
    ?  @rgb
    : \@rgb
}

########################################################################
# exported interface
########################################################################

sub initialize_palette
{
    my $count   = shift || 16;

    my $delta   = 360 / $count;

    @colorz
    = map 
    {
        [ hsv2rgb $delta * $_, 1, 1 ]
    }
    ( 0 .. $count );

    scalar @colorz
}

sub websafe_hex
{
    ...
}

sub websafe_rgb
{
    ...
}

sub radian2rgb
{
    my $radians = shift;

    my $hue = 360 * ( ( $PI + $radians ) / $two_pi );

    my @rgb = hsv2rgb $hue, 1, 0.75;

    wantarray
    ?  @rgb
    : \@rgb
}

sub cyl2rgb
{
    my ( $r, $a ) = @_;

    my $sat = 1;
    my $val = $r;
    my $hue = int ( 360 * ( ( $PI + $a ) / $two_pi ) );

    my @rgb = hsv2rgb $hue, $sat, $val;

    wantarray
    ?  @rgb
    : \@rgb
}

initialize_palette;

__END__

=head1 NAME

WCurve::Util::ColorTable -- find approximate color table 
using hex color values.

=head1 SYNOPSIS

    use WCurve::Util::ColorTable;

    my $hex_color   = ...;

    # this will return an integer in hex format suitable
    # for use with an integer-driven color table of RGB.

    my $web_color   = websafe_hex $hex_color;
    my $web_color   = websafe_hex $hex_color;

    # angle from 0 .. 2 * PI.

    my ( $r, $g, $b ) = radian2rgb $angle_in_radians;

=head1 DESCRIPTION

Values taken from:

    http://immigration-usa.com/html_colors.html
