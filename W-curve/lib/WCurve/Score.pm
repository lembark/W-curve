########################################################################
# housekeeping
########################################################################

package WCurve::Score;

use Scalar::Util    qw( blessed );

use Exporter::Proxy qw( dispatch=score );

use WCurve::Score::Display;
use WCurve::Score::SingleValue;

# keep require happy

1

__END__
