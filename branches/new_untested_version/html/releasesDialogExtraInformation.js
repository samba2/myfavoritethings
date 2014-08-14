$('#showDetails').click(function () {
    $( "#dialogExtraInformation" ).dialog({ width: 600 });
    
    $('#buttonShowDetailsOK').click(function () {
        $( "#dialogExtraInformation" ).dialog('close');        
    })
})