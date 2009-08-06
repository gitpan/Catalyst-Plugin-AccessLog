package Catalyst::Plugin::AccessLog::Formatter;
our $VERSION = '0.02';


# ABSTRACT: Log formatter for Catalyst::Plugin::AccessLog

use namespace::autoclean;
use Moose;
use DateTime;

my %items;

sub item {
  my ($names, $code) = @_;
  $names = [ $names ] unless ref $names;

  $items{$_} = $code for @$names;
}

my %whitespace_escapes = (
  "\r" => "\\r",
  "\n" => "\\n",
  "\t" => "\\t",
  "\x0b" => "\\v",
);

# Approximate the rules for safely escaping headers/etc given in the apache docs
sub escape_string {
  my $str = shift;
  return "" unless defined $str and length $str;

  $str =~ s/(["\\])/\\$1/g;
  $str =~ s/([\r\n\t\x0b])/$whitespace_escapes{$1}/eg;
  $str =~ s/([^[:print:]])/sprintf '\x%02x', ord $1/eg;

  return $str;
}

sub get_item {
  my ($self, $c, $key, $arg) = @_;

  return "[unknown format key $key]" unless exists $items{$key};
  return $items{$key}->($c, $arg);
}

sub format_line {
  my ($self, $c) = @_;
  my $format = $c->config->{'Plugin::AccessLog'}{format};
  my $output = "";

  while (1) {
    my $argument = qr/\{ ( [^}]+ ) \}/x;
    my $longopt = qr/\[ ( [^]]+ ) \]/x;

    if ($format =~ /\G \Z/cgx) { # Found end of string.
      last;
    } elsif ($format =~ /\G ( [^%]+ )/cgx) { # Found non-percenty text.
      $output .= $1;
    } elsif ($format =~ /\G \%\% /cgx) { # Literal percent
      $output .= "%";
    } elsif ($format =~ /\G \% $argument $longopt/cgx) { # Long opt with argument
      $output .= $self->get_item($c, $2, $1);
    } elsif ($format =~ /\G \% $longopt/cgx) { # Long opt
      $output .= $self->get_item($c, $1);
    } elsif ($format =~ /\G \% $argument (.)/cgx) { # Short opt with argument
      $output .= $self->get_item($c, $2, $1);
    } elsif ($format =~ /\G \% (.)/cgx) { # Short opt
      $output .= $self->get_item($c, $1);
    } else {
      warn "Can't happen!";
    }
  }

  return $output;
}


item ['a', 'remote_address'] => sub {
  return shift->request->address;
};


item ['b', 'clf_size'] => sub {
  return shift->response->content_length || "-";
};


item ['B', 'size'] => sub {
  return shift->response->content_length;
};


item ['h', 'remote_host'] => sub {
  my $c = shift;
  if ($c->config->{'Plugin::AccessLog'}{hostname_lookups}) {
    return $c->request->hostname;
  } else {
    return $c->request->address;
  }
};


item ['i', 'header'] => sub {
  my ($c, $arg) = @_;
  my $header = $c->req->header($arg);
  return "-" unless defined($header);
  return escape_string($header);
};


item 'l' => sub { # for apache compat
  return "-";
};


item ['m', 'method'] => sub {
  return shift->request->method;
};


item ['p', 'port'] => sub {
  return shift->req->base->port;
};


item ['r', 'request_line'] => sub { # Mostly for apache's sake
  my $c = shift;
  return $c->req->method . " /" . $c->req->path . " " . $c->req->protocol;
};


item ['s', 'status'] => sub {
  return shift->response->status;
};


sub _request_start {
  my ($c) = @_;

  # Remove the hack when we're comfortable depending on Catalyst 5.8008.
  my @time = $c->stats->can('created')
    ? $c->stats->created
    : @{ $c->stats->{tree}->getNodeValue->{t} };
  return $time[0] + $time[1] / 1_000_000;
}

item ['t', 'apache_time'] => sub {
  my ($c, $arg) = @_;
  return "-" unless $c->use_stats;
  my $config = $c->config->{'Plugin::AccessLog'};
  my $format = $arg || '[%d/%b/%Y:%H:%M:%S %z]'; # Apache default
  return DateTime->from_epoch(epoch => _request_start($c), 
    time_zone => $config->{time_zone})->strftime($format);
};


item ['time', 'datetime'] => sub {
  my ($c, $arg) = @_;
  return "-" unless $c->use_stats;
  my $config = $c->config->{'Plugin::AccessLog'};
  my $format = $arg || $config->{time_format};

  return DateTime->from_epoch(epoch => _request_start($c),
    time_zone => $config->{time_zone})->strftime($format);
};


item ['u', 'remote_user'] => sub {
  return shift->request->remote_user || '-';
};


item ['V', 'v', 'host_port'] => sub {
  return shift->request->base->host_port;
};


item 'hostname' => sub {
  return shift->request->base->host;
};


# Possibly improvement: use uri_for to absolutize this with base, and then
# take the path component off of that...
item ['U', 'path'] => sub {
  return '/' . shift->request->path;
};


item ['T', 'handle_time'] => sub {
  my $c = shift;
  if ($c->use_stats) {
    return sprintf "%f", $c->stats->elapsed;
  } else {
    return "-";
  }
};


no Moose;

1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::AccessLog::Formatter - Log formatter for Catalyst::Plugin::AccessLog

=head1 VERSION

version 0.02

=head1 DESCRIPTION

The log format argument is a string which will be used to generate each line
of the access log. The string consists of literal characters which will be
copied to the log output verbatim, and escapes, which will be replaced with
information about the request or the response. This format string is
intended to be compatible with the Apache C<LogFormat> directive, however it
contains some extensions and leaves a few features unimplemented.

Escapes can be either B<short escapes> or B<long escapes>. Both types begin
with the "C<%>" character. Short escapes consist of a C<%> followed by a
single character, for example C<%h> for the remote hostname. Long
escapes consist of a C<%> followed by a name inside B<square brackets>, for
example C<%[remote_hostname]> for the same option. Apache-compatible
options have both short escapes and long escapes, while incompatible options
have only long escapes.

Some escapes (currently C<%[time]>, C<%[apache_time]>, C<%[header]>, and
C<%[apache_header]>) may also take an argument, which can be optional or
required. The argument is placed inside B<curly braces> between the percent
sign and the name of the escape, for example C<%{User-agent}i> or
C<%{User-agent}[header]> to get the value of the C<User-agent> header.

A literal percent-sign can be produced in the output using the escape
sequence C<%%>.

=head2 Escapes

=over 4

=item %[remote_address], %a

The IP address of the remote client.



=item %[clf_size], %b

The size of the response content in bytes. If the response content is empty,
produces a dash C<-> instead of 0. This is compatible with CLF.



=item %[size], %B

The size of the response content in bytes. Always numeric, even for 0.



=item %[remote_host], %h

The hostname of the remote client, if the C<hostname_lookups> config option
is true. Otherwise, the IP address of the remote client, as
C<%[remote_address]>.



=item %[header], %i

The value of the request header named in the (mandatory) argument, or "-" if
no such header was provided. Usage: C<%{User-agent}i> to get the
C<User-agent> request header.



=item %l

For Apache compatibility, this option produces a single dash C<->. In Apache
this option returns the remote username from an C<ident> check, if the
module is present, which it never is, which means it always produces a
single dash on Apache as well. We don't bother implementing ident.



=item %[method], %m

The request method (e.g. GET, POST).



=item %[port], %p

The port number that the request was received on. In apache this is the
server's "canonical port", however this is information that's not available
to Catalyst.



=item %[request_line], %r

The first line of the HTTP request, e.g. C<"GET / HTTP/1.0">.



=item %[status], %s

The HTTP status of the response, e.g. 200 or 404.



=item %[apache_time], %t

The time that the request was received.

While this escape and the C<%[time]> escape both take an optional
C<strftime> argument, they differ in their default formats. This escape
defaults to a "human readable" format which is lousy to parse, but is
nonetheless compatible with apache.



=item %[time], %[datetime]

The time that the request was received.

While this escape and the C<%[apache_time]> escape both take an optional
C<strftime> argument, they differ in their default formats. This escape
defaults to the C<time_format> config option provided to
C<Catalyst::Plugin::AccessLog>. If that option is not provided, the default
is ISO 8601.



=item %[remote_user], %u

The REMOTE_USER variable as set by HTTP basic auth, or certain frontend
authentication methods. Returns a dash C<-> if no such thing exists.



=item %[host_port], %v, %V

The host and the port of the request URI. Apache specifies that these should
be the server's "canonical" host and port, but this information is
unavailable to Catalyst.



=item %[hostname]

The hostname of the request URI.



=item %[path], %U

The request path (relative to the application root, but with a leading
slash).



=item %[handle_time], %T

The time spent handling this request, as provided by the C<< $c->stats >>
object. Returns a dash C<-> if stats are unavailable.



=back 



=head1 AUTHORS

  Andrew Rodland <andrew@hbslabs.com>
  Murray <sysmon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 


