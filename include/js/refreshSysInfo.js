/* refreshUptimeInfo.js
* functions for retrieving status information via jQuery
* Visit http://www.ipfire.org/
*/

$(document).ready(function(){
   refreshSysInfo();
});

function refreshSysInfo() {
	$.ajax({
		url: '/cgi-bin/sysinfo.cgi',
		success: function(xml) {

			var up = $("up", xml).text();
			var time = $("time", xml).text();
			var user = $("user", xml).text();
			var load = $("load_a", xml).text() + ", " + $("load_b", xml).text() + ", " + $("load_c", xml).text();
			
			var cpu = Math.round($("cpu_usage", xml).text());
			var memory = Math.round($("memory_usage", xml).text());
			var disk = $("disk_usage", xml).text();

			$(".up").each(function () { 
				$(this).text(up);
			});
			$("#time").text(time);
			$("#user").text(user);
			$("#load").text(load);

			$("#cpu").attr('value', cpu);
			$('.progress-bar-cpu').attr('style', 'width: ' + cpu + '%');
			$('.progress-cpu').text(cpu + '%');
			$("#memory").attr('value', memory);
			$('.progress-bar-memory').attr('style', 'width: ' + memory + '%');
			$('.progress-memory').text(memory + '%');
			$("#disk").attr('value', disk);
			$('.progress-bar-disk').attr('style', 'width: ' + disk);
			$('.progress-disk').text(disk);
			
			$('#cpu').val(cpu + '%').trigger('change');
			$('#memory').val(memory + '%').trigger('change');
			$('#disk').val(disk).trigger('change');
			
		}
	});

	window.setTimeout("refreshSysInfo()", 1000);
}