# Dashboard plugin - Notifications
#!/usr/bin/perl
package Wireless;

use strict;
use warnings;
use Time::Local;
use CGI qw/:standard/;
use CGI::Carp 'fatalsToBrowser';

require '/var/ipfire/general-functions.pl';
require "${General::swroot}/lang.pl";
require "${General::swroot}/header.pl";

my %netsettings=();
our %entries = ();
my %wlanapsettings=();

&General::readhash("${General::swroot}/wlanap/settings", \%wlanapsettings);

my $wlan_card_status = '';
my $wlan_ap_status = '';
my $cmd_out = `/usr/sbin/iwconfig $wlanapsettings{'INTERFACE'} 2>/dev/null`;

if ( $cmd_out eq '' ){
	$wlan_card_status = '';
}else{
	$cmd_out = `/sbin/ifconfig | /bin/grep $wlanapsettings{'INTERFACE'}`;
	if ( $cmd_out eq '' ){
		$wlan_card_status = 'down';
	}else{
		$wlan_card_status = 'up';
		$cmd_out = `/usr/sbin/iwconfig $wlanapsettings{'INTERFACE'} | /bin/grep "Mode:Master"`;
		if ( $cmd_out ne '' ){
			$wlan_ap_status = 'up';
		}
	}
}

my $wifi_switch = 'off';
if($wlan_ap_status eq 'up') { $wifi_switch = 'on' }

my ($ip, $endtime, $ether, $hostname, @record, $record);
open(LEASES,"/var/state/dhcp/dhcpd.leases") or die "Can't open dhcpd.leases";
while (my $line = <LEASES>) {
	next if( $line =~ /^\s*#/ );
	chomp($line);
	my @temp = split (' ', $line);

	if ($line =~ /^\s*lease/) {
		$ip = $temp[1];
		# All fields are not necessarily read. Clear everything
		$endtime = 0;
		$ether = "";
		$hostname = "";
	} elsif ($line =~ /^\s*ends never;/) {
		$endtime = 'never';
	} elsif ($line =~ /^\s*ends/) {
		$line =~ /(\d+)\/(\d+)\/(\d+) (\d+):(\d+):(\d+)/;
		$endtime = timegm($6, $5, $4, $3, $2 - 1, $1 - 1900);
	} elsif ($line =~ /^\s*hardware ethernet/) {
		$ether = $temp[2];
		$ether =~ s/;//g;
	} elsif ($line =~ /^\s*client-hostname/) {
		shift (@temp);
		$hostname = join (' ',@temp);
		$hostname =~ s/;//g;
		$hostname =~ s/\"//g;
	} elsif ($line eq "}") {
		
		my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $dst);
		($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $dst) = localtime ($endtime);
		my $enddate = sprintf ("%02d/%02d/%d %02d:%02d:%02d",$mday,$mon+1,$year+1900,$hour,$min,$sec);
	
		if ($endtime eq 'never' || $endtime > time()) {
			if ( &General::IpInSubnet ( $ip,
					$netsettings{"BLUE_NETADDRESS"},
					$netsettings{"BLUE_NETMASK"} ) ) 
			{
				@record = ('IPADDR',$ip,'ENDTIME',$endtime,'ETHER',$ether,'HOSTNAME',$hostname,'NETWORK','BLUE');
				$record = {};
				%{$record} = @record;
				$entries{$record->{'IPADDR'}} = $record;
			}
			else
			{		
				@record = ('IPADDR',$ip,'ENDTIME',$endtime,'ETHER',$ether,'HOSTNAME',$hostname,'NETWORK','GREEN');
				$record = {};
				%{$record} = @record;
				$entries{$record->{'IPADDR'}} = $record;
			}
		}		
	}
}
close(LEASES);

my $green_leases = 0;
my $blue_leases = 0;
foreach my $key (%entries) {
	if($entries{$key}->{NETWORK} eq 'BLUE') { ++$blue_leases; }
	elsif ($entries{$key}->{NETWORK} eq 'GREEN') { ++$green_leases; }
}

#$wlanapsettings{'DRIVER'}
my $ssid_broadcast = '';
my $frequency = '2.4 GHz';

if($wlanapsettings{'HIDESSID'} eq 'on') { $ssid_broadcast = ' (hidden)' };
if($wlanapsettings{'HW_MODE'} eq 'an' || $wlanapsettings{'HW_MODE'} eq 'ac') { $frequency = 'Dual band' }

sub show
{
	my $widget_id = 2;
	return "
		<div class='box box-info' id='wid_$widget_id'>
			<div class='box-header with-border ui-sortable-handle'>
				<i class='fas fa-wifi large'></i>
				<h3 class='box-title'>Wireless</h3>
				<div class='box-tools pull-right'>
					<input type='checkbox' id='toggle-wifi' name='toggle-wifi' value='1' class='lcs_check' autocomplete='off'>
				</div>
			</div>
			<div class='box-body'>
				<div class='col-md-12'>
					<table class='table borderless anthracite'>
						<tbody>
							<tr>
								<td>SSID</td>
								<td>$wlanapsettings{'SSID'}$ssid_broadcast</td>
							</tr>
							<tr>
								<td>WLAN Standard</td>
								<td>802.11$wlanapsettings{'HW_MODE'}</td>
							</tr>
							<tr>
								<td>Frequency</td>
								<td>2.4 GHz</td>
							</tr>
							<tr>
								<td>Encryption</td>
								<td>$wlanapsettings{'ENC'}</td>
							</tr>
							<tr>
								<td>Connected Devices</td>
								<td>$blue_leases</td>
							</tr>
							<tr>
								<td colspan='2'>
									<hr />
								</td>
							</tr>
							<tr>
							<td>Guest Access</td>
							<td>
								<input type='checkbox' id='toggle-guest-wifi' name='toggle-guest-wifi' value='1' class='lcs_check' autocomplete='off' />								
							</td>
							</tr>
							<tr>
								<td>SSID</td>
								<td>---</td>
							</tr>
							<tr>
								<td>Encryption</td>
								<td>WPA2</td>
							</tr>
							<tr>
								<td>Connected Devices</td>
								<td>0</td>
							</tr>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	"
	;
}

1;