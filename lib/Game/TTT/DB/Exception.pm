package Game::TTT::DB::Exception;

use strict;
use warnings;
use feature ':5.20';

use overload
    '""' => sub { shift->{message} },
    fallback => 1;

sub throw { 
  my( $class, $msg ) = @_;
  $msg =~ s/at \/.*$//;
  die bless { message => $msg }, $class;
}

1;

__END__
