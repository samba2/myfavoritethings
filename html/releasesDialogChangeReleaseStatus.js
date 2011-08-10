$('#changeReleaseStatus').click(function () {
    //prepare
    hideElements();
    setupReleaseStatusButton();
    // display button
    $( "#dialogChangeReleaseStatus" ).dialog({ minHeight: 100 });
    
    // click functions
    $('#radioSetOfflineNow').click(function () {
        // reset datePicker if selected before
        $('#divDatePicker').hide("normal");
        $('#txtDatePicker').val("");
        $('#buttonOK').removeAttr('disabled');  
     });
     
    $('#radioSetOfflineLater').click(function () {
        // reset "Save" to disabled if coming from "radioSetOfflineNow"
        $('#buttonOK').attr('disabled', true);
        $('#divDatePicker').show("normal");
        $('#txtDatePicker').datepicker({
            minDate: 0,
            onSelect: function() { 
                enableOKButton();
            }
        });
    });
    
    $('#buttonOK').click(function () {
        var date = "";
        
        if ($('#radioSetOfflineLater')) {
            // set posted value of radio button value to
            // eg 01242011
            date = $('#txtDatePicker').val();
            date = date.replace(/\//g,"");
            $('#radioSetOfflineLater').val(date);
        }
    });

    // helper functions
    function hideElements () {
        $('#buttonOK').attr('disabled', true);
        $('#divDatePicker').hide();
        $('#paraSetOffline').hide();
        $('#paraNoChangeFileMissing').hide();
        $('#paraSetOnline').hide();
        $('#paraRemoveExpiry').hide();
        $('#divInputsSetOffline').hide();
    }

    function setupReleaseStatusButton() {
        var status = $('#releaseStatus').text();
        
        if ( status === "Online" ) {
            $('#paraSetOffline').show();
            $('#divInputsSetOffline').show();
        }
        else if ( status === "Offline" || status === "Expired" ) {
            $('#paraSetOnline').show();
            enableOKButton();
        }
        else if ( statusIsExpiryDate(status) ) {
            $('#paraRemoveExpiry').show(); 
            enableOKButton();   
        }
        else if ( status === "File missing" ) {
             $('#paraNoChangeFileMissing').show();
             $('#buttonOK').hide();
        }
    }

    function statusIsExpiryDate(status) {
        if ( status.indexOf("Expires at") != -1 ) {
            return true;
        }
        return false;
    }
    
    function enableOKButton() {
        $('#buttonOK').removeAttr('disabled');
    }
    
})
