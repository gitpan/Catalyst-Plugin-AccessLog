package MockUser;
our $VERSION = '1.01';

use Moose;

has 'id' => ( is => 'rw' );

no Moose;
1;
