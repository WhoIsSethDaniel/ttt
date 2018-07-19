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
  my( $user, $url ) = @_;
  my $req = GET $url, 'Content-Type' => 'application/json';
  $req->authorization_basic( $user, 'password' );
  return $req;
}

{
  my $app  = Game::TTT::Service->to_app;
  my $test = Plack::Test->create($app);

  my $title = 'get users (needs auth header)';

  in_tempdir "$title" => sub {
    my( $cwd ) = @_;

    local $ENV{ GAME_TTT_DB_NAME } = $cwd . '/ttt01.db';

    my $db = fixtures();

    my $res;
    is( 
      exception {
        $res = $test->request( GET '/users' );
      },
      undef,
      "$title: get successful" );

    my $content = from_json $res->content;
    is( 
      $content->{ message },
      "Must have authorization header",
      "$title: must have auth header" );
  };
}

{
  my $app  = Game::TTT::Service->to_app;
  my $test = Plack::Test->create($app);

  my $title = 'get users (ok)';

  in_tempdir "$title" => sub {
    my( $cwd ) = @_;

    local $ENV{ GAME_TTT_DB_NAME } = $cwd . '/ttt02.db';

    my $db = fixtures();

    my $res;
    my $req = make_request( 'bob', '/users' );
    is( 
      exception {
        $res = $test->request( $req )
      },
      undef,
      "$title: get successful" );

    my $content = from_json $res->content;
    cmp_deeply( 
      $content,
      {
        users => [ qw(
          bob
          mary
          steve
        ) ]
      },
      "$title: users looks good" );
  };
}

{
  my $app  = Game::TTT::Service->to_app;
  my $test = Plack::Test->create($app);

  my $title = 'get games (ok)';

  in_tempdir "$title" => sub {
    my( $cwd ) = @_;

    local $ENV{ GAME_TTT_DB_NAME } = $cwd . '/ttt03.db';

    my $db = fixtures();

    my $res;
    my $req = make_request( 'bob', '/games' );
    is( 
      exception {
        $res = $test->request( $req )
      },
      undef,
      "$title: get successful" );

    my $content = from_json $res->content;
    is(
      scalar @{ $content->{ games } },
      2,
      "$title: only see bob's games" );
  };
}

done_testing;
