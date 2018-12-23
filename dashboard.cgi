#!/usr/bin/perl
###############################################################################
#                                                                             #
# IPFire.org - A linux based firewall                                         #
# Copyright (C) 2005-2010  IPFire Team                                        #
#                                                                             #
# This program is free software: you can redistribute it and/or modify        #
# it under the terms of the GNU General Public License as published by        #
# the Free Software Foundation, either version 3 of the License, or           #
# (at your option) any later version.                                         #
#                                                                             #
# This program is distributed in the hope that it will be useful,             #
# but WITHOUT ANY WARRANTY; without even the implied warranty of              #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
# GNU General Public License for more details.                                #
#                                                                             #
# You should have received a copy of the GNU General Public License           #
# along with this program.  If not, see <http://www.gnu.org/licenses/>.       #
#                                                                             #
###############################################################################

use strict;
use Time::Local;
use Data::Dumper;

# enable only the following on debugging purpose
#use warnings;
#use CGI::Carp 'fatalsToBrowser';

require '/var/ipfire/general-functions.pl';
require "${General::swroot}/lang.pl";
require "${General::swroot}/header.pl";

my %netsettings=();
my %proxysettings=();
my %confighash=();
my %vpnsettings=();
my %wlanapsettings=();

&General::readhash("${General::swroot}/ethernet/settings", \%netsettings);
&General::readhash("${General::swroot}/proxy/advanced/settings", \%proxysettings);
&General::readhash("${General::swroot}/ovpn/settings", \%confighash);
&General::readhash("${General::swroot}/vpn/settings", \%vpnsettings);
&General::readhash("/var/ipfire/wlanap/settings", \%wlanapsettings);

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

&Header::showhttpheaders();
&Header::openpage('Dashboard', 1, '');

print <<EOF
<!-- green: $green_leases, blue: $blue_leases -->
EOF
;

print <<EOF
<script type="text/javascript" src="/themes/dashboard/include/js/jquery.sparkline.min.js"></script>
<script type="text/javascript" src="/themes/dashboard/include/js/lc_switch.min.js"></script>
<script type="text/javascript">
		\$(document).ready(function(e) {			
			\$('#toggle-wifi').lc_switch();
			\$('#toggle-guest-wifi').lc_switch();
			\$('#toggle-wifi').lcs_$wifi_switch();
			// Guest wifi not yet implemented!
		
			// triggered each time a field changes status
			\$(document).on('lcs-statuschange', '.lcs_check', function() {
				var action 	= (\$(this).is(':checked')) ? '$Lang::tr{'start'}' : '$Lang::tr{'stop'}';
				var object = { ACTION: action };
				\$.post( "/cgi-bin/wlanap.cgi", object );
			});
		});

		\$(function() {
			\$('.dial').each(function () { 
				var elm = \$(this);
				var cval = elm.attr('value');
				elm.knob({
					'thickness':.1,
					'width': 80,
					'height': 80,
					'dynamicDraw': true,
					'bgColor': '#bcc7ce'
				});
				elm.val(cval + '%');
			});
			
			\$(".sparkline").each(function () {
				var \$this = \$(this);
				\$this.sparkline('html', \$this.data());
			});	
		});
	</script>
EOF
;

# Framework::Row
&Header::openbigbox('100%', 'left');

# Framework::Box
#&Header::openbox('100%', 'center', $Lang::tr{'Network'});

print <<EOF
<div class="row">
	<div class="col-md-12">
		<div class="col-xs-7">
			<h2 class="anthracite">Dashboard</h2>
			
			<div class="col-xs-12">
				<div class="progress-group mobile">
                    <span class="progress-text">CPU</span>
                    <span class="progress-number progress-cpu"><b>0%</b></span>

                    <div class="progress sm">
                      <div class="progress-bar progress-bar-green progress-bar-cpu" style="width: 80%"></div>
                    </div>
                </div>
				<div class="progress-group mobile">
                    <span class="progress-text">Memory</span>
                    <span class="progress-number progress-memory"><b>0%</b></span>

                    <div class="progress sm">
                      <div class="progress-bar progress-bar-aqua progress-bar-memory"></div>
                    </div>
                </div>
				<div class="progress-group mobile">
                    <span class="progress-text">Disk</span>
                    <span class="progress-number progress-disk"><b>0%</b></span>

                    <div class="progress sm">
                      <div class="progress-bar progress-bar-yellow progress-bar-disk"></div>
                    </div>
                </div>
			</div>
			
		</div>
		<div class="col-xs-5 dials pull-right">
			<!-- metrics and clocks -->
			<div class="text-center dashboard-dial float-right">
				  <input type="text" class="dial" id="disk" data-readonly="true" value="0" data-fgColor="#f19425">

				  <div class="dial-label">Disk</div>
			</div>
			<div class="text-center dashboard-dial float-right">
				  <input type="text" class="dial" id="memory" data-readonly="true" value="0" data-fgColor="#10b8cc">

				  <div class="dial-label">Memory</div>
			</div>			
			<div class="text-center dashboard-dial float-right">
				  <input type="text" class="dial" id="cpu" data-readonly="true" value="0" data-fgColor="#8dd4cd">

				  <div class="dial-label">CPU</div>
			</div>			
		</div>
	</div>
</div>
EOF
;

# Framework::Box
&Header::openbox('100%', 'center', 'Firewall Statistics', 4, 'success', 'fas fa-server');
print <<EOF
			<div class="row">
				<div class="col-md-12">
					<div class="sparkline" data-type="bar" data-width="97%" data-height="200px" data-bar-Width="14" data-bar-Spacing="7" data-bar-Color="#f39c12">
						6,4,8, 9, 10, 5, 13, 18, 21, 7, 9
					</div>
					<!-- /box-content -->
				</div>
			</div>
			<!-- /.row -->
EOF
;
&Header::closebox();

&Header::openbox('100%', 'center', 'Network', 4, 'danger', 'fas fa-cloud');

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

print <<EOF
              <div class="row">
                <div class="col-md-12">
                  <table class="table borderless anthracite">
					<tr>
						<td class="red">Internet</td>
						<td>$ipaddr</td>
					</tr>
					<tr>
						<td>Gateway</td>
						<td>$gateway</td>
					</tr>
					<tr>
						<td>DNS Servers</td>
						<td>$dns_servers</td>
					</tr>
					<tr>
						<td>Connected</td>
						<td><span class='up'></span></td>
					</tr>
					<tr>
						<td colspan="2"><hr/></td>
					</tr>
					<tr>
						<td class="light-green">LAN</td>
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
						<td colspan="2"><hr/></td>
					</tr>
					<tr>
						<td class="teal">IPSec</td>
						<td>$ipsecip ($ipsec_state)</td>
					</tr>
					<tr>
						<td class="teal">OpenVPN</td>
						<td>$openvpnip ($openvpn_state)</td>
					</tr>
				  </table>
                </div>
                <!-- /.col -->
              </div>
              <!-- /.row -->
EOF
;
&Header::closebox();

# Framework::Box
&Header::openbox('100%', 'center', 'Wireless', 4, 'info', 'fas fa-wifi', '<div class="box-tools pull-right"><input type="checkbox" id="toggle-wifi" name="toggle-wifi" value="1" class="lcs_check" autocomplete="off" /></div>');

#$wlanapsettings{'DRIVER'}
my $ssid_broadcast = '';
my $frequency = '2.4 GHz';

if($wlanapsettings{'HIDESSID'} eq 'on') { $ssid_broadcast = ' (hidden)' };
if($wlanapsettings{'HW_MODE'} eq 'an' || $wlanapsettings{'HW_MODE'} eq 'ac') { $frequency = 'Dual band' }

print <<EOF	
              <div class="row">
                <div class="col-md-12">
                  <table class="table borderless anthracite">
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
						<td colspan="2"><hr/></td>
					</tr>
					<tr>
						<td>Guest Access</td>
						<td>
							<input type="checkbox" id="toggle-guest-wifi" name="toggle-guest-wifi" value="1" class="lcs_check" autocomplete="off" />
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
				  </table>
                </div>
                <!-- /.col -->
              </div>
              <!-- /.row -->
EOF
;

&Header::closebox();
&Header::closebigbox();
&Header::closepage();