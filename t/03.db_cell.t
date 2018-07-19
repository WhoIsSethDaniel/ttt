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

  # make a game
  my $game = $db->resultset( 'Game' )->new_result( {} );
  $game->_player1( 'bob' );
  $game->_player2( 'mary' );
  $game->p1tok( 'o' );
  $game->p2tok( 'x' );
  $game->insert;

  return $db;
}

{
  in_tempdir "cell 'value' field validation" => sub {
    my( $cwd ) = @_;

    my $title = 'cell validation';

    local $ENV{ GAME_TTT_DB_NAME } = $cwd . '/ttt01.db';

    my $db = fixtures();

    # find any cell
    my $cell = $db->resultset( 'Cell' )->find(1);

    is( 
      $cell->value,
      undef,
      "$title: cell value is undefined" );

    like( 
      exception { 
        $cell->make_column_dirty( 'value' );
        $cell->update;
      },
      qr/field 'value' must be present and non-null/,
      "$title: exception: cell value is NULL" );

    like( 
      exception { 
        $cell->update( { value => 'z' } );
      },
      qr/field 'value' must be either 'x' or 'o'/,
      "$title: exception: cell value is not x or o" );

    is(
      exception { 
        $cell->update( { value => 'x' } );
      },
      undef,
      "$title: cell value ok" );
  };
}

done_testing;
