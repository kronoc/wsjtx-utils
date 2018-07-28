#!/usr/bin/perl -w

use warnings;
use strict;
use diagnostics;
use sigtrap;

$|=1;   #nb: if set to nonzero, forces a flush right away and after every write or print.

=begin comment
Code to parse a wsjt-x generated log file and create an ADI log file, for a given callsign for $self->{op}
=end comment
=cut

my $self = {
	op => 'EI8GVB',
	qth => 'IO63WN',
	custom => '',
	inputFile => '../wsjtx.log',
	@ARGV
};

my %bands = (
	1 => '160m',
	3 => '80m',
	5 => '60m',
	7 => '40m',
	10 => '30m',
	14 => '20m',
	18 => '17m',
	21 => '15m',
	24 => '12m',
	28 => '10m',
	50 => '6m',
	70 => '4m',
	144 => '2m',
);

run();

sub band{
	my $freq = shift;
	return undef unless defined $freq;
	if ($freq =~ m/(.+)\.(.+)/) {
		my $band = $bands{$1};
		return defined $band ? $band : '';
	}
}

sub toAdiDate{
	my $date = shift;
	$date =~ s/[-:]+//g;
	return $date;
	#	return length($date)>7 ? substr($date, 2, 6) : '';
}
sub toAdiTime{
	my $time = shift;
        $time =~ s/[-:]+//g; 
	return $time;
}

sub csvsplit {
        my $line = shift;
        my $sep = (shift or ',');

        return () unless $line;

        my @cells;
        $line =~ s/\r?\n$//;

        my $re = qr/(?:^|$sep)(?:"([^"]*)"|([^$sep]*))/;

        while($line =~ /$re/g) {
                my $value = defined $1 ? $1 : $2;
                push @cells, (defined $value ? $value : '');
        }
	return @cells;
}

sub run{
	open(my $fh, '<:encoding(UTF-8)', $self->{inputFile})  or die "Could not open file '$self->{inputFile}' $!";
	while (my $row = <$fh>) {
		my @cells = csvsplit($row);
		my $adi;
		$adi .= "<call:@{[length($cells[4])]}>$cells[4] ";
		$adi .= "<gridsquare:@{[length($cells[5])]}>$cells[5] ";
		$adi .= "<mode:@{[length($cells[7])]}>$cells[7] ";
		$adi .= "<rst_sent:@{[length($cells[8])]}>$cells[8] ";
		$adi .= "<rst_rcvd:@{[length($cells[9])]}>$cells[9] ";
		$adi .= "<qso_date:@{[length(toAdiDate($cells[0]))]}>@{[toAdiDate($cells[0])]} ";
		$adi .= "<time_on:@{[length(toAdiTime($cells[1]))]}>@{[toAdiTime($cells[1])]} ";
		$adi .= "<qso_date_off:@{[length(toAdiDate($cells[2]))]}>@{[toAdiDate($cells[2])]} ";
		$adi .= "<time_off:@{[length(toAdiTime($cells[3]))]}>@{[toAdiTime($cells[3])]} ";
		$adi .= "<band:@{[length(band($cells[6]))]}>@{[band($cells[6])]} ";
		$adi .= "<freq:@{[length($cells[6])]}>$cells[6] ";
		$adi .= "<station_callsign:@{[length($self->{op})]}>$self->{op} ";
		$adi .= "<my_gridsquare:@{[length($self->{qth})]}>$self->{qth} ";
		$adi .= "<comment:@{[length($cells[11])]}>$cells[11] ";
		$adi .= "$self->{custom} ";
		$adi .= "<eor>";
		print "$adi  \n";
		
	}
	close $fh;
}	
