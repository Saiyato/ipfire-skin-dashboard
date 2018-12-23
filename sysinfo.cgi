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

use strict;
use POSIX qw(strftime);

# Up time

my $uptime = ();
my $uptime = qx(/usr/bin/uptime);

my $up = ();
my $time = ();
my $user = ();
my $load = ();

$uptime =~ /\s(\d+:\d+:\d+)\sup\s(.+?),.*?(\d+)\suser.*?,.*?(\d+\.\d+),\s(\d+\.\d+),\s(\d+\.\d+)/;

my $time = strftime "%Y-%m-%e %H:%M:%S %Z (%z)", localtime;
my $up = $2;
my $user = $3;
my $load_a = $4;
my $load_b = $5;
my $load_c = $6;

# CPU Info

my $cpu_model = ();
my $cpu_model = qx(/usr/bin/lscpu | grep Model | cut -d ':' -f 2);
$cpu_model =~ s/^\s+|\s+$//g;

my $cpu_usage = ();
my $cpu_usage = qx(ps -A -o pcpu | tail -n+2 | paste -sd+ | bc);
$cpu_usage =~ s/^\s+|\s+$//g;

my $memory_usage = ();
my $memory_usage = qx(free | grep Mem | awk '{print \$3/\$2 * 100.0}');
$memory_usage =~ s/^\s+|\s+$//g;

my $disk_usage = ();
my $disk_usage = qx(df -h | grep '/\$' | awk '{print \$5}');
$disk_usage =~ s/^\s+|\s+$//g;

print "pragma: no-cache\n";
print "Content-type: text/xml\n\n";
print "<?xml version=\"1.0\"?>\n";
print <<END
<sysinfo>
 <time>$time</time>
 <up>$up</up>
 <user>$user</user>
 <load_a>$load_a</load_a>
 <load_b>$load_b</load_b>
 <load_c>$load_c</load_c>
 <cpu_model>$cpu_model</cpu_model>
 <cpu_usage>$cpu_usage</cpu_usage>
 <memory_usage>$memory_usage</memory_usage>
 <disk_usage>$disk_usage</disk_usage>
</sysinfo>
END
;