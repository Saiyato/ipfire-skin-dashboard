# Dashboard plugin - Notifications
#!/usr/bin/perl
package Notifications;

use DBI;

my $notifications = '';
my $db_error = '';
my $driver   = "SQLite";
my $database = "/srv/web/ipfire/html/themes/dashboard/include/database/dashboard.db";
my $dsn = "DBI:$driver:dbname=$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
   or die $DBI::errstr;

my $stmt = qq(SELECT ID, Subject, Description, URL, Icon, Read FROM Notifications;);
my $sth = $dbh->prepare( $stmt );
my $rv = $sth->execute() or die $DBI::errstr;

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
$dbh->disconnect();

sub show
{
	my $widget_id = 3;
	return "
		<div class='box box-success' id='wid_$widget_id'>
			<div class='box-header with-border ui-sortable-handle'>
				<i class='far fa-envelope'></i>
				<h3 class='box-title'>Notifications</h3>
			</div>
			<div class='box-body'>
				<div class='col-md-12'>
					<div class='box-body'>
						<ul class='products-list product-list-in-box'>
							$notifications
						</ul>
					</div>
				</div>
			</div>
		</div>
	"
	;
}

1;