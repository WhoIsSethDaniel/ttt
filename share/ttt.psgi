use Dancer2;
# 'set serializer' is here because if it comes much (any?) later it, at least 
# partially, gets wiped out and body_parameters will not work as expected.
set serializer => 'JSON';
set logger => 'console';
use Game::TTT::Service;
use Plack::Builder;

dance();
