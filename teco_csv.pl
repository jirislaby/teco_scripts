#!/usr/bin/perl -w
use strict;
use IO::Socket;

my $host = $ARGV[0];
my $file = $ARGV[1];

my $socket = IO::Socket::INET->new(PeerAddr => $host, PeerPort => 5010,
	Proto => "tcp", Type => SOCK_STREAM) or
		die "Couldn't connect: $@\n";

# //DATALOG0/KOLEKCE0/2018/11/20160433.CSV
print $socket "GETFILE:$file\n";

my $rqlen = length "GETFILE:$file\[";
my $datalen;

do {
	my $cont;
	read $socket, $cont, $rqlen;

#print "XXXCONT1='$cont'\n";

	$datalen = '';
	while (1) {
		my $byte;
		read $socket, $byte, 1;
		last if ($byte eq ']');
		$datalen .= $byte;
	}

	# skip '='
#print "XXXDATALEN=$datalen\n";
	read $socket, $cont, 1;
#print "XXXCONT2='$cont'\n";

	read $socket, $cont, $datalen;
	print $cont;
#print "XXXCONT3='", substr($cont, 0, 16), "'\n";

	# skip '\r\n'
	read $socket, $cont, 2;
#print "XXXCONT4='$cont'\n";
} while ($datalen);

close($socket);
