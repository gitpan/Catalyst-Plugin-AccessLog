package MockUser;
our $VERSION = '1.00';


use Moose;

has 'id' => ( is => 'rw' );

no Moose;
1;
