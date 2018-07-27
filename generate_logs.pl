#!/usr/bin/perl -w

use warnings;
use strict;
use diagnostics;
use sigtrap;

$|=1;   #nb: if set to nonzero, forces a flush right away and after every write or print.

=begin comment
Code to parse a wsjt-x generated ALL.txt log file and reconstruct QSO logs for a given callsign for $self->{op}
=end comment
=cut

my $self = {
	op => 'EI8GVB',
	inputFile => './ALL.txt',
	outputFile => './all-fixed.log',
	adiOutputFile => './all-fixed.adi',
	timeout => 180,
	@ARGV
};

my %bands = (
3 => '80M',
5 => '60M',
7 => '40M',
10 => '30M',
14 => '20M',
18 => '17M',
21 => '15M',
24 => '12M',
28 => '10M',
);

run();

sub band{
	my $freq = shift;
	return undef unless defined $freq;
	if ($freq =~ m/(.+)\.(.+)/) {
		my $band = $bands{$1};
		return "$band";
	}
}

sub getDate{
	my $dateTime = shift;
	my $year = "20".substr($dateTime, 0, 2);
	my $month=substr($dateTime, 2, 2);
	my $day=substr($dateTime, 4, 2);
	return "$year-$month-$day";
}
sub getTime{
	my $dateTime = shift;
	my $hour = substr($dateTime, 0, 2);
	my $min=substr($dateTime, 2, 2);
	my $seconds=substr($dateTime, 4, 2);
	return "$hour:$min:$seconds";
}

sub run{
	my $op = $self->{op};
	open(my $fh, '<:encoding(UTF-8)', $self->{inputFile})  or die "Could not open file '$self->{inputFile}' $!";

	my $qth = "";
	my $sent = "";
	my $rcvd = "";
	my $dxcallr = "";
	my $dxcallq = "";
	my $qsoStartDate = "";
	my $qsoStartTime = "";

	while (my $row = <$fh>) {
		my $output="";
		if (index($row, "$op") != -1) {
			chomp $row;
			if ($row =~ m/(.+)  Transmitting (.+) MHz  (.+):  (.+) $op 73/) {
				my $frequency = $2;
				my $thisBand = band($2);
				my $date=getDate($1);
				my $time=getTime($1);
				my $mode=$3;
				my $dx=$4;
				my $dxloc="";
				my $dxrpt="";
				if ($dx eq $dxcallq){
					$dxloc=$qth;
				}
				if ($dx eq $dxcallr){
					$dxrpt=$rcvd;
				}

				$output = "$date,$time,$date,$time,$dx,$dxloc,$frequency,$mode,$sent,$dxrpt,,$mode  Sent: $sent  Rcvd: $rcvd,";
				print "$output \n";
			}	elsif ($row =~ m/(\d+)\s+(.+)\s+(.+)\s+(\d+)\s+~\s+(\w+)\s+(\w+)\s+(.+)\s(.+)/) {
				my $msg = $7;
			  if (index($msg, "73") != -1 || index($msg, "RR73") != -1 || index($msg, "RRR") != -1)  {
					#ignore
				} elsif (substr($msg, 0, 1) eq "R"){
					if (substr($msg, 1, 1) eq "-" || substr($msg, 1, 1) eq "+"){
						$dxcallr = $6;
						$rcvd = substr($msg, 1, 3);
					}else{
						$dxcallq = $6;
						$qth=$7;
					}
				} elsif(substr($msg, 0, 1) eq "-" || substr($msg, 0, 1) eq "+"){
					$dxcallr = $6;
					$rcvd = substr($msg, 0, 3);
				} else{
					$dxcallq = $6;
					$qth=substr($msg, 0, 4);
				}

			}elsif ($row =~ m/(.+)  Transmitting (.+) MHz  (.+):  (.+) $op (.+)/) {
				my $msg = $5;
				if (index($msg, "73") != -1 || index($msg, "RR73") != -1 || index($msg, "RRR") != -1)  {
					#ignore
				} elsif (substr($msg, 0, 1) eq "R"){
					if (substr($msg, 1, 1) eq "-" || substr($msg, 1, 1) eq "+"){
						$sent = substr($msg, 1, 3);
					}
				} elsif(substr($msg, 0, 1) eq "-" || substr($msg, 0, 1) eq "+"){
						$sent = substr($msg, 0, 3);
				}
			}
		}
	}
}
