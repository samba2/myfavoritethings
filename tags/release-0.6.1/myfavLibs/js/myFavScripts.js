
    var hash = {
     '.zip' : 1,
     '.ZIP' : 1,
    };

    function check_extension(filename,submitId) {
        var re = /\..+$/;
        var ext = filename.match(re);
        var submitEl = document.getElementById(submitId);
        if (hash[ext]) {
            submitEl.disabled = false;
            return true;
        } else {
            alert("Invalid archive format, please select another file. (Archive must have a 'zip' extension)");
            submitEl.disabled = true;

            return false;
        }
    }
    
    function check_extension2(filename,submitId) {
        var re = /\..+$/;
            var ext = filename.match(re);
            var submitEl = document.getElementById(submitId);

       submitEl.disabled = false;
           return true;
    }

        function showdiv(){
			if (document.getElementById) { // DOM3 = IE5, NS6
				document.getElementById('pleaseWait').style.display = 'block';
			}
			
		}	