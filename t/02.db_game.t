use strict;
use warnings;
use feature ':5.20';

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;

use Game::TTT::Schema;

my $class = 'Game::TTT::DB::Result::Game';

# Test::DBIx::Class would be better, but takes more effort to setup. 

delete $ENV{ GAME_TTT_DB_NAME };

sub fixtures {
  my $db = Game::TTT::Schema->connect;

  is( 
    exception { $db->deploy },
    undef,
    "deployed ok" );

  # create some users
  foreach my $user (qw( bob mary ) ) {
    $db->resultset( 'User' )
       ->create( { name => $user } );
  }

  return $db;
}

{
  in_tempdir "check user validation" => sub {
    my( $cwd ) = @_;

    local $ENV{ GAME_TTT_DB_NAME } = $cwd . '/ttt01.db';

    my $db = fixtures();

    like( 
      exception { 
        my $g = $db->resultset( 'Game' )->new_result( {} );
        $g->_player1( 'bob' );
        $g->_player2( 'mary' );
        $g->p1tok( 'q' );
        $g->p2tok( 'x' );
        $g->insert;
      },
      qr/player tokens must be either 'x' or 'o'/,
      "exception: bad player token" );

    like( 
      exception { 
        my $g = $db->resultset( 'Game' )->new_result( {} );
        $g->_player1( 'bob' );
        $g->p1tok( 'o' );
        $g->p2tok( 'x' );
        $g->insert;
      },
      qr/Required field 'p2' is not specified/,
      "exception: player not specified" );
  };
}

{
  in_tempdir "check user validation" => sub {
    my( $cwd ) = @_;

    local $ENV{ GAME_TTT_DB_NAME } = $cwd . '/ttt01.db';

    my $db = fixtures();

    my $game;
    is( 
      exception { 
        $game = $db->resultset( 'Game' )->new_result( {} );
        $game->_player1( 'bob' );
        $game->_player2( 'mary' );
        $game->p1tok( 'o' );
        $game->p2tok( 'x' );
        $game->insert;
      },
      undef,
      "game created" );

    $game->discard_changes;
    
    is( 
      $game->status,
      'inprogress',
      "status is as expected" );

    is(
      exception {
        $game->update( { status => 'abandoned' } )
      },
      undef,
      "changed status to abandoned" );

    $game->discard_changes;

    like(
      exception {
        $game->update( { status => 'inprogress' } )
      },
      qr/Cannot change the status of a game no longer in progress/,
      "cannot change status from non-inprogress" );
  };
}

done_testing;
