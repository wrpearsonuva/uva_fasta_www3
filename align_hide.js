var default_show ='inline';
function set_block() {
   if (window.location.search) {
      default_show ='inline';
   }
   else default_show ='inline';
}

function show_hide(id) {
   var e = document.getElementById(id);
   if(e.style.display != 'none') { e.style.display = 'none';}
   else {e.style.display = default_show;}
}

function show_hide_class(className) {
    var elements = document.getElementsByClassName(className),
    n = elements.length;
    for (var i = 0; i < n; i++) {
        var e = elements[i];

        if (e.style.display != 'none') {
	        e.style.display = 'none';
	} else {
	  e.style.display = 'inline';
	}
    }
}
