#!/usr/bin/perl
###############################################################################
#                                                                             #
# IPFire.org - A linux based firewall                                         #
# Copyright (C) 2007  Michael Tremer & Christian Schmidt                      #
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
#                                                                             #
# Theme file for IPfire (based on ipfire theme)                               #
# Author kay-michael köhler kmk <michael@koehler.tk>                          #
#                                                                             #
# Version 1.0	March, 6th 2013                                               #
###############################################################################
#                                                                             #
# Modyfied theme by a.marx@ipfire.org January 2014                            #
#                                                                             #
# Cleanup code, deleted unused code and rewrote the rest to get a new working #
# IPFire default theme.                                                       #
###############################################################################

require "${General::swroot}/lang.pl";

###############################################################################
#
# print menu html elements for submenu entries
# @param submenu entries
sub showsubmenu() {
	my $submenus = shift;
	my $active = '';
	
	print '<ul class="treeview-menu">';
	foreach my $item (sort keys %$submenus) {
		$link = getlink($submenus->{$item});
		next if (!is_menu_visible($link) or $link eq '');
		
		if($link eq @URI[0]) { $active = ' class="active"'; };
		#print "<!-- $link == @URI[0] -->";

		my $subsubmenus = $submenus->{$item}->{'subMenu'};

		print '<li'.$active.'><a href="'.$link.'"><i class="far fa-circle"></i> '.$submenus->{$item}->{'caption'}.'</a>';
		$active = '';

		&showsubmenu($subsubmenus) if ($subsubmenus);
		print '</li>';
	}
	print '</ul>';
}

###############################################################################
#
# print menu html elements
sub showmenu() {
	foreach my $k1 ( sort keys %$menu ) {
		$link = getlink($menu->{$k1});
		next if (!is_menu_visible($link) or $link eq '');
		
		#if($link eq @URI[0]) { print "<!-- $k1 | $link | @URI -->"; };
		#print '<li class="treeview"><a href="#"><i class="fa fa-wrench fa-fw"></i> <span>'.$menu->{$k1}->{'caption'}.'</span></a>';
		
		if($menu->{$k1}->{'caption'} eq 'System') {
			print '<li class="treeview"><a href="#"><i class="fas fa-wrench fa-fw"></i> <span>'.$menu->{$k1}->{'caption'}.'</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a>';
		}
		elsif($menu->{$k1}->{'caption'} eq 'Status') {
			print '<li class="treeview"><a href="#"><i class="fas fa-chart-bar fa-fw"></i> <span>'.$menu->{$k1}->{'caption'}.'</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a>';
		}
		elsif($menu->{$k1}->{'caption'} eq 'Network') {
			print '<li class="treeview"><a href="#"><i class="fas fa-ethernet fa-fw"></i> <span>'.$menu->{$k1}->{'caption'}.'</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a>';
		}
		elsif($menu->{$k1}->{'caption'} eq 'Services') {
			print '<li class="treeview"><a href="#"><i class="fab fa-servicestack fa-fw"></i> <span>'.$menu->{$k1}->{'caption'}.'</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a>';
		}
		elsif($menu->{$k1}->{'caption'} eq 'Firewall') {
			print '<li class="treeview"><a href="#"><i class="fas fa-shield-alt fa-fw"></i> <span>'.$menu->{$k1}->{'caption'}.'</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a>';
		}
		elsif($menu->{$k1}->{'caption'} eq 'IPFire') {
			print '<li class="treeview"><a href="#"><i class="fab fa-linux fa-fw"></i> <span>'.$menu->{$k1}->{'caption'}.'</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a>';
		}
		elsif($menu->{$k1}->{'caption'} eq 'Logs') {
			print '<li class="treeview"><a href="#"><i class="fas fa-file-medical-alt fa-fw"></i> <span>'.$menu->{$k1}->{'caption'}.'</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a>';
		}
		else {
			print '<li class="treeview"><a href="#"><i class="fas fa-cogs fa-fw"></i> <span>'.$menu->{$k1}->{'caption'}.'</span></a>';
		}
			
		my $submenus = $menu->{$k1}->{'subMenu'};
		&showsubmenu($submenus) if ($submenus);
		print "</li>";
	}
}

###############################################################################
#
# print page opening html layout
# @param page title
# @param boh
# @param extra html code for html head section
# @param suppress menu option, can be numeric 1 or nothing.
#		 menu will be suppressed if param is 1
sub openpage {
	my $title = shift;
	my $boh = shift;
	my $extrahead = shift;
	my $suppressMenu = shift;
	my @tmp = split(/\./, basename($0));
	my $scriptName = @tmp[0];

	@URI=split ('\?',  $ENV{'REQUEST_URI'} );
	&General::readhash("${swroot}/main/settings", \%settings);
	&genmenu();

	my $headline = "IPFire";
	if (($settings{'WINDOWWITHHOSTNAME'} eq 'on') || ($settings{'WINDOWWITHHOSTNAME'} eq '')) {
		$headline =  "$settings{'HOSTNAME'}.$settings{'DOMAINNAME'}";
	}

	my @stylesheets = ("bootstrap.min.css");
	push(@stylesheets, "AdminLTE.min.css");
	push(@stylesheets, "skin-red.min.css");
	push(@stylesheets, "font-awesome.all.min.css");
	push(@stylesheets, "ionicons.min.css");
	push(@stylesheets, "lc_switch.css");
	push(@stylesheets, "overrides.css");

print <<END;
<!DOCTYPE html>
<html>
	<head>
	<title>$headline - $title</title>
	$extrahead
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
	<meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
	<link rel="shortcut icon" href="/favicon.ico" />
	
	<script type="text/javascript" src="/themes/dashboard/include/js/jquery.min.js"></script>

	<script type="text/javascript" src="/themes/dashboard/include/js/refreshSysInfo.js"></script>
	<script type="text/javascript" src="/themes/dashboard/include/js/overrideClasses.js"></script>	

	<script type="text/javascript">
		function swapVisibility(id) {
			\$('#' + id).toggle();
		}
	</script>
END

	foreach my $stylesheet (@stylesheets) {
		print "<link href=\"/themes/dashboard/include/css/$stylesheet\" rel=\"stylesheet\" type=\"text/css\" />\n";
	}

if ($settings{'SPEED'} ne 'off') {
print <<END
	<script type="text/javascript" src="/themes/dashboard/include/js/refreshInetInfo.js"></script>
END
;
}

if($title && $title eq 'Dashboard') { $title = ''; }

print <<END
	</head>
	<body class="hold-transition skin-red sidebar-mini">
	<div class="wrapper">
		<header class="main-header">
	
			<!-- Logo -->
			<a href="#" class="logo">
				<span class="logo-mini">IP<b>F</b></span>
				<span class="logo-lg">IP<b>Fire</b></span>
			</a>	
			
			<!-- Navigation -->
			<nav class="navbar navbar-static-top">
			<a href="#" class="sidebar-toggle" data-toggle="push-menu" role="button">
				<span class="fas fa-bars"></span>
				<span class="sr-only">Toggle navigation</span>
			</a>			

END
;
	if ($settings{'WINDOWWITHHOSTNAME'} ne 'off') {
		print "<a class=\"navbar-brand\" href=\"#\">$settings{'HOSTNAME'}.$settings{'DOMAINNAME'}</a>";
	} else {
		print "<a class=\"navbar-brand\" href=\"#\">IP<span class=\"bold\">FIRE</span></a>";
	}

print <<END
		<div class="navbar-custom-menu">
		<ul class="nav navbar-nav">
END
;

if ($settings{'SPEED'} ne 'off') {
	print <<EOF;
	
		<li class="txrx">
			<i class="fas fa-caret-down"></i>  <span id='rx_kbs'>--.-- bit/s</span>			
		</li>
		<li class="txrx">
			<i class="fas fa-caret-up"></i> <span id='tx_kbs'>--.-- bit/s</span>
		</li>
EOF
}

my $activeClass = '';
if(@URI[0] eq '/cgi-bin/dashboard.cgi') { $activeClass = ' active'; }
print <<END
				<!-- Notifications Menu -->
				<li class="dropdown notifications-menu">
					<!-- Menu toggle button -->
					<a href="#" class="dropdown-toggle" data-toggle="dropdown">
						<i class="far fa-bell"></i>
						<span class="label label-warning">10</span>
					</a>
					<ul class="dropdown-menu">
						<li class="header">You have 10 notifications</li>
						<li>
							<!-- Inner Menu: contains the notifications -->
							<ul class="menu">
								<li>
									<!-- start notification -->
									<a href="#">
										<i class="fa fa-users text-aqua"></i> 5 new members joined today
									</a>
								</li><!-- end notification -->
							</ul>
						</li>
						<li class="footer"><a href="#">View all</a></li>
					</ul>
				</li>
			</ul>			
			</div><!-- navbar-custom-menu -->
		</nav>
	</header>
	
  <aside class="main-sidebar">
    <section class="sidebar">
		<ul class="sidebar-menu" data-widget="tree">
			<li class="header">MAIN NAVIGATION</li>
			<li class="branch$activeClass">
				<a href="/cgi-bin/dashboard.cgi">
					<i class="fas fa-fire fa-fw"></i> <span>Dashboard</span>
				</a>
			</li>
END
;

&showmenu() if ($suppressMenu != 1);

print <<END			
				</ul>
			</section> <!-- /sidebar -->
		</aside> <!-- /navbar-collapse -->
END
;

print <<END
	<div class="content-wrapper">
		<section class="content-header">
			<h1 class="page-header">$title</h1>
		</section>
		<section class="content">
			<div class="row">
			<!-- content -->
END
;
}

###############################################################################
#
# print page opening html layout without menu
# @param page title
# @param boh
# @param extra html code for html head section
sub openpagewithoutmenu {
	openpage(shift,shift,shift,1);
	return;
}

###############################################################################
#
# print page closing html layout

sub closepage () {

	open(FILE, "</etc/system-release");
	my $system_release = <FILE>;
	$system_release =~ s/core/Core Update /;
	close(FILE);

print <<END
		</div> <!-- row -->
	</section> <!-- page-wrapper -->

	</div> <!-- content-wrapper --> 
	<footer class="main-footer">
		<div class="pull-right">
			<b>$system_release</b> | Up time: <span class='up'>--</span> | Current time: <span id='time'></span>
		</div>
		<a href="https://www.ipfire.org/" target="_blank"><strong>IPFire.org</strong></a> &bull;
		<a href="https://www.ipfire.org/donate" target="_blank">$Lang::tr{'support donation'}</a>
	</footer>
	
	</div> <!-- wrapper -->
	
<script type="text/javascript" src="/themes/dashboard/include/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/themes/dashboard/include/js/adminlte.js"></script>
<script type="text/javascript" src="/themes/dashboard/include/js/jquery.knob.min.js"></script>
	
</body>
</html>
END
;
}

###############################################################################
#
# print big box opening html layout
sub openbigbox {
}

###############################################################################
#
# print big box closing html layout
sub closebigbox {
}

###############################################################################
#
# print box opening html layout
# @param page width
# @param page align
# @param page caption
sub openbox {
	$width = $_[0];
	$align = $_[1];
	$caption = $_[2];
	$size = $_[3];
	$type = $_[4];
	$icon = $_[5];
	$tools = $_[6];

	if($size)
	{
		print "<div class='col-md-$size'>\n"
	}
	else
	{
		if($align eq 'center') {
			print "<div class='col-md-12'>\n"
		}
		else {
			print "<div class='col-md-12'>\n";
		}
	}

	if($type)
	{
		print "<div class='box box-$type'>";
	}
	else
	{
		print "<div class='box'>";
	}
	
	if ($caption) {
		print "<div class='box-header with-border'>";
		if ($icon) { print "<i class='$icon'></i>"; }		
		print "<h3 class='box-title'>$caption</h3>";
		if($tools) { print $tools; }
		print "</div>\n";
	}
	
	print "<div class='box-body'>";
}

###############################################################################
#
# print box closing html layout
sub closebox {
	print "</div></div></div>";
}

1;
