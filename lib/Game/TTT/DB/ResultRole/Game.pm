package Game::TTT::DB::ResultRole::Game;

use Moo::Role;
use feature ':5.22';

has '_game_id' => (
  is      => 'rw',
  trigger => \&check_game
);

sub check_game {
  my( $self, $val ) = @_;
  my $game = 
    $self->result_source
         ->schema
         ->resultset( 'Game' )
         ->find( $val );
  die "Given game id, %s, cannot be found"
    if ! defined $game;
  $self->game_id( $game->id );
}

1;

__END__
