$('#deleteRelease').click(function () {
    $( "#dialogDeleteRelease" ).dialog({ height: 'auto',
                                         minHeight: 50,
                                         modal: true });
                                         
    $('#buttonDeleteReleaseCancel').click(function () {
        $( "#dialogDeleteRelease" ).dialog('close');        
    })
})