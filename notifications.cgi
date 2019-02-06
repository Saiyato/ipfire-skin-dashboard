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
use warnings;
use CGI qw/:standard/;
use CGI::Carp 'fatalsToBrowser';
use DBI;

my %cgiparams = ();
my $operation = '';
my $id = 0;
my $new_status = 1;
my $timestamp = '';
my $subject = '';
my $msg = '';
my $url = '';
my $icon = '';
my $result = '';

sub validateTimeStamp
{
	my $date = shift;
	if( $date =~ /^(19|2\d)\d\d([- \/.])(0[1-9]|1[012])\2(0[1-9]|[12][0-9]|3[01])T(0[0-9]|1[0-9]|2[0-4]):([0-5][0-9]):([0-5][0-9])$/ ) { return $date; }
	else { return '2000-01-01T00:00:00'; }
}

# Parse GET parameters
if ($ENV{'QUERY_STRING'})
{
	my @temp = split(',',$ENV{'QUERY_STRING'});
	$operation = $temp[0];
	
	if ($operation eq 'view')
	{
		$timestamp = validateTimeStamp($temp[1]); # yyyyMMddTHH:mm:ss
		$subject = CGI::unescape($temp[2]);
		$msg = CGI::unescape($temp[3]);
		$url = $temp[4];
		$icon = CGI::unescape($temp[5]);
	}
	elsif ($operation eq 'insert')
	{
		$timestamp = validateTimeStamp($temp[1]); # yyyyMMddTHH:mm:ss
		$subject = CGI::unescape($temp[2]);
		$msg = CGI::unescape($temp[3]);
		$url = $temp[4];
		$icon = CGI::unescape($temp[5]);
	}
	elsif ($operation eq 'update')
	{
		$id = $temp[1];
		if(defined $temp[2]) { $new_status = $temp[2]; }
		
		$timestamp = $new_status;
	}
	elsif ($operation eq 'sort')
	{		
		my $db_error = '';
		my $driver   = "SQLite";
		my $database = "/srv/web/ipfire/html/themes/dashboard/include/database/dashboard.db";
		my $dsn = "DBI:$driver:dbname=$database";
		my $userid = "";
		my $password = "";
		my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
			or die $DBI::errstr;
		
		my $stmt = ();
		my $rv = ();
		my $increment = 0;		
		my $tmp = '';
		
		# Left column
		my @wids = split('\|', $temp[2]);
		foreach my $wid (@wids) {
			if($wid ne '')
			{
				my $f_wid = $wid;
				$f_wid =~ s/wid\[\]=//g;
				
				$stmt = "UPDATE Widgets SET SortColumn = ?, SortOrder = ? WHERE ID = ?";
				$rv = $dbh->do( $stmt, undef, 'left', $increment, $f_wid ) or die $DBI::errstr;
				
				if($rv < 0) {
					$db_error = $DBI::errstr;
					$result = 'failed';
				}				
				++$increment;
			}
		}
		
		# Middle column
		$increment = 0;
		my @wids = split('\|', $temp[4]);
		foreach my $wid (@wids) {
			if($wid ne '')
			{
				my $f_wid = $wid;
				$f_wid =~ s/wid\[\]=//g;
				
				$stmt = "UPDATE Widgets SET SortColumn = ?, SortOrder = ? WHERE ID = ?";
				$rv = $dbh->do( $stmt, undef, 'middle', $increment, $f_wid ) or die $DBI::errstr;
				
				if($rv < 0) {
					$db_error = $DBI::errstr;
					$result = 'failed';
				}
				++$increment;
			}
		}
		
		# Right column
		$increment = 0;
		my @wids = split('\|', $temp[6]);
		foreach my $wid (@wids) {
			if($wid ne '')
			{
				my $f_wid = $wid;
				$f_wid =~ s/wid\[\]=//g;
				
				$stmt = "UPDATE Widgets SET SortColumn = ?, SortOrder = ? WHERE ID = ?";
				$rv = $dbh->do( $stmt, undef, 'right', $increment, $f_wid ) or die $DBI::errstr;
				
				if($rv < 0) {
					$db_error = $DBI::errstr;
					$result = 'failed';
				}
				++$increment;
			}
		}
		
		$dbh->disconnect;
		if($rv == 0) { $result = 'success'; }
	}
	elsif ($operation eq 'test')
	{
		$id = $temp[1];
		$timestamp = $id;
	}
}

# Parse POST parameters
if ($cgiparams{'ACTION'} eq 'notify')
{
	$timestamp = validateTimeStamp($cgiparams{'timestamp'});
	$subject = $cgiparams{'subject'};
	$msg = $cgiparams{'msg'};
	$url = $cgiparams{'url'};
	$icon = $cgiparams{'icon'};
}

if($operation eq 'insert')
{
	my $db_error = '';
	my $driver   = "SQLite";
	my $database = "/srv/web/ipfire/html/themes/dashboard/include/database/dashboard.db";
	my $dsn = "DBI:$driver:dbname=$database";
	my $userid = "";
	my $password = "";
	my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
		or die $DBI::errstr;
	
	my $stmt = "INSERT INTO Notifications (TimeStamp, Subject, Description, URL, Icon, Read) VALUES (?, ?, ?, ?, ?, 0)";
	my $rv = $dbh->do( $stmt, undef, $timestamp, $subject, $msg, $url, $icon ) or die $DBI::errstr;

	if($rv < 0) {
	   $db_error = $DBI::errstr;
	   $result = 'failed';
	}
	
	$dbh->disconnect;
	$result = 'success';
}

if($operation eq 'update')
{
	my $db_error = '';
	my $driver   = "SQLite";
	my $database = "/srv/web/ipfire/html/themes/dashboard/include/database/dashboard.db";
	my $dsn = "DBI:$driver:dbname=$database";
	my $userid = "";
	my $password = "";
	my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
		or die $DBI::errstr;
	
	my $stmt = "UPDATE Notifications SET Read = ? WHERE ID = ?;";
	my $rv = $dbh->do( $stmt, undef, $new_status, $id ) or die $DBI::errstr;

	if($rv < 0) {
	   $db_error = $DBI::errstr;
	   $result = 'failed';
	}
	
	$dbh->disconnect;
	$result = 'success';
}

print "pragma: no-cache\n";
print "Content-type: text/xml\n\n";
print "<?xml version=\"1.0\"?>\n";
print <<END
<notification>
 <operation>$operation</operation>
 <timestamp>$timestamp</timestamp>
 <subject>$subject</subject>
 <msg>$msg</msg>
 <url>$url</url>
 <icon>$icon</icon>
 <result>$result</result>
</notification>
END
;