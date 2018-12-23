/* overrideClasses.js
* functions for overriding classes via jQuery
* Visit http://www.ipfire.org/
*/

$(document).ready(function(){	
	formatTables();
   
	$(function(){
		var $ppc = $('.progress-pie-chart'),
		percent = parseInt($ppc.data('percent')),
		deg = 360*percent/100;
		if (percent > 70) {
			$ppc.addClass('gt-70');
		}
		$('.ppc-progress-fill-cpu').css('transform','rotate('+ deg +'deg)');
		$('.ppc-progress-fill-memory').css('transform','rotate('+ deg +'deg)');
		$('.ppc-progress-fill-disk').css('transform','rotate('+ deg +'deg)');
		$('.ppc-percents span').html(percent+'%');
	});   
});

function formatTables() {
	
	var Selector = {
		table       : 'table',
		button      : 'button',
		submit		: '[type="submit"]',
		altBackup	: '[alt="Backup"]',
		altDelete	: '[alt="Delete"]',
		altDownload	: '[alt="download"]',
		altRestore	: '[alt="Restore"]',
		input       : 'input',
		imageType   : '[type="image"]',
		tbl		    : '.tbl',
		treeviewMenu: '.treeview-menu',
		open        : '.menu-open, .active',
		li          : 'li',
		data        : '[data-widget="tree"]',
		active      : '.active'
	};
	
	var ClassName = {
		sTable: 'table table-striped',
		hTable: 'table table-hover',
		buttonflat: 'btn btn-default btn-flat'
	};
	
	$(Selector.tbl, this.element).addClass(ClassName.sTable);
	$(Selector.tbl, this.element).removeClass('tbl');
	$(Selector.input + Selector.submit, this.element).addClass(ClassName.buttonflat);
	//$(Selector.tbl + Selector.active, this.element).addClass(ClassName.open);
	
	$(Selector.input + Selector.imageType + Selector.altDownload, this.element).addClass("hidden");
	$(Selector.input + Selector.imageType + Selector.altDelete, this.element).addClass("hidden");
	$(Selector.input + Selector.imageType + Selector.altBackup, this.element).addClass("hidden");
	$(Selector.input + Selector.imageType + Selector.altRestore, this.element).addClass("hidden");
	$("<button type='submit' class='unbutton' title='Download'><i class='ion ion-archive' alt='Download'></i></button>").insertBefore(Selector.input + Selector.imageType + Selector.altDownload, this.element);
	$("<button type='submit' class='unbutton' title='Delete'><i class='far fa-trash-alt' alt='Delete'></i></button>").insertBefore(Selector.input + Selector.imageType + Selector.altDelete, this.element);
	$("<button type='submit' class='unbutton' title='Backup'><i class='fas fa-plus' alt='Backup'></i></button>").insertBefore(Selector.input + Selector.imageType + Selector.altBackup, this.element);
	$("<button type='submit' class='unbutton' title='Restore'><i class='fas fa-undo' alt='Restore'></i></button>").insertBefore(Selector.input + Selector.imageType + Selector.altRestore, this.element);

}