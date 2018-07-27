#!/usr/bin/perl -w

use warnings;
use strict;
use diagnostics;
use sigtrap;

$|=1;   #nb: if set to nonzero, forces a flush right away and after every write or print.

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
		#	return "${$bands{$1}}"
		return "$band";
	}
}

sub getDate{
	my $dateTime = shift;
	#180527_204115
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
				print "$row\n";
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
			}	elsif ($row =~ m/(.+) (.+) (.+)  (.+) ~  (.+) (.+) (.+)/) {
				my $msg = $7;
				if ($msg eq "RR73" ){
					#ignore
				} elsif (substr($msg, 0, 1) eq "R"){
					if (substr($msg, 1, 1) eq "-" || substr($msg, 1, 1) eq "+"){
						if ($6 eq $op){
							$sent = substr($msg, 1, 3);
						}else{
							$dxcallr = $6;
							$rcvd = substr($msg, 1, 3);
						}
					}
				} elsif(substr($msg, 0, 1) eq "-" || substr($msg, 0, 1) eq "+"){
					if ($6 eq $op){
						$sent = $7;
					}else{
						$dxcallr = $6;
						$rcvd = $7;
					}
				} else{
					$dxcallq = $6;
					$qth=$7;
				}

			}
=begin comment

=end comment
=cut

			#154345 -15  0.4 1006 ~  EI8 DL1ZBO JN49
			#154400   1 -0.8 1427 ~  VR2XMT DL1RI -11
			#154400  -8  0.6 1489 ~  RV6FT DL3OH R-16
		}




	}
}
