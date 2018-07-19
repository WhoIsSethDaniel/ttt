package Game::TTT::Client::LeaveGame;

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
  [ 'game=i', 'game id to play on', { required => 1 } ],
  [ 'verbose|v', 'show full response' ],
  [ 'help|h', 'show help' ]
);

print($usage->text), exit if $opt->help;

sub run {

  my $ua = LWP::UserAgent->new;

  my $url = sprintf "http://%s:%d/games/%d/status/abandoned", $opt->host, $opt->port, $opt->game;
  my $req = PUT $url, 'Content-Type' => 'application/json';
  $req->authorization_basic( $opt->user, 'fake' );
  my $resp = $ua->request( $req );
  if( exists $resp->{ message } ) {
    die $resp->{ message } . "\n";
  } 

  my $deserial = decode_json $resp->content;
  if( $deserial->{ message } ) {
    say $deserial->{ message };
  }

  say Dumper( $deserial ) if $opt->verbose;
}

1;

__END__
