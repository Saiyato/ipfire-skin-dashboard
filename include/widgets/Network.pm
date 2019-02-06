# Dashboard plugin - Notifications
#!/usr/bin/perl
package Network;

use strict;
use warnings;
use Time::Local;
use CGI qw/:standard/;
use CGI::Carp 'fatalsToBrowser';

require '/var/ipfire/general-functions.pl';
require "${General::swroot}/lang.pl";
require "${General::swroot}/header.pl";

my %netsettings=();
my %proxysettings=();
my %confighash=();
my %vpnsettings=();

my %dashboardsettings=();
my %cgiparams=();
my %settings;
&General::readhash("${General::swroot}/ethernet/settings", \%netsettings);
&General::readhash("${General::swroot}/proxy/advanced/settings", \%proxysettings);
&General::readhash("${General::swroot}/ovpn/settings", \%confighash);
&General::readhash("${General::swroot}/vpn/settings", \%vpnsettings);

our %entries = ();
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

my $ipaddr;
my $gateway;
my $dns_servers;
my $sub=&General::iporsubtocidr($netsettings{'GREEN_NETMASK'});
my $dhcp_state = 'OFF';
my $proxy_state = 'OFF';
my $ipsecip = '0.0.0.0';
my $ipsec_state = '<span class="red">offline</span>';
my $openvpnip = '0.0.0.0';
my $openvpn_state = '<span class="red">offline</span>';

if (open(IPADDR,"${General::swroot}/red/local-ipaddress")) {
	$ipaddr = <IPADDR>;
	close IPADDR;
	chomp ($ipaddr);
}

if ( -e "${General::swroot}/red/remote-ipaddress" ) {
open (TMP, "<${General::swroot}/red/remote-ipaddress");
	$gateway = <TMP>;
	chomp($gateway);
	close TMP;
}

if ( -e "${General::swroot}/red/dns" ) {
	open (TMP, "<${General::swroot}/red/dns");
	$dns_servers = <TMP>;
	chomp($dns_servers);
	close TMP;
}

if ( $netsettings{'GREEN_TYPE'} ne "DHCP" ) { $dhcp_state = 'ON'; }
if ( $proxysettings{'ENABLE'} eq 'on' ) { $proxy_state = 'ON'; }

if ( $vpnsettings{'ENABLED'} eq 'on' || $vpnsettings{'ENABLED_BLUE'} eq 'on' ) {
	$ipsecip = $vpnsettings{'VPN_IP'};
	$ipsec_state = '<span class="light-green">online</span>';
}

if (($confighash{'ENABLED'} eq "on") ||
    ($confighash{'ENABLED_BLUE'} eq "on") ||
    ($confighash{'ENABLED_ORANGE'} eq "on")) {
	my ($ovpnip,$subovnp) = split("/",$confighash{'DOVPN_SUBNET'});
	$subovnp = &General::iporsubtocidr($subovnp);
	$openvpnip = "$ovpnip/$subovnp";
	$openvpn_state = '<span class="light-green">online</span>';
}

sub show
{
	my $widget_id = 1;
	return "
		<div class='box box-danger' id='wid_$widget_id'>
			<div class='box-header with-border ui-sortable-handle'>
				<i class='fas fa-cloud'></i>
				<h3 class='box-title'>Network</h3>
			</div>
			<div class='box-body'>
				<div class='col-md-12'>
					<table class='table borderless anthracite'>
						<tbody>
							<tr>
								<td class='red'>Internet</td>
								<td>$ipaddr</td>
							</tr>
							<tr>
								<td>Gateway</td>
								<td>$gateway</td>
							</tr>
							<tr>
								<td>DNS Servers</td>
								<td> 192.168.178.1 8.8.8.8</td>
							</tr>
							<tr>
								<td>Connected</td>
								<td>
									<span class='up'/>
								</td>
							</tr>
							<tr>
								<td colspan='2'>
									<hr />
								</td>
							</tr>
							<tr>
								<td class='light-green'>LAN</td>
								<td>$netsettings{'GREEN_ADDRESS'}/$sub</td>
							</tr>
							<tr>
								<td>DHCP</td>
								<td>$dhcp_state</td>
							</tr>
							<tr>
								<td>Proxy</td>
								<td>$proxy_state</td>
							</tr>
							<tr>
								<td>Connected Devices</td>
								<td>$green_leases</td>
							</tr>
							<tr>
								<td colspan='2'>
									<hr />
								</td>
							</tr>
							<tr>
								<td class='teal'>IPSec</td>
								<td>$ipsecip ($ipsec_state)</td>
							</tr>
							<tr>
								<td class='teal'>OpenVPN</td>
								<td>$openvpnip ($openvpn_state)</td>
							</tr>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	"
	;
}