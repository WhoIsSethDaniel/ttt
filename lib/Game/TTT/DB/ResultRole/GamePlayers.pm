package Game::TTT::DB::ResultRole::GamePlayers;

use Moo::Role;
use feature ':5.22';

has '_player1' => (
  is      => 'rw',
  trigger => \&check_player1
);

has '_player2' => (
  is      => 'rw',
  trigger => \&check_player2
);

sub _check_player {
  my( $self, $val ) = @_;

  my $user = 
    $self->result_source
         ->schema
         ->resultset( 'User' )
         ->find( { name => $val } );

  die sprintf( "Given user '%s' does not exist\n", $val )
    if ! defined $user;

  return $user;
}

sub check_player1 {
  my( $self, $val ) = @_;
  my $user = $self->_check_player($val);
  $self->p1( $user->id );
  $self->turn( $user->name );  # p1 is always first
}

sub check_player2 {
  my( $self, $val ) = @_;
  my $user = $self->_check_player($val);
  $self->p2( $user->id );
}

1;

__END__
