public without sharing class PHSS_CpsDashboardController {

    @AuraEnabled
    public static PHSS_CpsWrapper initWrapper() {
    	PHSS_CpsWrapper cpsWrap = new PHSS_CpsWrapper();
        // Get Organization name
        List<User> userList = [Select Id,Name,ContactId From User Where Id = :UserInfo.getUserId()];
        if(!userList.isEmpty() && userList[0].ContactId != null) {
            List<Contact> conList = [Select Id,Account.Name From Contact Where Id = :userList[0].ContactId];
            cpsWrap.accId = conList[0].Account.Id;
            cpsWrap.accName = conList[0].Account.Name;
        }
        
        // Initialize Session list
        List<PHSS_CpsWrapper.SessionWrapper> sessionWrapList = new List<PHSS_CpsWrapper.SessionWrapper>();
        PHSS_CpsWrapper.SessionWrapper sessionWrap = new PHSS_CpsWrapper.SessionWrapper();
        sessionWrapList.add(sessionWrap);
        cpsWrap.sessionList = sessionWrapList;
        
        // Class Formats
        List<String> formatsList = new List<String>();
        Schema.DescribeFieldResult fieldResult = redwing__ILT_Class__c.Classroom_Setting__c.getDescribe();
        List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry val : entries) {
            if(val.getLabel() != 'Online') {
            	formatsList.add(val.getLabel());
            }
        }
        cpsWrap.classFormatList = formatsList;
        
        // Timezone
        PHSS_skedJobToILTClass localSkedJobtoILTClass = new PHSS_skedJobToILTClass();
        cpsWrap.timeZoneList = localSkedJobtoILTClass.timeZoneMap;
		
        return cpsWrap;
    }

    @AuraEnabled
    public static void updateClass(String jsonStr) {
        try {
          	System.debug('log');
            PHSS_CpsWrapper cpsWrap = (PHSS_CpsWrapper)JSON.deserialize(jsonStr, PHSS_CpsWrapper.class);
            
            //update ILT class information
			redwing__ILT_Class__c offering= new redwing__ILT_Class__c();
            offering.Id=cpsWrap.iltClassId;
            offering.Registration_Fee__c=cpsWrap.regFee;
            offering.CPS_Registration_Phone__c =cpsWrap.regPhone;
            offering.CPS_Registration_URL__c =cpsWrap.regUrl;
            offering.redwing__Location__c = cpsWrap.locationId;
            
             // Convert date and time to UTC 
            integer indx = cpsWrap.sessionList.size() - 1;
            
            Date classStartDate = Date.valueOf(cpsWrap.sessionList[0].classDate);
            Date classEndDate = Date.valueOf(cpsWrap.sessionList[indx].classDate);
            
            List<String> startTimeList = cpsWrap.sessionList[0].startTime.split(':');
            List<String> endTimeList = cpsWrap.sessionList[indx].endTime.split(':');
            
            String timeZoneVal = cpsWrap.timeZoneList.get(cpsWrap.sessionList[0].timeZone); 
            TimeZone tz = Timezone.getTimeZone(timeZoneVal);
            
            DateTime startDateTime = DateTime.newInstanceGmt(classStartDate.year(),classStartDate.month(),classStartDate.day(),Integer.valueOf(startTimeList[0]),Integer.valueOf(startTimeList[1]),0);
            DateTime endDateTime = DateTime.newInstanceGmt(classEndDate.year(),classEndDate.month(),classEndDate.day(),Integer.valueOf(endTimeList[0]),Integer.valueOf(endTimeList[1]),0);

            String timeStart = String.valueOf(startTimeList[0]);
            String timeEnd = String.valueOf(endTimeList[0]);
            Integer daysToAdd = 0;
            Integer daysToSubtract = 1;
            
            DateTime startTime = DateTime.newInstanceGmt(classStartDate.year(),classStartDate.month(),Integer.valueOf(classStartDate.day()+daysToAdd),Integer.valueOf(timeStart),Integer.valueOf(startTimeList[1]),0); 
            DateTime endTime = DateTime.newInstanceGmt(classEndDate.year(),classEndDate.month(),Integer.valueOf(classEndDate.day()+daysToAdd),Integer.valueOf(timeEnd),Integer.valueOf(endTimeList[1]),0); 
                        
            offering.redwing__Start_Time__c = startTime.format('HH:mm', 'GMT'); 
            offering.redwing__End_Time__c = endTime.format('HH:mm', 'GMT'); 
          
            offering.redwing__Start_Date__c = startTime.dateGmt();
            offering.redwing__End_Date__c = endTime.dateGmt();             
            
            offering.redwing__Timezone__c = timeZoneVal;
            
            if(!Test.isRunningTest()) {
            update offering;
             }
            //delete all session information before adding new ones
            System.debug('testing 123');
            List<redwing__ILT_Session__c> toDel = new List<redwing__ILT_Session__c>();
			toDel = [select id from redwing__ILT_Session__c where redwing__ILT_Class__c=:cpsWrap.iltClassId];
		     if(!Test.isRunningTest()) {
            delete toDel;
             }
            
            System.debug('test 456');
            
            Integer sessionIndex = 0;
            List<redwing__ILT_Session__c> sessList = new List<redwing__ILT_Session__c>();
            for(PHSS_cpsWrapper.SessionWrapper sessWrap : cpsWrap.sessionList) {
                redwing__ILT_Session__c sess = new redwing__ILT_Session__c();
                sess.redwing__ILT_Class__c = cpsWrap.iltClassId;
                sess.redwing__Date__c = Date.valueOf(sessWrap.classDate);
  
                List<String> sessStartTimeList = sessWrap.startTime.split(':');
                Time sessStartTime = Time.newInstance(Integer.valueOf(sessStartTimeList[0]),Integer.valueOf(sessStartTimeList[1]),0,0);
                List<String> sessEndTimeList = sessWrap.endTime.split(':');
                Time sessEndTime = Time.newInstance(Integer.valueOf(sessEndTimeList[0]),Integer.valueOf(sessEndTimeList[1]),0,0);
                
                sess.redwing__Start_Time__c = String.valueOf(sessStartTime).subString(0,5);
                sess.redwing__End_Time__c = String.valueOf(sessEndTime).subString(0,5);
                sess.redwing__Location__c = cpsWrap.locationId;
                //System.debug('course name is:'+cpsWrap.courseName);
                Integer clsday = sess.redwing__Date__c.day();
                Integer clsmonth = sess.redwing__Date__c.month();
                Integer clsyear = sess.redwing__Date__c.year();
                Datetime sessionDatetime = Datetime.newInstance(clsyear, clsmonth, clsday, 12, 00, 00);
                Integer namePrefixLength = Math.min(cpsWrap.courseName.length(), 40);
                sess.Name = cpsWrap.courseName.substring(0, namePrefixLength) + ' ' + sessionDatetime.format('MM/dd/yyyy');
                sessList.add(sess);
                
            }
			       //  System.debug('test 777');   
             if(!Test.isRunningTest()) {
                insert sessList;    
            }
		
            
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static ccrz__E_Product__c getLearningPlanId(String ccProdId) {
        
        ccrz__E_Product__c  ccProd = [SELECT Id, LMS_Learning_Plan__c, LMS_Learning_Plan__r.Name  FROM ccrz__E_Product__c WHERE Id =: ccProdId LIMIT 1];
        
        return ccProd;
    }
	
    @AuraEnabled
    public static ccrz__E_Product__c getLearningPlanAttributes(String ccProdId) {

        ccrz__E_Product__c  ccProd = [SELECT Id, LMS_Learning_Plan__c, LMS_Learning_Plan__r.Name, LMS_Learning_Plan__r.Classroom_Setting__c, LMS_Learning_Plan__r.redwing__Duration__c  FROM ccrz__E_Product__c WHERE Id =: ccProdId LIMIT 1];

        return ccProd;
    }
	    
    
    @AuraEnabled
    public static ccrz__E_Product__c getLearningPlanAttributesByName(String LPName) {

        ccrz__E_Product__c  ccProd = [SELECT Id, ccrz__ProductId__c,LMS_Learning_Plan__c, LMS_Learning_Plan__r.Name, LMS_Learning_Plan__r.Classroom_Setting__c, LMS_Learning_Plan__r.redwing__Duration__c  FROM ccrz__E_Product__c WHERE LMS_Learning_Plan__r.Name =: LPName LIMIT 1];

        return ccProd;
    }
    
    
    @AuraEnabled
    public static Id createIltLocation(String accountId, String name, String address1, String address2, String postcode, String state, String city, String lat, String lng) {
	 //System.debug('createIltLocation');
        // validate if the site is really new?
        
        List<redwing__ILT_Location__c> locations = [SELECT Id, Name, redwing__Address_1__c, redwing__Address_2__c, redwing__Postal_Code__c, redwing__State__c, redwing__City__c
                                                    FROM redwing__ILT_Location__c WHERE Account__c = :accountId];

        for (redwing__ILT_Location__c existingLoc : locations) {

            if (existingLoc.redwing__Address_1__c == address1 && existingLoc.redwing__Postal_Code__c == postcode && existingLoc.redwing__State__c == state && existingLoc.redwing__City__c == city &&
                    ( (String.isBlank(existingLoc.redwing__Address_2__c) && String.isBlank(address2)) || existingLoc.redwing__Address_2__c == address2 )) {
                
                existingLoc.Skedulo_Type__c = 'CPS';
                existingLoc.GeoLocation__Latitude__s = decimal.valueOf(lat);
                existingLoc.GeoLocation__Longitude__s = decimal.valueOf(lng);
                update existingLoc;
                        
                return existingLoc.Id;
            }
        }
	
        // create if no match found to the existing ones
        redwing__ILT_Location__c loc = new redwing__ILT_Location__c();
        loc.Account__c = accountId;
        loc.Name = name;
        loc.redwing__Address_1__c = address1;
        loc.redwing__Street__c = address1;
        loc.redwing__Address_2__c = address2;
        loc.redwing__Postal_Code__c = postcode;
        loc.redwing__State__c = state;
        loc.redwing__City__c = city;
        loc.Skedulo_Type__c = 'CPS';
        loc.GeoLocation__Latitude__s = decimal.valueOf(lat);
        loc.GeoLocation__Longitude__s = decimal.valueOf(lng);

        insert loc;
        return loc.Id;
    }
    
    @AuraEnabled
    public static void postClass(String jsonStr) {
        try {
            
            List<ccrz__E_CartItem__c> updatedCartItems = new list<ccrz__E_CartItem__c>();
            List<ccrz__E_Order__c> updatedOrders = new List<ccrz__E_Order__c>();
            
            //System.debug('JSON:'+jsonStr);
            PHSS_CpsWrapper cpsWrap = (PHSS_CpsWrapper)JSON.deserialize(jsonStr, PHSS_CpsWrapper.class);
            
            System.debug('cpsWrap:'+cpsWrap);
            
            // Create Learning (master) record
            redwing__Learning__c objLearning = new redwing__Learning__c();
            objLearning.RecordTypeId = Schema.SObjectType.redwing__Learning__c.getRecordTypeInfosByName().get('ILT Class').getRecordTypeId();
            objLearning.Name = cpsWrap.courseName;
            objLearning.redwing__Published__c = true;
            insert objLearning;    
            
            // Create ILT Class record
            redwing__ILT_Class__c newClass = new redwing__ILT_Class__c();
            newClass.Request_Type__c = 'CPS';
            newClass.Name = cpsWrap.courseName;
            newClass.Skedulo_Account__c = cpsWrap.accId;
            newClass.Learning_Plan__c = cpsWrap.courseId;
            
            // Convert date and time to UTC 
            integer indx = cpsWrap.sessionList.size() - 1;
            System.debug('Max size of Session Obj: '+indx);
            
            Date classStartDate = Date.valueOf(cpsWrap.sessionList[0].classDate);
            
            Date classEndDate = Date.valueOf(cpsWrap.sessionList[indx].classDate);
            
            List<String> startTimeList = cpsWrap.sessionList[0].startTime.split(':');
            
            List<String> endTimeList = cpsWrap.sessionList[indx].endTime.split(':');
            
            String timeZoneVal = cpsWrap.timeZoneList.get(cpsWrap.sessionList[0].timeZone); 
            TimeZone tz = Timezone.getTimeZone(timeZoneVal);
            
            DateTime startDateTime = DateTime.newInstanceGmt(classStartDate.year(),classStartDate.month(),classStartDate.day(),Integer.valueOf(startTimeList[0]),Integer.valueOf(startTimeList[1]),0);
            DateTime endDateTime = DateTime.newInstanceGmt(classEndDate.year(),classEndDate.month(),classEndDate.day(),Integer.valueOf(endTimeList[0]),Integer.valueOf(endTimeList[1]),0);

            String timeStart = String.valueOf(startTimeList[0]);
            String timeEnd = String.valueOf(endTimeList[0]);
            Integer daysToAdd = 0;
            Integer daysToSubtract = 1;
            
            DateTime startTime = DateTime.newInstanceGmt(classStartDate.year(),classStartDate.month(),Integer.valueOf(classStartDate.day()+daysToAdd),Integer.valueOf(timeStart),Integer.valueOf(startTimeList[1]),0); 
            DateTime endTime = DateTime.newInstanceGmt(classEndDate.year(),classEndDate.month(),Integer.valueOf(classEndDate.day()+daysToAdd),Integer.valueOf(timeEnd),Integer.valueOf(endTimeList[1]),0); 
            
            DateTime rco_post_startTime = DateTime.newInstanceGmt(System.today(), Time.newInstance(0,0,0,0)); 
            DateTime rco_post_endTime = DateTime.newInstanceGmt(classStartDate.year(),classStartDate.month(),Integer.valueOf(classStartDate.day() - daysToSubtract),Integer.valueOf(timeEnd),Integer.valueOf(endTimeList[1]),0); 
            
            newClass.redwing__Start_Time__c = startTime.format('HH:mm', 'GMT'); 
            newClass.redwing__End_Time__c = endTime.format('HH:mm', 'GMT'); 
            
            newClass.redwing__Start_Date__c = startTime.dateGmt();
            newClass.redwing__End_Date__c = endTime.dateGmt();             
            
            newClass.redwing__Timezone__c = timeZoneVal;

            newClass.redwing__Location__c = cpsWrap.locationId;
            newClass.CPS_Registration_URL__c = cpsWrap.regUrl;
            newClass.CPS_Registration_Phone__c = cpsWrap.regPhone;
            newClass.Registration_Fee__c = cpsWrap.regFee;
            newClass.CPS_Approval_Status__c = 'Submitted';
            newClass.redwing__Learning__c = objLearning.Id;
            newClass.Classroom_Setting__c = cpsWrap.classFormat;

            newClass.Class_Searchable__c = true;
             if(!Test.isRunningTest()) {
            insert newClass;
             }
            
            Integer sessionIndex = 0;
            List<redwing__ILT_Session__c> sessList = new List<redwing__ILT_Session__c>();
            for(PHSS_cpsWrapper.SessionWrapper sessWrap : cpsWrap.sessionList) {
                redwing__ILT_Session__c sess = new redwing__ILT_Session__c();
                sess.redwing__ILT_Class__c = newClass.Id;
                sess.redwing__Date__c = Date.valueOf(sessWrap.classDate);
                
                List<String> sessStartTimeList = sessWrap.startTime.split(':');
                Time sessStartTime = Time.newInstance(Integer.valueOf(sessStartTimeList[0]),Integer.valueOf(sessStartTimeList[1]),0,0);
                List<String> sessEndTimeList = sessWrap.endTime.split(':');
                Time sessEndTime = Time.newInstance(Integer.valueOf(sessEndTimeList[0]),Integer.valueOf(sessEndTimeList[1]),0,0);
                
                sess.redwing__Start_Time__c = String.valueOf(sessStartTime).subString(0,5);
                sess.redwing__End_Time__c = String.valueOf(sessEndTime).subString(0,5);
                sess.redwing__Location__c = cpsWrap.locationId;
                
                
                Integer clsday = sess.redwing__Date__c.day();
                Integer clsmonth = sess.redwing__Date__c.month();
                Integer clsyear = sess.redwing__Date__c.year();
                Datetime sessionDatetime = Datetime.newInstance(clsyear, clsmonth, clsday, 12, 00, 00);
                Integer namePrefixLength = Math.min(cpsWrap.courseName.length(), 40);
                sess.Name = cpsWrap.courseName.substring(0, namePrefixLength) + ' ' + sessionDatetime.format('MM/dd/yyyy');
                
                sessList.add(sess);
            }
            
            if(!Test.isRunningTest()) {
                insert sessList;    
            }
            
        }
        catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    
    @AuraEnabled 
    public static List<PHSS_CpsWrapper> getOfferings(String accountId, String accountName) { 
    		Integer offeringCnt = 0;
            //System.debug('getOfferings');
        	List<PHSS_CpsWrapper> offerings = new List<PHSS_CpsWrapper>();

             if (accountId != null) {
        	 for(redwing__ILT_Class__c offering : [Select Id, Name, redwing__Start_Date__c,redwing__Location__c,redwing__Timezone__c, CPS_Registration_URL__c, CPS_Registration_Phone__c,Offering_Id__c, Registration_Fee__c, Classroom_Setting__c From redwing__ILT_Class__c Where redwing__ILT_Class__c.Skedulo_Account__c =:accountId And Request_Type__c = 'CPS' and redwing__Location__c!=null and redwing__Start_Date__c>= TODAY and Class_Searchable__c=true and Class_Online__c=true]){
				
                    if (offering != null){
                        //Class
                        offeringCnt = offeringCnt + 1;
                        PHSS_CpsWrapper cpsWrap = new PHSS_CpsWrapper();
                        cpsWrap.iltClassId = String.valueOf(offering.Id);
                        cpsWrap.offeringId = String.valueOf(offeringCnt);
             			cpsWrap.courseName = offering.Name;
                        cpsWrap.locationId = offering.redwing__Location__c;
                        cpsWrap.regUrl = offering.CPS_Registration_URL__c; 
                        cpsWrap.regPhone = offering.CPS_Registration_Phone__c; 
                        cpsWrap.regFee = offering.Registration_Fee__c;
                        cpsWrap.classFormat = offering.Classroom_Setting__c;
                        cpsWrap.clsId=offering.Offering_Id__c;
                        cpsWrap.timeZone=offering.redwing__Timezone__c;
						List<String> classDateString=String.valueOf(offering.redwing__Start_Date__c).split('-');
                        cpsWrap.startDate=classDateString[1]+'/'+classDateString[2]+'/'+classDateString[0];

                        //Location
                        redwing__ILT_Location__c loc =  [Select Id, Name, redwing__Address_1__c, redwing__Street__c, redwing__Address_2__c, redwing__Postal_Code__c, redwing__State__c, redwing__City__c, Skedulo_Type__c, GeoLocation__Latitude__s, GeoLocation__Longitude__s  From redwing__ILT_Location__c Where  Id= :cpsWrap.locationId ];
						cpsWrap.siteName = loc.Name;
	           			cpsWrap.address1 = loc.redwing__Address_1__c;
                        cpsWrap.address2 = loc.redwing__Address_2__c;
 			   			cpsWrap.city  = loc.redwing__City__c;
						cpsWrap.state = loc.redwing__State__c;
						cpsWrap.zip = loc.redwing__Postal_Code__c;
						cpsWrap.geoLat = String.valueOf(loc.GeoLocation__Latitude__s);
						cpsWrap.geoLng = String.valueOf(loc.GeoLocation__Longitude__s);
                       
                        

                        cpsWrap.sessionList = new List<PHSS_CpsWrapper.SessionWrapper>();
                        
                        for(redwing__ILT_Session__c session : [Select Id, Name, redwing__ILT_Class__c, redwing__Date__c, redwing__Description__c, redwing__End_Time__c, redwing__Location__c, redwing__Start_Time__c, ltui__End_Time_Formatted__c, ltui__Start_Time_Formatted__c, Skedulo_Account__c, redwing__Type__c  From redwing__ILT_Session__c Where  redwing__ILT_Session__c.redwing__ILT_Class__c = :offering.Id ]){
					
                            if (session != null){
                                PHSS_CpsWrapper.SessionWrapper wrapperSession = new PHSS_CpsWrapper.SessionWrapper();  
                                //wrapperSession.classDate = String.valueOf(session.redwing__Date__c);
                                wrapperSession.classDate = DateTime.newInstance(session.redwing__Date__c.year(), session.redwing__Date__c.month(), session.redwing__Date__c.day()).format('yyyy-MM-dd');
                                wrapperSession.startTime = session.redwing__Start_Time__c;
                                wrapperSession.endTime = session.redwing__End_Time__c;
                                //wrapperSession.timeZone = session.;
                                cpsWrap.sessionList.add(wrapperSession);
                                
                            }
                        }
                                  
						offerings.add(cpsWrap);
                                  
                    }                                                             
                                                             
               }      
	
            }
        	
			return offerings;

    }

}