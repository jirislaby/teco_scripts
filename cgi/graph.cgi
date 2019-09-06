#!/usr/bin/perl -w
use strict;
use CGI ':standard';
use RRDp;
use RRDs;
use Data::Dumper;

$|++;

my $RRD = '/home/xslaby/barak.rrd';
my $cg = new CGI;

my $stime = $cg->param('stime') || 'now-8month';
my $etime = $cg->param('etime');

my $width = $cg->param('width') || 1300;
my $height = $cg->param('height') || 600;

$width = 1300 if ($width < 0 || $width > 4096);
$height = 600 if ($height < 0 || $height > 4096);

my @cmdline = ('-', '--left-axis-format', '%.1lf',
	'--right-axis', '1:0',
	'--right-axis-format', '%.1lf',
	'-w', $width, '-h', $height,
	'-s', $stime,
);

my @defs = (
        [ 'temp_fit' ],
        [ 'temp_garaz' ],
        [ 'temp_obyvak' ],
        [ 'temp_kuchV' ],
        [ 'temp_dig' ],
        [ 'temp_prac' ],
        [ 'temp_koup1' ],
        [ 'temp_tech' ],
        [ 'temp_det_jz' ],
        [ 'temp_det_j' ],
        [ 'temp_loz' ],
        [ 'temp_koup2' ],
        [ 'temp_chodba2' ],
        [ 'temp_out' ],
        [ 'svit' ],
        [ 'kotel' ],
        [ 'der_prac', 'LAST' ],
        [ 'der_obyv', 'LAST' ],
        [ 'der_loz', 'LAST' ],
);

foreach my $def (@defs) {
	my $fun = $$def[1] || 'AVERAGE';
	push @cmdline, "DEF:$$def[0]=$RRD:$$def[0]:$fun";
}

my @cdefs = (
	[ "kotel15", "kotel,15,+" ],
	[ "svit_div", "svit,7,/" ],
);

foreach my $def (@cdefs) {
	push @cmdline, "CDEF:$$def[0]=$$def[1]";
}

my @graphs = (
	[ 'Venkovní',      'temp_out',     'AREA',  '000000' ],
	[ 'Fitness',       'temp_fit',     'LINE1', 'a00000' ],
	[ 'Garáž',         'temp_garaz',   'LINE1', 'f00000' ],
	[ 'Obývák',        'temp_obyvak',  'LINE1', '006000' ],
	[ 'Kuchyně V',     'temp_kuchV',   'LINE1', '008000' ],
	[ 'Digestoř',      'temp_dig',     'LINE1', '00a000' ],
	[ 'Pracovna',      'temp_prac',    'LINE1', '00f000' ],
	[ 'Koupelna',      'temp_koup1',   'LINE1', '60a060' ],
	[ 'Technická',     'temp_tech',    'LINE1', 'a0f0a0' ],
	[ 'Dětský JZ',     'temp_det_jz',  'LINE1', '000060' ],
	[ 'Dětský J',      'temp_det_j',   'LINE1', '000080' ],
	[ 'Ložnice',       'temp_loz',     'LINE1', '0000a0' ],
	[ 'Chodba 2NP',    'temp_chodba2', 'LINE1', '0000f0' ],
	[ 'Kotel',         'kotel15',      'LINE1', '808080' ],
	[ 'Svit',          'svit_div',     'LINE1', '4080a0' ],
#	[ 'Der. pracovna', 'der_prac',     'LINE1', '004000' ],
#	[ 'Der. obývák',   'der_obyv',     'LINE1', '400000' ],
#	[ 'Der. ložnice',  'der_loz',      'LINE1', '004040' ],
);

if (defined $cg->param('help')) {
	print $cg->header(-type => 'text/plain',
		-charset => 'UTF-8',
		-expires => 'now');

	print "Datas:\n\t", join "\n\t", map { $$_[0] } @graphs;

	exit 1;
}

my %req_datas;

if ($cg->param('datas')) {
	%req_datas = map { $_ => 1 } split /,/, $cg->param('datas');
} else {
	%req_datas = map { $$_[0] => 1 } @graphs;
}

foreach my $graph (@graphs) {
	if ($req_datas{$$graph[0]}) {
		push @cmdline, qq($$graph[2]:$$graph[1]#$$graph[3]:"$$graph[0]");
	}
}

if (defined $cg->param('debug')) {
	print $cg->header(-type => 'text/plain',
		-charset => 'UTF-8',
		-expires => 'now');

	print Dumper(\@cmdline);

	exit 1;
}

print $cg->header(-type => 'image/png',
	-charset => 'UTF-8',
	-expires => 'now');

RRDs::graph(@cmdline);

my $ERR = RRDs::error;
die "RRD ERROR: $ERR" if ($ERR);

1;
