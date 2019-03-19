# Dashboard plugin - Notifications
#!/usr/bin/perl
package Services;

use strict;
use warnings;
use Time::Local;
use CGI qw/:standard/;
use CGI::Carp 'fatalsToBrowser';

require '/var/ipfire/general-functions.pl';
require "${General::swroot}/lang.pl";
require "${General::swroot}/header.pl";

my %netsettings=();
my %servicenames =(
	$Lang::tr{'dhcp server'} => 'dhcpd',
	$Lang::tr{'web server'} => 'httpd',
	$Lang::tr{'cron server'} => 'fcron',
	$Lang::tr{'dns proxy server'} => 'unbound',
	$Lang::tr{'logging server'} => 'syslogd',
	$Lang::tr{'kernel logging server'} => 'klogd',
	$Lang::tr{'ntp server'} => 'ntpd',
	$Lang::tr{'secure shell server'} => 'sshd',
	$Lang::tr{'vpn'} => 'charon',
	$Lang::tr{'web proxy'} => 'squid',
	'OpenVPN' => 'openvpn'
);

my %link =(
	$Lang::tr{'dhcp server'} => "<a href=\'dhcp.cgi\'>$Lang::tr{'dhcp server'}</a>",
	$Lang::tr{'web server'} => $Lang::tr{'web server'},
	$Lang::tr{'cron server'} => $Lang::tr{'cron server'},
	$Lang::tr{'dns proxy server'} => $Lang::tr{'dns proxy server'},
	$Lang::tr{'logging server'} => $Lang::tr{'logging server'},
	$Lang::tr{'kernel logging server'} => $Lang::tr{'kernel logging server'},
	$Lang::tr{'ntp server'} => "<a href=\'time.cgi\'>$Lang::tr{'ntp server'}</a>",
	$Lang::tr{'secure shell server'} => "<a href=\'remote.cgi\'>$Lang::tr{'secure shell server'}</a>",
	$Lang::tr{'vpn'} => "<a href=\'vpnmain.cgi\'>$Lang::tr{'vpn'}</a>",
	$Lang::tr{'web proxy'} => "<a href=\'proxy.cgi\'>$Lang::tr{'web proxy'}</a>",
	'OpenVPN' => "<a href=\'ovpnmain.cgi\'>OpenVPN</a>",
	"$Lang::tr{'intrusion detection system'} (GREEN)" => "<a href=\'ids.cgi\'>$Lang::tr{'intrusion detection system'} (GREEN)</a>",
	"$Lang::tr{'intrusion detection system'} (RED)" => "<a href=\'ids.cgi\'>$Lang::tr{'intrusion detection system'} (RED)</a>",
	"$Lang::tr{'intrusion detection system'} (ORANGE)" => "<a href=\'ids.cgi\'>$Lang::tr{'intrusion detection system'} (ORANGE)</a>",
	"$Lang::tr{'intrusion detection system'} (BLUE)" => "<a href=\'ids.cgi\'>$Lang::tr{'intrusion detection system'} (BLUE)</a>"
);

&General::readhash("${General::swroot}/ethernet/settings", \%netsettings);

sub show
{
	my $widget_id = 4;
	my $retval = "
		<div class='box box-primary' id='wid_$widget_id'>
			<div class='box-header with-border ui-sortable-handle'>
				<i class='fab fa-servicestack'></i>
				<h3 class='box-title'>Services</h3>
			</div>
			<div class='box-body'>
				<div class='col-md-12'>
					<table class='table borderless table-hover'>
						<tbody>
							<tr>
								<th>Name</th>
								<th>Status</th>
								<th>PID</th>
								<th>Memory usage</th>
							</tr>
	";
	
	my $key = '';
	foreach $key (sort keys %servicenames){	
		$retval = $retval. "<tr><td>".$link{$key}."</td>";
		my $shortname = $servicenames{$key};
		my $status = &isrunning($shortname);
		
		$retval = $retval.$status."</tr>";
	}
	
	# Generate list of installed addon pak's
	my @pak = `find /opt/pakfire/db/installed/meta-* 2>/dev/null | cut -d"-" -f2`;
	foreach (@pak){
		chomp($_);

		# Check which of the paks are services
		my @svc = `find /etc/init.d/$_ 2>/dev/null | cut -d"/" -f4`;
		foreach (@svc){
			# blacklist some packages
			#
			# alsa has trouble with the volume saving and was not really stopped
			# mdadm should not stopped with webif because this could crash the system
			#
			chomp($_);
			if ( $_ eq 'squid' ) {
				next;
			}
			if ( ($_ ne "alsa") && ($_ ne "mdadm") ) {				
				$retval = $retval . "<td>$_</td> ";
				#print "<td align='center' $col width='8%'><a href='services.cgi?$_!start'><img alt='$Lang::tr{'start'}' title='$Lang::tr{'start'}' src='/images/go-up.png' border='0' /></a></td>";
				#print "<td align='center' $col width='8%'><a href='services.cgi?$_!stop'><img alt='$Lang::tr{'stop'}' title='$Lang::tr{'stop'}' src='/images/go-down.png' border='0' /></a></td> ";
				my $status = &isrunningaddon($_);
		 		$status =~ s/\\[[0-1]\;[0-9]+m//g;

				chomp($status);
				$retval = $retval.$status."</tr>";
			}
		}
	}
	
	$retval = $retval . "		
						</tbody>
					</table>
				</div>
			</div>
		</div>";
		
	return $retval;
}

sub isrunning{
	my $cmd = $_[0];
	my $status = "<td><span class='label label-danger'>Stopped</span></td><td colspan='2'></td>";
	my $pid = '';
	my $testcmd = '';
	my $exename;
	my $memory;

	$cmd =~ /(^[a-z]+)/;
	$exename = $1;

	if (open(FILE, "/var/run/${cmd}.pid")){
		$pid = <FILE>; chomp $pid;
		close FILE;
		if (open(FILE, "/proc/${pid}/status")){
			while (<FILE>){
				if (/^Name:\W+(.*)/) {
					$testcmd = $1;
				}
			}
			close FILE;
		}
		if (open(FILE, "/proc/${pid}/status")) {
			while (<FILE>) {
				my ($key, $val) = split(":", $_, 2);
				if ($key eq 'VmRSS') {
					$memory = $val;
					last;
				}
			}
			close(FILE);
		}
		if ($testcmd =~ /$exename/){
			$status = "<td><span class='label label-success'>Running</span></td><td>$pid</td><td>$memory</td>";
		}
	}
	return $status;
}

sub isrunningaddon{
	my $cmd = $_[0];
	my $status = "<td><span class='label label-danger'>Stopped</span></td><td colspan='2'></td>";
	my $pid = '';
	my $testcmd = '';
	my $exename;
	my @memory;

	my $testcmd = `/usr/local/bin/addonctrl $_ status 2>/dev/null`;

	if ( $testcmd =~ /is\ running/ && $testcmd !~ /is\ not\ running/){
		$status = "<td><span class='label label-success'>Running</span></td>";
		$testcmd =~ s/.* //gi;
		$testcmd =~ s/[a-z_]//gi;
		$testcmd =~ s/\[[0-1]\;[0-9]+//gi;
		$testcmd =~ s/[\(\)\.]//gi;
		$testcmd =~ s/  //gi;
		$testcmd =~ s///gi;

		my @pid = split(/\s/,$testcmd);
		$status .="<td>$pid[0]</td>";

		my $memory = 0;

		foreach (@pid){
			chomp($_);
			if (open(FILE, "/proc/$_/statm")){
				my $temp = <FILE>;
				@memory = split(/ /,$temp);
			}
			$memory+=$memory[0];
		}
		$status .="<td>$memory KB</td>";
	}else{
		$status = "<td><span class='label label-danger'>Stopped</span></td><td colspan='2'></td>";
	}
	return $status;
}


1;