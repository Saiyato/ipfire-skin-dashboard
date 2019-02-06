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

BEGIN { push ( @INC, "/srv/web/ipfire/html/themes/dashboard/include/widgets/" ); }

#use strict;
use Time::Local;
use CGI qw/:standard/;
use CGI::Carp 'fatalsToBrowser';
use warnings;
use DBI;

use Module::Load;
my $dir = '/srv/web/ipfire/html/themes/dashboard/include/widgets/';
opendir(DIR, $dir) or die $!;
while (my $file = readdir(DIR)) {
	# Use a regular expression to ignore files beginning with a period or not ending with .pm
	next if ($file =~ m/^\./);
	next if ($file !~ m/\.pm$/);
	$file =~ s/.pm//g;
	load $file;
}
closedir(DIR);

my $notifications = '';
my @left = ();
my @middle = ();
my @right = ();
my $db_error = '';
my $driver   = "SQLite";
my $database = "/srv/web/ipfire/html/themes/dashboard/include/database/dashboard.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
   or die $DBI::errstr;

my $stmt = qq(SELECT ID, Subject, Description, URL, Icon, Read FROM Notifications;);
my $stmt2 = qq(SELECT WidgetName, SortColumn FROM Widgets ORDER BY SortColumn, SortOrder;);
my $sth = $dbh->prepare( $stmt );
my $sth2 = $dbh->prepare( $stmt2 );
my $rv = $sth->execute() or die $DBI::errstr;
my $rv2 = $sth2->execute() or die $DBI::errstr;

if($rv < 0) {
   $db_error = $DBI::errstr;
}

while(my @row = $sth->fetchrow_array()) {
	my $icon = '';
	if (! defined $row[4]) { $icon = 'fa fas fa-bell'; }
	else { $icon = $row[4]; }
	my $read = '';
	my $mark_as_read = " <a href='dashboard.cgi' class='label label-success pull-right' onClick='readNotification($row[0])'>Mark as read</a>";
	if ($row[5] eq 1) { $read = ' strikethrough'; $mark_as_read = ''; }
	$notifications = $notifications . "<li id='$row[0]' class='item$read'><div class='product-img'><i class='fa-big $icon'></i></div><div class='product-info'><span class='product-title'>$row[1]$mark_as_read</span><span class='product-description'>$row[2]</span></div></li>";
}
while(my @row = $sth2->fetchrow_array()) {
	
	if ($row[1] eq 'left') { push (@left, $row[0]); }
	elsif ($row[1] eq 'middle') { push (@middle, $row[0]); }
	elsif ($row[1] eq 'right') { push (@right, $row[0]); }
}
$dbh->disconnect();
   
require '/var/ipfire/general-functions.pl';
require "${General::swroot}/lang.pl";
require "${General::swroot}/header.pl";

my $settings = "/srv/web/ipfire/html/themes/dashboard/include/settings";
my $errormessage = '';

&General::readhash("/srv/web/ipfire/html/themes/dashboard/include/settings", \%dashboardsettings);

# ACTIONS
if ($cgiparams{'ACTION'} eq "$Lang::tr{'save'}")
{
  # Save button in config panel

  my %new_settings = ();
  $new_settings{'CPUINFO'} = $cgiparams{'CPUINFO'};
  $new_settings{'DNSINFO'} = $cgiparams{'DNSINFO'};
  $new_settings{'NETWORKINFO'} = $cgiparams{'NETWORKINFO'};
  $new_settings{'WIRELESSINFO'} = $cgiparams{'WIRELESSINFO'};

  General::writehash($settings, \%new_settings);

  if(!$errormessage)
  {
      # Clear hashes
  }
  else
  {
    $cgiparams{'update'}='on';
  }
  %settings = %new_settings;
}

&showdash;

sub showdash
{

&Header::showhttpheaders();
&Header::openpage('Dashboard', 1, '');

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
			
			// Make the dashboard widgets sortable Using jquery UI
			\$('.connectedSortable').sortable({
				placeholder         : 'sort-highlight',
				connectWith         : '.connectedSortable',
				handle              : '.box-header, .nav-tabs',
				forcePlaceholderSize: true,
				zIndex              : 999999,
				update				: function () {
					var data = {
						left: \$("#left-column").sortable('serialize'),
						middle: \$("#middle-column").sortable('serialize'),
						right: \$("#right-column").sortable('serialize')
					};
					var url = '/cgi-bin/notifications.cgi?sort,c1,' + data.left.toString().replace(/&/g, '|') + ',c2,' + data.middle.toString().replace(/&/g, '|') + ',c3,' + data.right.toString().replace(/&/g, '|');
					//alert('Sorted data: ' + url);
					\$.get(url, function(data) {});
				}
			});
			\$('.connectedSortableSortable .box-header, .connectedSortable .nav-tabs-custom').css('cursor', 'move');			
		});		
	</script>
EOF
;

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
<div class='row' id='sortable-content'>
EOF
;

# Framework::Column
&Header::openleftcolumn(3);

foreach (@left) { 
    print "$_"->show();
}

&Header::closeleftcolumn();

# Framework::Column
&Header::openmiddlecolumn(3);

foreach (@middle) { 
    print "$_"->show();
}

&Header::closemiddlecolumn();

# Framework::Column
&Header::openrightcolumn(6);

foreach (@right) { 
    print "$_"->show();
}

&Header::closerightcolumn();

print <<EOF
</div>
EOF
;

&Header::closepage();
}

0;