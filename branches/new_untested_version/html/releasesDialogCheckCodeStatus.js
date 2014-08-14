$('#checkCodeStatus').click(function () {
    $('#dialogCheckCodeStatus').dialog();
     
    // reset to default values
    initCheckCodeDialog();
    $('#spanCheckCodeStatusText').text('');
    $('#buttonCheckCodeStatus').unbind('click');
    $('#buttonResetCodeStatus').unbind('click');

    $('#buttonCheckCodeStatus').click(function () {
        $.getJSON("RPC.cgi?",
           {
            rm: "getCodeStatus",
            releaseId: $('#spanReleaseId').text(),
            downloadCode: $('#textDownloadCode').val()
           },
           function(data) {
              fillReturnedText(data); 

              if ( data.allowReset === 1) {
                  // disable check button+text field, enable reset
                  $('#buttonResetCodeStatus').removeAttr('disabled'); 
                  $('#buttonCheckCodeStatus').attr('disabled', true); 
                  $('#textDownloadCode').attr('disabled', true);   
              }
           }
       )
    })
    
    $('#buttonResetCodeStatus').click(function () {
        $.getJSON("RPC.cgi?",
           {
            rm: "resetCode",
            releaseId: $('#spanReleaseId').text(),
            downloadCode: $('#textDownloadCode').val()
           },
           function(data) {
              fillReturnedText(data);
              initCheckCodeDialog();
           }
       )    
    })    
    
    $('#buttonCheckCodeStatusCancel').click(function () {
        $( "#dialogCheckCodeStatus" ).dialog('close');        
    })
    
    function fillReturnedText(data) {
        if ( data.error ) {
           $('#spanCheckCodeStatusText').text(data.error);
         }
         else if ( data.codeStatus ) {
            $('#spanCheckCodeStatusText').text(data.codeStatus);
         }   
    }
    
    function initCheckCodeDialog() {
        $('#buttonResetCodeStatus').attr('disabled', true);
        $('#buttonCheckCodeStatus').removeAttr('disabled'); 
        $('#textDownloadCode').removeAttr('disabled'); 
        $('#textDownloadCode').val('');
    }
})
