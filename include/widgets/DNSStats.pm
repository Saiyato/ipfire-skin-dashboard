# Dashboard plugin - Notifications
#!/usr/bin/perl
package DNSStats;

use strict;
use warnings;
use CGI qw/:standard/;
use CGI::Carp 'fatalsToBrowser';

require '/var/ipfire/general-functions.pl';
require "${General::swroot}/lang.pl";
require "${General::swroot}/header.pl";

sub show
{
	my $widget_id = 5;
	my $retval = "
		<div class='box box-primary' id='wid_$widget_id'>
			<div class='box-header with-border ui-sortable-handle'>
				<i class='fas fa-globe large'></i>
				<h3 class='box-title'>DNS Statistics</h3>
			</div>
			<div class='box-body'>
				<div class='col-md-12'>
	";
	
	my $ctr = 0;
	my $ctr2 = 0;
	my ($totalQueries, $chartData, $chartLegend, $responseData);
	my @dns = `/usr/sbin/unbound-control stats_noreset`;
	foreach my $entry (@dns) {
		chomp($entry);
		
		my @colorshex = ("#f56954", "#00a65a", "#f39c12", "#00c0ef", "#3c8dbc", "#d2d6de", "#605ca8", "#d81b60", "#39cccc", "#001f3f");
		my @colors = ("red", "green", "yellow", "aqua", "light-blue", "gray", "purple", "maroon", "teal", "navy");
		
		# total.num.queries=499	
		if($entry =~ /total\.num\.queries=(\d+)/)
		{
			$totalQueries = $1;
		}
		
		# num.query.type.A=328		
		if($entry =~ /num\.query\.type\.([A-Z]+)=(\d+)/)
		{		
			$chartData = $chartData . "{value:" . $2 . ",label:'" . $1 . "',color:'". $colorshex[$ctr] ."'},";
			$chartLegend = $chartLegend . "<li><i class=\"far fa-circle text-". $colors[$ctr] ."\"></i> ". $1 ."</li>";
			$ctr++;		
		}
		
		# num.answer.rcode.NOERROR=382
		if($entry =~ /num\.answer\.rcode\.([A-Za-z]+)=(\d+)/)
		{
			$responseData = $responseData . "<div class=\"progress-group\"><span class=\"progress-text\">". $1 ."</span><span class=\"progress-number\"><b>". $2 ."</b>/".$totalQueries."</span><div class=\"progress sm\"><div class=\"progress-bar progress-bar-". $colors[$ctr2] ."\" style=\"width: ". $2/$totalQueries*100 ."%\"></div></div></div>";
			$ctr2++;
		}
	}
	
	$retval = $retval . "
			<div class=\"row\">				
				<div class=\"col-md-8\">
				<h4>Query types</h4>
				  <div class=\"row\">
					<div class=\"col-md-8\">
					  <div class=\"chart-responsive\">
						<canvas id=\"pieChart\" height=\"150\"></canvas>
					  </div>
					</div>
					<div class=\"col-md-4\">
					  <ul class=\"chart-legend clearfix\">
						". $chartLegend ."
					  </ul>
					</div>
				  </div>
			  </div>
			  <div class=\"col-md-4\">
				<h4>Responses</h4>
				". $responseData ."
			  </div>
		  </div>

<script>
  \$(function () {					
    //-------------
    //- PIE CHART -
    //-------------
    // Get context with jQuery - using jQuery's .get() method.
    var pieChartCanvas = \$('#pieChart').get(0).getContext('2d')
    var pieChart       = new Chart(pieChartCanvas)
    var PieData        = [
		".$chartData."
    ]
    var pieOptions     = {
      //Boolean - Whether we should show a stroke on each segment
      segmentShowStroke    : true,
      //String - The colour of each segment stroke
      segmentStrokeColor   : '#fff',
      //Number - The width of each segment stroke
      segmentStrokeWidth   : 2,
      //Number - The percentage of the chart that we cut out of the middle
      percentageInnerCutout: 50, // This is 0 for Pie charts
      //Number - Amount of animation steps
      animationSteps       : 100,
      //String - Animation easing effect
      animationEasing      : 'easeOutBounce',
      //Boolean - Whether we animate the rotation of the Doughnut
      animateRotate        : true,
      //Boolean - Whether we animate scaling the Doughnut from the centre
      animateScale         : false,
      //Boolean - whether to make the chart responsive to window resizing
      responsive           : true,
      // Boolean - whether to maintain the starting aspect ratio or not when responsive, if set to false, will take up entire container
      maintainAspectRatio  : true,
      //String - A legend template
      legendTemplate       : '<ul class=\"<%=name.toLowerCase()%>-legend\"><% for (var i=0; i<segments.length; i++){%><li><span style=\"background-color:<%=segments[i].fillColor%>\"></span><%if(segments[i].label){%><%=segments[i].label%><%}%></li><%}%></ul>'
    }
    //Create pie or douhnut chart
    // You can switch between pie and douhnut using the method below.
    pieChart.Doughnut(PieData, pieOptions)
  })
</script>	
					
				</div>
			</div>
		</div>";
		
	return $retval;
}


1;