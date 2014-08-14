$('#editVoucher').click(function () {
    $( "#dialogEditVoucher" ).dialog({ 
        width: 600,
        close: function () {
            cancelEditArea("Header");
            cancelEditArea("Footer");    
        }
    });
       
    // init remaining chars controls
    var minTextLength = 1,
        totalChars = { 'Header':250, 
                       'Footer':200},
    // save init data for reset via cancel or dialog-close                   
        initialText = { 'Header' : $('#textareaEditVoucherHeader').val(),
                        'Footer' : $('#textareaEditVoucherFooter').val()
                      }
        initialPrintStatus = { 'Header' : $('#buttonEditVoucherDisableHeader').is(':checked'),
                               'Footer' : $('#buttonEditVoucherDisableFooter').is(':checked')
                             };
          
    drawRemainingChars("Header");
    toggleArea("Header","");

    drawRemainingChars("Footer");
    toggleArea("Footer","");
    
     // update remaining chars when changing the textarea content
    $('#textareaEditVoucherHeader').keyup(function(){
        drawRemainingChars("Header");
    })    

    $('#textareaEditVoucherFooter').keyup(function(){
        drawRemainingChars("Footer");
    })    
    
    $('#buttonEditVoucherDisableHeader').click(function () {
        toggleArea("Header","normal");
        toggleSaveButton();
    })    
    
    $('#buttonEditVoucherDisableFooter').click(function () {
        toggleArea("Footer","normal");
        toggleSaveButton();
    })    
    
    $('#buttonEditVoucherReset').click(function () {
        resetAreaToDefault("Header");
        resetAreaToDefault("Footer");
        
        toggleSaveButton();
    })    
    
    $('#buttonEditVoucherCancel').click(function () {
        cancelEditArea("Header");
        cancelEditArea("Footer");
        
        $( "#dialogEditVoucher" ).dialog('close');        
    })
  
     function drawRemainingChars(area) {
        var idTextArea = "#textareaEditVoucher" + area,
            idSpanRemainingChars = "#spanEditVoucher" + area + "RemainingChars",
            idSpanTotalChars = "#spanEditVoucher" + area + "TotalChars",
            textAreaLength=$(idTextArea).val().length;

        $(idSpanTotalChars).text(totalChars[area]);
        $(idSpanRemainingChars).text(textAreaLength);
        
        toggleSaveButton();
    }
    
    // display area depending on checkbox "Don't print voucher header"
    function toggleArea(area, speed) {
        var idButtonDisableArea = "#buttonEditVoucherDisable" + area,
            idTextArea = "#textareaEditVoucher" + area,
            idSpanArea = "#spanEditVoucher" + area;

        if ( $(idButtonDisableArea).is(':checked')) {
            $(idTextArea).hide(speed);  
            $(idSpanArea).hide(speed);
        }
        else {
            $(idTextArea).show(speed);  
            $(idSpanArea).show(speed);
        }
    }

    function cancelEditArea(area) {
        var idTextArea = "#textareaEditVoucher" + area,
            idCheckBoxDisableArea = "#buttonEditVoucherDisable" + area;
        
        $(idTextArea).val(initialText[area]);
        drawRemainingChars(area);
     
        if ( initialPrintStatus[area] ) {
            $(idCheckBoxDisableArea).attr('checked', true);    
        } 
        else {
            $(idCheckBoxDisableArea).attr('checked', false);    
        }
        toggleArea(area, "normal");
    }
    
    function resetAreaToDefault(area) {
        var idDefaultAreaText = "#voucherGlobal" + area,
            idTextArea = "#textareaEditVoucher" + area,
            idCheckBoxDisableArea = "#buttonEditVoucherDisable" + area,
            defaultText;
        
        // reset area text to default text stored in hidden form field    
        defaultText = $(idDefaultAreaText).attr("value"); 
        $(idTextArea).val(defaultText);
        drawRemainingChars(area);
     
        // all areas are printed by default
        $(idCheckBoxDisableArea).attr('checked', false);    
        toggleArea(area, "normal");
    }

     function toggleSaveButton() {
         if ( ( areaIsValid('Header') || $('#buttonEditVoucherDisableHeader').is(':checked') ) 
              && 
              ( areaIsValid('Footer') || $('#buttonEditVoucherDisableFooter').is(':checked') )
            ) {
             $('#buttonEditVoucherSave').removeAttr('disabled');
         }
         else {
             $('#buttonEditVoucherSave').attr('disabled', true);
         }
     }
    
     function areaIsValid(area) {
         var idTextArea = "#textareaEditVoucher" + area,
             textAreaLength=$(idTextArea).val().length;
         
         if ( textAreaLength > minTextLength &&
              textAreaLength < totalChars[area]) {
            return true;
         }
         else {
            return false;
         }     
     }
 })
