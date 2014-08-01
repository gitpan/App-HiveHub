
requires 'Path::Tiny', '0';
requires 'PocketIO', '0';
requires 'Plack::Builder', '0';
requires 'Twiggy', '0';
requires 'Plack', '0';
requires 'Plack::Middleware::Rewrite', '0';
requires 'AnyEvent', '0';
requires 'AnyEvent::SerialPort', '0';
requires 'AnyEvent::HiveJSO', '0';
requires 'AnyEvent::HTTP', '0';
requires 'HiveJSO', '0.007';
requires 'Data::Printer', '0';
requires 'DateTime', '0';
requires 'JSON::MaybeXS', '0';
requires 'MooX', '0';
requires 'MooX::Options', '0';
requires 'File::ShareDir::ProjectDistDir', '0';

on test => sub {
  requires 'Test::More', '0.96';
};
