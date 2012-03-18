########################################################################
# housekeeping
########################################################################

package WCurve::Web;

use v5.12;
use FindBin::libs;
use autodie qw( open close );

use File::Basename;
use Plack::Runner;

use File::Temp  qw( tempfile tempdir    );
use Symbol      qw( qualify_to_ref      );
use URI::Encode qw( uri_decode          );

use WCurve;

########################################################################
# package variables
########################################################################

my $verbose = $ENV{ VERBOSE } || $^P || '';

my $wc      = WCurve->new( qw( FloatCyl factory_object ) );

my $json_tmp
= do
{
    my $tmp = 'w-curve-tmp';
    my $pub = "public/$tmp";

    -e $pub || mkdir $pub or die "'$pub', $!";

    -r $pub or die "Non-readable: '$pub'";
    -w _    or die "Non-writeable: '$pub'";
    -x _    or die "Non-executable: '$pub'";

    "$pub/json.XXXXXX"
};

print STDERR "JSON tmpfile: '$json_tmp'\n";

my %content_hdrz
= qw
(
    text    text/plain
    html    text/html
    css     text/css
    xml     text/xml

    json    application/json
    js      application/javascript

    png     image/png
);

my $image_root  = 'public/images';
my $fixed_root  = 'public/lib';

my @fixed_pathz =
(
    [
        wcurve  =>
        
        [ qw( js    /wcurve     W-Curve.js  ) ],
    ],

    [
        curview =>

        [ qw( html  /           curview.html                            ) ],
        [ qw( js    /glge       glge-compiled-min.js                    ) ],
        [ qw( css   /css        jquery_ui/jquery-ui-1.8.13.custom.css   ) ],
        [ qw( xml   /curview    curview.xml                             ) ],
    ],

    [
        'curview/jquery_ui' =>

        [ qw( js    /jquery_ui/js/jquery-1.5.1.min.js               jquery-1.5.1.min.js             ) ],
        [ qw( js    /jquery_ui/js/jquery-ui-1.8.13.custom.min.js    jquery-ui-1.8.13.custom.min.js  ) ],
    ],
);

my %content_cache   = ();

########################################################################
# utility subs
########################################################################

sub cache_entry
{
    my ( $type, $path ) = @_;

    -e $path    or die "Non-existant fixed path: $path";
    -r _        or die "Non-readable fixed path: $path";

    my $content
    = do
    {
        local $/;

        open my $fh, '<', $path;

        readline $fh
    };

    # this obviously needs more logic...

    [
        200,
        $content_hdrz{ $type },
        [ $content ]
    ]
}

########################################################################
# prepare the fixed-path cache
########################################################################

$_  = [ 'Content-Type' => $_ ]
for values %content_hdrz;

for( @fixed_pathz )
{
    my ( $subdir, @pathz ) = @$_;

    my $libdir  = "$fixed_root/$subdir";

    for( @pathz )
    {
        my ( $type, $uri, $base ) = @$_;

        my $path    = "$libdir/$base";

        print STDOUT "Cache: '$uri' -> '$path'\n";

        my $content = cache_entry $type => $path;

        $content_cache{ "$uri" } = cache_entry $type => $path;
    }
}

########################################################################
# handler handed back to plack
########################################################################

my $server
= sub
{
$DB::single = 1;

    my $env = shift;

    my $headerz = '';
    my $content = '';

    given( $env->{ PATH_INFO } )
    {
        when( %content_cache )
        {
            print STDERR "Cache hit: $_\n"
            if $verbose;

            return $content_cache{ $_ }
        }

        my $dir = dirname $_;

        when( $dir eq '/images' )
        {
            return $content_cache{ $_ }
            ||= cache_entry png => "./public/$_";
        }

# Q: Where is post data accessable?

$DB::single = 1;

        when( exists $env->{ fasta } )
        {
            return
            [
                200,
                $content_hdrz{ js },
                $wc->read_seq( $env->{ fasta } )->curview
            ]
        }

        print STDERR "Unhandled path: '$_'"
        if $verbose;

$DB::single = 1;

        return [ 200, [], [''] ];
    }
};

if( caller )
{
    # plackup, twiggy, etc.

    $server
}
else
{
    # standalone application

    require Plack::Runner;

    my $runner = Plack::Runner->new;

    $runner->parse_options( @ARGV );

    $runner->run( $server );
}

__END__

Example request: http://localhost:5000/

  DB<1> x $env
0  HASH(0x1d28d58)
   'HTTP_ACCEPT' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
   'HTTP_ACCEPT_CHARSET' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7'
   'HTTP_ACCEPT_ENCODING' => 'gzip, deflate'
   'HTTP_ACCEPT_LANGUAGE' => 'en-us,en;q=0.5'
   'HTTP_HOST' => 'localhost:5000'
   'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64; rv:5.0) Gecko/20100101 Firefox/5.0'
   'PATH_INFO' => '/'
   'QUERY_STRING' => ''
   'REMOTE_ADDR' => '127.0.0.1'
   'REQUEST_METHOD' => 'GET'
   'REQUEST_URI' => '/'
   'SCRIPT_NAME' => ''
   'SERVER_NAME' => 0
   'SERVER_PORT' => 5000
   'SERVER_PROTOCOL' => 'HTTP/1.1'
   'psgi.errors' => *main::STDERR
   'psgi.input' => GLOB(0x2252920)
      -> *HTTP::Server::PSGI::$input
            FileHandle({*HTTP::Server::PSGI::$input}) => fileno(-1)
   'psgi.multiprocess' => ''
   'psgi.multithread' => ''
   'psgi.nonblocking' => ''
   'psgi.run_once' => ''
   'psgi.streaming' => 1
   'psgi.url_scheme' => 'http'
   'psgi.version' => ARRAY(0x1cb8398)
      0  1
      1  1
   'psgix.input.buffered' => 1
   'psgix.io' => IO::Socket::INET=GLOB(0x1821aa0)
      -> *Symbol::GEN1
            FileHandle({*Symbol::GEN1}) => fileno(8)

public/lib curview/curview.html
public/lib curview/curview.xml
public/lib curview/glge-compiled-min.js
public/lib curview/jquery_ui/jquery-1.5.1.min.js
public/lib curview/jquery_ui/jquery-ui-1.8.13.custom.css
public/lib curview/jquery_ui/jquery-ui-1.8.13.custom.min.js
public/lib wcurve/W-Curve.js
public/lib wcurve/curview.html
