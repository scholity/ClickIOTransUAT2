({
    parseOrgClass : function (header, record) {
        var fields = header.split('|');
        if (fields.length > 0 && fields.length == record.length) {
            var obj = {};
	        for (var i = 0; i < fields.length; i++) {
                var field = fields[i];
    	        var value = record[i];
                if (value.length > 0) {
                    if (field == 'Sender ID') { obj['senderId'] = value; }
                    else if (field == 'Batch ID') { obj['batchId'] = value; }
                    else if (field == 'Group ID') { obj['groupId'] = value; }
                    else if (field == 'Record Type') { obj['recordType'] = value; }
                    else if (field == 'Organization ID') { obj['orgId'] = value; }
                    else if (field == 'Organization Name') { obj['orgName'] = value; }
                    else if (field == 'PO Number') { obj['PO'] = value; }
                    else if (field == 'Course Code') { obj['courseCode'] = value; }
					else if (field == 'Course Version') { obj['courseVersion'] = value; }
                    else if (field == 'Course End Date') { obj['courseEndDate'] = value; }
                    else if (field == 'Total Students') { obj['totalStudents'] = value; }
                    else if (field == 'Training Site Name') { obj['trainingSiteName'] = value; }
                    else if (field == 'Training Site Address') { obj['trainingSiteAddress'] = value; }
                    else if (field == 'Training Site City') { obj['trainingSiteCity'] = value; }
                    else if (field == 'Training Site State') { obj['trainingSiteState'] = value; }
                    else if (field == 'Training Site Zip') { obj['trainingSiteZipCode'] = value; }
                }
        	}
            return obj;
        }
        return null;
    },
    
    parseInstructor : function (header, record) {
        var fields = header.split('|');
        if (fields.length > 0 && fields.length == record.length) {
            var obj = {};
	        for (var i = 0; i < fields.length; i++) {
                var field = fields[i];
    	        var value = record[i];
                if (value.length > 0) {
                    if (field == 'Sender ID') { obj['senderId'] = value; }
                    else if (field == 'Batch ID') { obj['batchId'] = value; }
                    else if (field == 'Group ID') { obj['groupId'] = value; }
                    else if (field == 'Record Type') { obj['recordType'] = value; }
                    else if (field == 'Instructor ID') { obj['instructorId'] = value; }
                    else if (field == 'Instructor First Name') { obj['instructorFirstName'] = value; }
                    else if (field == 'Instructor Last Name') { obj['instructorLastName'] = value; }
                    else if (field == 'Instructor Email Address') { obj['instructorEmail'] = value; }
                }
        	}
            return obj;
        }
        return null;
	},
    
    parseStudent : function (header, record) {
        var fields = header.split('|');
        if (fields.length > 0 && fields.length == record.length) {
            var obj = {};
	        for (var i = 0; i < fields.length; i++) {
                var field = fields[i];
    	        var value = record[i];
                if (value.length > 0) {
                    if (field == 'Sender ID') { obj['senderId'] = value; }
                    else if (field == 'Batch ID') { obj['batchId'] = value; }
                    else if (field == 'Group ID') { obj['groupId'] = value; }
                    else if (field == 'Record Type') { obj['recordType'] = value; }
                    else if (field == 'Participant First Name') { obj['studentFirstName'] = value; }
                    else if (field == 'Participant Last Name') { obj['studentLastName'] = value; }
                    else if (field == 'Participant Email Address') { obj['studentEmail'] = value; }
                    else if (field == 'Participant Phone Number') { obj['studentPhone'] = value; }
                    else if (field == 'Mastery Status') { obj['masteryStatus'] = value; }
                }
        	}
            return obj;
        }
        return null;
    },
    
    prepareForUpload : function (helper, csv) {
        console.log('prepareForUpload() invoked');
        var arr = [];
        
        // split into records
        arr = csv.split('\n');
        if (arr.length == 1) {
            csv.split('\r');
        }
        
        // remove last line if it's empty
        if (arr.length > 1) {
            var lastItem = arr[arr.length - 1];
            if (lastItem.trim().length == 0) {
                arr.pop();
            }
        }
        
        var header_OrgClass		= 'Sender ID|Batch ID|Group ID|Record Type|Organization ID|Organization Name|PO Number|Course Code|Course Version|Course End Date|Total Students|Training Site Name|Training Site Address|Training Site City|Training Site State|Training Site Zip';
        var header_Instructor	= 'Sender ID|Batch ID|Group ID|Record Type|Instructor ID|Instructor First Name|Instructor Last Name|Instructor Email Address';
        var header_Student		= 'Sender ID|Batch ID|Group ID|Record Type|Participant First Name|Participant Last Name|Participant Email Address|Participant Phone Number|Mastery Status';
        
        var orgClasses			= [];
        var instructors			= [];
        var students			= [];
        var section				= '';		// values: '', 'OrgClass', 'Instructor', 'Student'
        var errors				= [];
        
        for (var i = 0; i < arr.length; i++) {
            var data = arr[i].trim();
            
            if		(data == header_OrgClass) 		{ section = 'OrgClass'; }
            else if (data == header_Instructor)		{ section = 'Instructor'; }
            else if (data == header_Student) 		{ section = 'Student'; }
            else {
                var jsonObj = null;
                var record = data.split('|');
                
                if (section == 'OrgClass') {
                    jsonObj = helper.parseOrgClass(header_OrgClass, record);
                    if (jsonObj != null) { orgClasses.push(jsonObj); }
                } else if (section == 'Instructor') {
                    jsonObj = helper.parseInstructor(header_Instructor, record);
                    if (jsonObj != null) { instructors.push(jsonObj); }
                } else if (section == 'Student') {
                    jsonObj = helper.parseStudent(header_Student, record);
                    if (jsonObj != null) { students.push(jsonObj); }
                }
                
                if (jsonObj == null) {
                    errors.push('Failed to parse record on line ' + i + '.');
                }
            }
        }
        
        if (orgClasses.length == 0) { errors.push('Missing organization and classes.'); }
        if (instructors.length == 0) { errors.push('Missing instructor(s).'); }
        if (students.length == 0) { errors.push('Missing student(s).'); }
        
        var result = {};
        if (errors.length == 0) {
            var records = [];
            for (var i = 0; i < orgClasses.length; i++) { records.push(orgClasses[i]); }
            for (var i = 0; i < instructors.length; i++) { records.push(instructors[i]); }
            for (var i = 0; i < students.length; i++) { records.push(students[i]); }
            result['records'] = records;
        
        } else {
            result['errors'] = errors;
        }
        return result;
    },
    
    uploadBatchData : function (component, helper, batchData) {
        console.log('uploadBatchData() invoked');
        var action = component.get('c.processBatch');
        action.setParams({ 'dataStr' : JSON.stringify(batchData) });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state=' + state);
            if (state === 'SUCCESS') {
                var returnValue = response.getReturnValue();
                if (returnValue.Error != null) {
                    alert(returnValue.Error);
                } else {

                }

            } else {
            }
        });
        $A.enqueueAction(action);
    },
    
    uploadFile : function (component, helper, file) {
        console.log('uploadFile() invoked');
        var result = helper.prepareForUpload(helper, file);
        if (result.hasOwnProperty('errors')) {
            console.log('errors: ' + result['errors']);
        } else {
            console.log('no errors');
            var records = result['records'];
            helper.uploadBatchData(component, helper, records);
        }
    }
})