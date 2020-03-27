@RestResource(urlMapping='/PHSSClassCompletion/batch/*')
global without sharing class PHSS_ClassCompletionService {

    private static final Boolean DEBUG_MODE     = true;

    private static final String EOL_WINDOWS     = '\r\n';
    private static final String EOL_UNIX        = '\n';
    private static final String EOL_MAC_OLD     = '\r';
    
    // error messages
    private static final String NO_DATA_FOUND   = 'No data found.';
    private static final String FAILED_TO_FETCH_STUDENT_ACHIEVEMENTS = 'Failed to Fetch student achievements.';
    


    @HttpPost
    global static String process() {
        List<PHSS_ClassCompletionResponseWrapper> responsePayload = new List<PHSS_ClassCompletionResponseWrapper>();
        
        String buffer = EncodingUtil.base64Decode(EncodingUtil.base64Encode(RestContext.request.requestBody)).toString();
        if (String.isBlank(buffer)) {
            return NO_DATA_FOUND;
        }

        Map<String, Object> result;
        try {
            List<String> records = parseData(buffer);

            PHSS_ClassCompletionBatch batch = new PHSS_ClassCompletionBatch();
            result = batch.processData(records);
            Map<String, CCS_Batch_Class__c> batchMap = batch.getBatchMap();
            
           	// iterate through batches to create process log
            for (String batchName : batchMap.keySet())
            {
                CCS_Batch_Class__c batchClass = batchMap.get(batchName);
				/*
                Long startTime = DateTime.now().getTime();
                Long finishTime = DateTime.now().getTime();
                while ((finishTime - startTime) < 9000) {
                    //sleep for 9s
                    finishTime = DateTime.now().getTime();
                }
				*/
                //Build Student ResponsePayload
                //
                List<redwing__Achievement_Assignment__c> studentAchievements;
                try {
                    
                    
                	if(!Test.isRunningTest()) {
                    
                        studentAchievements = [
                            SELECT 
                            Account__c,
                            Achievement_Type__c,
                            CreatedById,
                            CreatedDate,
                            Firstname__c,
                            ILT_Class__c,
                            Lastname__c,
                            Name,Phone__c,
                            QR_Code_Identifier__c,
                            QR_Code_Web_Address__c,
                            QR_Code__c,
                            redwing__Acquisition_Date__c,
                            redwing__Status__c,
                            redwing__User__c,Request_Type__c,
                            Student_name__c 
                            FROM redwing__Achievement_Assignment__c 
                            Where 
                            Achievement_Type__c = 'Certifications' 
                            And
                            ILT_Class__c = :batchClass.ILT_Class__c
                        ];
                    } else {
                    	studentAchievements = [
                            SELECT 
                            Account__c,
                            Achievement_Type__c,
                            CreatedById,
                            CreatedDate,
                            Firstname__c,
                            ILT_Class__c,
                            Lastname__c,
                            Name,Phone__c,
                            QR_Code_Identifier__c,
                            QR_Code_Web_Address__c,
                            QR_Code__c,
                            redwing__Acquisition_Date__c,
                            redwing__Status__c,
                            redwing__User__c,Request_Type__c,
                            Student_name__c 
                            FROM redwing__Achievement_Assignment__c LIMIT 1
                        ];
                        
                    }
                    
                    if (studentAchievements != null && studentAchievements.size() > 0) {
                        
                        for (redwing__Achievement_Assignment__c studentAchievement : studentAchievements) {
                            
                                PHSS_ClassCompletionResponseWrapper studentWrapper = new PHSS_ClassCompletionResponseWrapper();
                                studentWrapper.account_Id = batchClass.Account__c;
                                studentWrapper.batch_Id = batchClass.Name;
                                studentWrapper.offering_Id = batchClass.Offering_Id_Batch_Class__c;
                                studentWrapper.cre_ilt_class_Id = String.valueOf(batchClass.ILT_Class__c);
                                studentWrapper.student_firstName = studentAchievement.Firstname__c;
                                studentWrapper.student_lastName = studentAchievement.Lastname__c;
                                studentWrapper.student_achievement = studentAchievement.redwing__Status__c;
                                studentWrapper.student_achievement_createDate = String.valueOf(studentAchievement.redwing__Acquisition_Date__c);
                                studentWrapper.student_certCompletionQRCode = studentAchievement.QR_Code_Identifier__c;
                            
                            
                   				List<CCS_Batch_Participant__c> students = [ SELECT Id, Name, Batch_Class__c, CreatedDate, First_Name__c, Last_Name__c, Evaluation_Notes__c, Phone_Number__c, Email_Address__c, Mastery_Status__c 
                                                                    FROM CCS_Batch_Participant__c 
                                                                        Where First_Name__c = :studentAchievement.Firstname__c 
                                                                            AND Last_Name__c = :studentAchievement.Lastname__c 
                                                                            	AND Batch_Class__c = :batchClass.Id Order By CreatedDate Desc]; 
                            
                            
                            	studentWrapper.student_notes = '';
                                if(students.size() > 0){
                                    studentWrapper.student_notes = students[0].Evaluation_Notes__c;
                                }
                                
                                responsePayload.add(studentWrapper);
							
                        }
						
                    }
        			
                    
                } catch (Exception e) {
                    throw new phss_cc_Exception(FAILED_TO_FETCH_STUDENT_ACHIEVEMENTS, e);
                    //throw new phss_cc_Exception(JSON.serialize(batchClass), e);
                }
	    }


        } catch (Exception e) {
            return e.getMessage();
        }

        if (!result.containsKey(PHSS_ClassCompletionBatch.SUCCESS_KEY)) {
            return String.valueOf(result);
        }

        String myJson = JSON.serializePretty(responsePayload);
        return myJson.replaceAll('\"', '\'');
    }


    private static List<String> parseData(String buffer) {

        String eol = null;
        if (buffer.contains(EOL_WINDOWS)) {
            if (DEBUG_MODE) { System.debug('delimiter: Windows'); }
            eol = EOL_WINDOWS;
        } else if (buffer.contains(EOL_UNIX)) {
            if (DEBUG_MODE) { System.debug('delimiter: Unix'); }
            eol = EOL_UNIX;
        } else if (buffer.contains(EOL_MAC_OLD)) {
            if (DEBUG_MODE) { System.debug('delimiter: Mac (old)'); }
            eol = EOL_MAC_OLD;
        }

        List<String> records = new List<String>();
        if (eol != null) {
            records = buffer.split(eol);
        } else {
            records.add(buffer);
        }

        if (DEBUG_MODE) { System.debug('Number of records received: ' + records.size()); }

        return records;
    }
}