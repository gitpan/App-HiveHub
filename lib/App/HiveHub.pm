package App::HiveHub;
BEGIN {
  $App::HiveHub::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Implementation of Hive Hub for gathering from the hive drones [IN DEVELOPMENT]
$App::HiveHub::VERSION = '0.001';
our $VERSION ||= '0.000';

use MooX qw(
  Options
);

use Path::Tiny;
use PocketIO;
use Plack::Builder;
use Twiggy::Server;
use AnyEvent;
use AnyEvent::SerialPort;
use AnyEvent::HiveJSO;
use AnyEvent::HTTP;
use File::ShareDir::ProjectDistDir;
use JSON::MaybeXS;
use DateTime;
use DDP;

option 'port' => (
  is => 'ro',
  format => 'i',
  default => '8888',
  doc => 'port for the webserver',
);

option 'hive' => (
  is => 'ro',
  format => 's',
  predicate => 1,
  doc => 'target url for dispatching received packages',
);

option 'homehive' => (
  is => 'ro',
  format => 's',
  predicate => 1,
  doc => 'target url of homehive cloud server (do not use)',
);

option 'serial' => (
  is => 'ro',
  format => 's',
  default => '/dev/ttyAMA0',
  doc => 'serial port for the HiveJSO stream',
);

option 'baud' => (
  is => 'ro',
  format => 's',
  default => '9600',
  doc => 'baud rate for the serial port',
);

sub run {
  my ( $self ) = @_;

  my $root = path(dist_dir('App-HiveHub'))->absolute->realpath->stringify;
  my $server = Twiggy::Server->new(
    port => $self->port,
  );
  my $last_socket;
  my $pocketio = PocketIO->new( handler => sub {} );

  my $uart = AnyEvent::SerialPort->new(
    serial_port => [
      $self->serial,
      [ baudrate => $self->baud ],
    ],
    read_size => 1,
  );

  $uart->on_read(sub {
    my ( $uart ) = @_;
    $uart->push_read(hivejso => sub {
      my ( $uart, $data ) = @_;
      if (ref $data eq 'HiveJSO::Error') {
        p($data->error); p($data->garbage);
        return;
      }
      print $data->original_json."\n";
      my $hivehub_data = $data->add(
        timestamp => DateTime->now->epoch,
      );
      if ($self->has_homehive) {
        http_post($self->homehive, '{"orig":'.$data->original_json.',"hivehub":'.$hivehub_data->hivejso.'}',
          headers => {
            'user-agent' => 'HiveHub/'.$VERSION,
            'content-type' => 'application/json',
          }, sub {},
        );
      }
      if ($self->has_hive) {
        http_post($self->hive, $hivehub_data->hivejso,
          headers => {
            'user-agent' => 'HiveHub/'.$VERSION,
            'content-type' => 'application/json',
          }, sub {},
        );        
      }
      if ($pocketio->pool->{connections} && %{$pocketio->pool->{connections}}) {
        my @keys = keys %{$pocketio->pool->{connections}};
        $pocketio->pool->{connections}->{$keys[0]}->sockets->emit('data',decode_json($hivehub_data->hivejso));
      }
    });
  });

  $server->register_service(builder {
    mount '/socket.io' => $pocketio;
    mount '/' => builder {
      enable 'Rewrite', rules => sub { s{^/$}{/index.html}; };
      enable "Plack::Middleware::Static", path => qr{^/}, root => $root;
    };
  });

  print "\n Starting HiveHub (port ".$self->port.")...\n\n";

  AE::cv->recv;
}

1;

__END__

=pod

=head1 NAME

App::HiveHub - Implementation of Hive Hub for gathering from the hive drones [IN DEVELOPMENT]

=head1 VERSION

version 0.001

=head1 DESCRIPTION

B<IN DEVELOPMENT, DO NOT USE YET>

See L<http://homehive.tv/> for now.

=head1 SUPPORT

IRC

  Join #hardware on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  https://github.com/homehivelab/p5-app-hivehub
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/homehivelab/p5-app-hivehub/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
