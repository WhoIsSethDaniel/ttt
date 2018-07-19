package Game::TTT::DB::ResultSet;

use strict;
use warnings;

use parent qw/ DBIx::Class::ResultSet /;

__PACKAGE__->load_components( qw/ Helper::ResultSet::Me
                                  Helper::ResultSet::IgnoreWantarray  / );

1;

__END__
