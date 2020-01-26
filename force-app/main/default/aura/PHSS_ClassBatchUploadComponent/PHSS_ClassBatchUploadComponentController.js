({
	handlePressUploadButton : function(component, event, helper) {
        console.log('handlePressUploadButton() invoked');
        var fileInput = component.find("file").getElement();
        var file = fileInput.files[0];
        
        if (file) {
            var reader = new FileReader();
            reader.readAsText(file, "UTF-8");
            reader.onload = function (evt) {
                var fileData = evt.target.result;
                window.setTimeout(
                    $A.getCallback(function() {
                        helper.uploadFile(component, helper, fileData);
                    }), 0
                );
            }
            reader.onerror = function (evt) {
            	console.log("error reading file");
        	}
    	}
	},
    
    handleUploadFinished : function(component, event, helper) {
        var uploadedFiles = event.getParam("files");
        var documentId = uploadedFiles[0].documentId;
        var fileName = uploadedFiles[0].name;
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "File "+fileName+" Uploaded successfully."
        });
        toastEvent.fire();
        
        $A.get('e.lightning:openFiles').fire({
            recordIds: [documentId]
        });
        
    }

})