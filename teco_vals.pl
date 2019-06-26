#!/usr/bin/perl -w
use strict;
use IO::Socket;

my $host = shift @ARGV;

my $socket = IO::Socket::INET->new(PeerAddr => $host, PeerPort => 5010,
	Proto => "tcp", Type => SOCK_STREAM) or
		die "Couldn't connect: $@\n";

foreach my $entry (@ARGV) {
	my $req = "GET:$entry";

	print $socket "$req\n";
	my $val = <$socket>;
	if (rindex($val, "$req,") == 0) {
		print substr $val, length($req) + 1;
	} else {
		print "U\n";
	}
}

close($socket);
