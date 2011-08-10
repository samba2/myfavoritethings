 $(document).ready(function(){
    $('#nextButton').hide();
                 
    $('#uploadLater').click(function(){
        $('#fileUploadDialog').hide("normal");
        $('#nextButton').show("normal");
    })
    
    $('#uploadNow').click(function(){
        $('#fileUploadDialog').show("normal");
        $('#nextButton').hide("normal");
    })
    
    // check if zip file was selected
    $('#fileName').change(function(){
        var allowedExtensions = {
           '.zip' : 1,
           '.ZIP' : 1,
        };
        
        var uploadPathData = $(this).val();
        
        var regExExtension = /\..+$/;
        var regExWhiteSpace = /\s/;

        var extension = uploadPathData.match(regExExtension);
        
        if ( ! allowedExtensions[extension]) {
            $('#submitButton').attr('disabled', true);
            alert("Upload rejected: Invalid archive format, please select another file. (Archive must have a 'zip' extension)");
        } 
        else if ( uploadPathData.match(regExWhiteSpace) ) {
            alert("Upload rejected: The filename must not include white spaces.");
        }
        else {
            $('#submitButton').removeAttr('disabled');
        }
    })
    
 })
