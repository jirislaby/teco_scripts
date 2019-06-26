#!/usr/bin/perl -w
use strict;
use Text::CSV qw(csv);
use RRDs;
use Data::Dumper;

die "bad args" if (scalar @ARGV < 2);
my $in_CSV = $ARGV[0];
my $out_RRD = $ARGV[1];

print "Handling $in_CSV -> $out_RRD\n";

my $csvf = csv(in => $in_CSV, sep_char => ";");

my %conv = (
	"Fitness Tep." => "temp_fit",
	"Garaz Tep." => "temp_garaz",
	"Obyvak Tep." => "temp_obyvak",
	"KuchynV Tep." => "temp_kuchV",
	"Digestor Tep." => "temp_dig",
	"Pracovna Tep." => "temp_prac",
	"Koupelna Tep." => "temp_koup1",
	"Technicka Tep." => "temp_tech",
	"Detsky J Tep." => "temp_det_j",
	"Detsky JZ Tep." => "temp_det_jz",
	"Loznice Tep." => "temp_loz",
	"Venkovni Tep." => "temp_out",
	"Svit" => "svit",
	"Svit100" => "svit",
	"Kotel" => "kotel",
);

my %silent = (
	"Digestor" => 1,
	"Text" => 1,
);

my %timestamps;
my $header = shift @$csvf;
my @template;
my %template;
for (my $col = 2; $col < scalar(@$header); $col++) {
	my $converted = $conv{$$header[$col]};
	if (defined $converted) {
		if (defined $template{$converted}) {
			print "Skipping duplicate column '$$header[$col]' mapped also to '$converted'\n";
			$converted = undef;
		} else {
			push @template, $converted;
			$template{$converted} = 1;
		}
	} elsif (!defined $silent{$$header[$col]}) {
		print "Skipping unknown column '$$header[$col]'\n";
	}
	$$header[$col] = $converted;
}
my $template = join ':', @template;

#print Dumper($header);
print "$template\n";

sub push_to_output($$) {
	my ($file, $entries) = @_;
	#print "Pushing ", scalar @$entries, " entries to $file\n";
	unshift @$entries, ($file, '-t', $template);
	#print Dumper($entries);
	RRDs::update @$entries;
	my $ERR = RRDs::error;
	if ($ERR) {
		if ($ERR =~ /illegal attempt to update using time/) {
			print "RRD WARNING: $ERR\n";
			#print Dumper($entries);
		} else {
			die "RRD ERROR: $ERR\n";
		}
	}
}

my @entries;
my $pushed = 0;

foreach my $line (@$csvf) {
	#print Dumper($line), "\n";
	my $date = $$line[0];
	$date =~ s/-//g;
	my $time = $$line[1];
	$time =~ s/:..$//;
	my @filt_list;

	# there is an empty col at the end
	for (my $col = 2; $col < scalar(@$line); $col++) {
		$$line[$col] =~ s/,/./;
		push(@filt_list, $$line[$col]) if defined $$header[$col];
	}
	my $vals = join ':', @filt_list;
	#print STDERR Dumper(\@filt_list);

	next if defined $timestamps{$date . $time};
	$timestamps{$date . $time} = 1;

	push @entries, "$date $time\@$vals";
	if (scalar @entries >= 1000) {
		$pushed += scalar @entries;
		push_to_output($out_RRD, \@entries);
		@entries = ();
	}
}

if (scalar @entries) {
	$pushed += scalar @entries;
	push_to_output($out_RRD, \@entries);
}

print "Pushed $pushed entries to $out_RRD\n";

1;
