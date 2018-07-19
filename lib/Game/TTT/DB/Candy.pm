package Game::TTT::DB::Candy;

use strict;
use warnings;
use parent 'DBIx::Class::Candy';

sub base { 'Game::TTT::DB::Result' }
sub autotable { 0 }

1;

__END__
