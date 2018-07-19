package Game::TTT::Client::CreateGame;

use strict;
use warnings;
use feature ':5.20';

use Data::Dumper::Concise;
use Getopt::Long::Descriptive;

use JSON;
# these days there are better agents, but this one is very common
use HTTP::Request::Common;
use LWP::UserAgent;

my( $opt, $usage ) = describe_options(
  'ttt-game-create %o',
  [ 'host=s', 'the server to connect to', { default => 'localhost' } ],
  [ 'port|p=i', 'the port to connect to', { default => 5000 } ],
  [ 'user|u=s', 'user to connect as', { required => 1 } ],
  [ 'width=i', 'the width of the board (optional)' ],
  [ 'p1=s', 'name of player 1', { required => 1 } ],
  [ 'p2=s', 'name of player 2', { required => 1 } ],
  [ 'token1=s', 'token for player 1', { required => 1 } ],
  [ 'token2=s', 'token for player 2', { required => 1 } ],
  [ 'verbose|v', 'show full response' ],
  [ 'help|h', 'show help' ]
);

print($usage->text), exit if $opt->help;

sub run {

  my $ua = LWP::UserAgent->new;

  my $json = encode_json {
      $opt->width ? ( width => $opt->width ) : (),
      player1 => $opt->p1,
      player2 => $opt->p2,
      player1_token => $opt->token1,
      player2_token => $opt->token2,
    };

  my $url = sprintf "http://%s:%d/games", $opt->host, $opt->port;
  my $req = POST $url, 'Content-Type' => 'application/json', Content => $json;
  $req->authorization_basic( $opt->user, 'fake' );
  my $resp = $ua->request( $req );
  if( exists $resp->{ message } ) {
    die $resp->{ message } . "\n";
  } 

  my $deserial = decode_json $resp->content;
  if( $deserial->{ created } ) {
    say "Created game: " . $deserial->{ id }; 
  } elsif( exists $deserial->{ message } ) { 
    say $deserial->{ message };
  }

  say Dumper( $deserial ) if $opt->verbose;
}

1;

__END__
