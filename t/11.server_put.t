use strict;
use warnings;
use feature ':5.20';

use Test::More;
use Test::Fatal;
use Plack::Test;
use Test::TempDir::Tiny;
use Test::Deep;

use Game::TTT::Service;
use Game::TTT::Schema;

use JSON;
use HTTP::Request::Common;

delete $ENV{ GAME_TTT_DB_NAME };

sub add_game {
  my( $db, $n1, $n2 ) = @_;
  my $g = $db->resultset( 'Game' )->new_result( {} );
  $g->_player1( $n1 );
  $g->_player2( $n2 );
  $g->p1tok( 'o' );
  $g->p2tok( 'x' );
  $g->insert;
}

sub fixtures {
  my $db = Game::TTT::Schema->connect;

  is( 
    exception { $db->deploy },
    undef,
    "deployed ok" );

  # create some users
  foreach my $user (qw( bob mary steve ) ) {
    $db->resultset( 'User' )
       ->create( { name => $user } );
  }

  add_game( $db, 'bob',  'mary'  );
  add_game( $db, 'bob',  'steve' );
  add_game( $db, 'mary', 'steve' );

  return $db;
}

sub make_request {
  my( $user, $meth, $url ) = @_;
  no strict 'refs';
  my $req = $meth->($url, 'Content-Type' => 'application/json');
  $req->authorization_basic( $user, 'password' );
  return $req;
}

{
  my $app  = Game::TTT::Service->to_app;
  my $test = Plack::Test->create($app);

  my $title = 'change game status (bad status)';

  in_tempdir "$title" => sub {
    my( $cwd ) = @_;

    local $ENV{ GAME_TTT_DB_NAME } = $cwd . '/ttt01.db';

    my $db = fixtures();

    my $put_res;
    my $put = make_request( 'bob', 'PUT', '/games/1/status/badbadbad' );
    is( 
      exception {
        $put_res = $test->request( $put )
      },
      undef,
      "$title: request ok" );

    my $put_content = from_json $put_res->content;
    cmp_deeply( 
      $put_content->{ message },
      "A user may only change game status to abandoned",
      "$title: status changed" );


  };
}

{
  my $app  = Game::TTT::Service->to_app;
  my $test = Plack::Test->create($app);

  my $title = 'change game status (ok)';

  in_tempdir "$title" => sub {
    my( $cwd ) = @_;

    local $ENV{ GAME_TTT_DB_NAME } = $cwd . '/ttt02.db';

    my $db = fixtures();

    my $game = 
      $db->resultset( 'Game' )
         ->find(1);

    is(
      $game->status,
      'inprogress',
      "$title: game is inprogress" );

    my $put_res;
    my $put = make_request( 'bob', 'PUT', '/games/1/status/abandoned' );
    is( 
      exception {
        $put_res = $test->request( $put )
      },
      undef,
      "$title: change successful" );

    my $put_content = from_json $put_res->content;
    cmp_deeply( 
      $put_content->{ message },
      "game status changed",
      "$title: status changed" );

    $game->discard_changes;

    is(
      $game->status,
      'abandoned',
      "$title: game is inprogress" );
  };
}

done_testing;
