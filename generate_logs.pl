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

sub parseDate{
	my $dateTime = shift;
	my $year = "20".substr($dateTime, 0, 2);
	my $month=substr($dateTime, 2, 2);
	my $day=substr($dateTime, 4, 2);
	return "$year-$month-$day";
}
sub parseTime{
	my $dateTime = shift;
	my $m_hour = substr($dateTime, 7, 2);
	my $m_min=substr($dateTime, 9, 2);
	my $m_seconds=substr($dateTime, 11, 2);
	return "$m_hour:$m_min:$m_seconds";
}
sub parseQSOTime{
	my $dateTime = shift;
	my $m_hour = substr($dateTime, 0, 2);
	my $m_min=substr($dateTime, 2, 2);
	my $m_seconds=substr($dateTime, 4, 2);
	return "$m_hour:$m_min:$m_seconds";
}



sub run{
	my $op = $self->{op};
	open(my $fh, '<:encoding(UTF-8)', $self->{inputFile})  or die "Could not open file '$self->{inputFile}' $!";
	my ($qth,$sent,$rcvd,$dxcallr,$dxcallq,$qsoStartDate,$qsoStartTime);# = ("") x 7;
	while (my $row = <$fh>) {
		my $output="";
		if (index($row, "$op") != -1) {
			chomp $row;
			if ($row =~ m/(.+)  Transmitting (.+) MHz  (.+):  (.+) $op 73/) {
				my $frequency = $2;
				my $thisBand = band($2);
				my $date=parseDate($1);
				my $time=parseTime($1);
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

				if ($qsoStartTime eq ""){
					$qsoStartTime=$time;
				}

				$output = "$date,$qsoStartTime,$date,$time,$dx,$dxloc,$frequency,$mode,$sent,$dxrpt,,$mode  Sent: $sent  Rcvd: $rcvd,";
				$qsoStartTime="";
				print "$output \n";
			}	elsif ($row =~ m/(\d+)\s+(.+)\s+(.+)\s+(\d+)\s+~\s+(\w+)\s+(\w+)\s+(.+)\s(.+)/) {
				my $msg = $7;
			  if (index($msg, "73") != -1 || index($msg, "RR73") != -1 || index($msg, "RRR") != -1)  {
					#ignore
				} elsif (substr($msg, 0, 1) eq "R"){
					#if ($qsoStartTime eq ""){
					#	$qsoStartTime=parseQSOTime($1);
					#} this needs some work
					if (substr($msg, 1, 1) eq "-" || substr($msg, 1, 1) eq "+"){
						$dxcallr = $6;
						$rcvd = substr($msg, 1, 3);
					}else{
						$dxcallq = $6;
						$qth=substr($msg, 0, 4);
					}
				} elsif(substr($msg, 0, 1) eq "-" || substr($msg, 0, 1) eq "+"){
					#if ($qsoStartTime eq ""){
					#	$qsoStartTime=parseQSOTime($1);
					#}
					$dxcallr = $6;
					$rcvd = substr($msg, 0, 3);
				} else{
					$dxcallq = $6;
					#if ($qsoStartTime eq ""){
					#	$qsoStartTime=parseQSOTime($1);
					#}
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
