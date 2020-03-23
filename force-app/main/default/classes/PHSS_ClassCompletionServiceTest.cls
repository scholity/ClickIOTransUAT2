@isTest
private class PHSS_ClassCompletionServiceTest {
    
    @isTest static  void testGetCallout() {
        String fileContent = '001d000001QuLKHAA3|0005|a3J21000000HXXX|A|001d000001QuLKHAA3|Cardio Partners, Inc.|My Test PO|AP-HSSAQU402|02/11/2020|02/11/2020|4|Cardio Partners, Inc. HQ|6105 Rockwell Dr. NE|Cedar Rapids|IA|52402\n'
            + '001d000001QuLKHAA3|0005|a3J21000000HXXX|B|christian.hernandez@cardiopartners.com.transuat|Christian|Hernandez|christian.hernandez@cardiopartners.com.transuat\n'
            + '001d000001QuLKHAA3|0005|a3J21000000HXXX|C|Isaac|Barker||800-345-4444|Successful||ibarker123@maildrop.cc\n'
            + '001d000001QuLKHAA3|0005|a3J21000000HXXX|C|Suzanne|Miller||800-123-4444|Successful|smiller123@maildrop.cc\n'
            + '001d000001QuLKHAA3|0005|a3J21000000HXXX|C|Johnny|Rocket||800-321-4444|Successful|jrocker123@maildrop.cc\n'
            + '001d000001QuLKHAA3|0005|a3J21000000HXXX|C|Jack|Black||800-666-4444|Unsuccessful|test note\n';
		
        // Create community user record
        List<Profile> profList = [SELECT Id FROM Profile WHERE Name = 'SB PHSS-Partner-Community Plus Login' LIMIT 1];
        String profId;
        ccrz__E_Product__c ccprod;
      
        if(!profList.isEmpty()) {
        	Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Bucket Account').getRecordTypeId();
        
            //Bucket Custom settings
            Bucket_Account_Settings__c bas = Bucket_Account_Settings__c.getOrgDefaults();
            bas.Bucket_Account_Owner_ID__c = UserInfo.getUserID();
            bas.Bucket_Account_RecordTypeID__c = recordTypeId;
            bas.Default_Bucket_Name__c = 'Bucket Account';
            bas.Maximum_Size_of_Bucket__c = 5000;
            insert bas;
        
            profId = profList[0].Id;
        
            // Get an user with a role
            List<User> userWithRole = [SELECT id, UserRole.Name 
                                       FROM User 
                                       WHERE (NOT UserRole.Name LIKE '%Customer User') AND
                                       		 UserRoleId != null AND
                                       		 Profile.Name = 'System Administrator' AND
                                       		 isActive = true
                                       LIMIT 1];
            
            User partnerUser;
            
            
            Account acc = new Account();
            System.runAs(userWithRole[0]) {
                acc.Name = 'TestAccount';
                acc.BillingStreet = '24 Willie Mays Plaza';
                acc.BillingCity = 'San Francisco';
                acc.BillingState = 'California';
                acc.BillingPostalCode = '94017';
                acc.BillingCountry = 'USA';
                acc.Phone = '9876543210';
                insert acc;

                Contact con = new Contact();
                con.FirstName = 'Contact';
                con.LastName = 'Test';
                con.Email = 'testCon@gmail.com';
                con.Account = acc;
                insert con;

                partnerUser = new User(LastName = 'Test',
                                         FirstName = 'User',
                                         Alias = 'testU',
                                         Email = 'testCon@gmail.com',
                                         Username = 'testUser@redCross.com',
                                         ProfileId = profId,
                                         ContactId = con.id,
                                         TimeZoneSidKey = 'GMT',
                                         LanguageLocaleKey = 'en_US',
                                         EmailEncodingKey = 'UTF-8',
                                         LocaleSidKey = 'en_US'
                                        );
                insert partnerUser;
                
                redwing__Training_Plan__c TPlan = new redwing__Training_Plan__c();
                TPlan.Name = 'Plan2';
                insert TPlan;
                
                System.debug('learning plan id' + TPlan.id);
                
                ccprod = new ccrz__E_Product__c(
                    Name = 'Lifeguarding',
                    ccrz__SKU__c = 'AP-HSSAQU402',
                    ccrz__Quantityperunit__c = 1,
                    ccrz__StartDate__c = Date.today(),
                    ccrz__EndDate__c = Date.today().addMonths(12),
                    ccrz__ProductId__c = 'AP-HSSAQU402',
                    //AP-HSSAQU402
                    LMS_Learning_Plan__c = TPlan.id
                );
                insert ccprod;
                
            }
        
            /*
            User runAsUser = [Select Id,FirstName,LastName,Alias,Email,Username,ProfileId,UserRoleId,TimeZoneSidKey,
                              EmailEncodingKey,LanguageLocaleKey,LocaleSidKey from User Where IsActive = True And
                              Name != 'Salesforce Automation Account' And UserRoleId != NULL
                              And Profile.Name = 'System Administrator' Limit 1];
            
            User runAsUser = [Select Id,FirstName,LastName,Alias,Email,Username,ProfileId,UserRoleId,TimeZoneSidKey,
                              EmailEncodingKey,LanguageLocaleKey,LocaleSidKey from User Where IsActive = True And
                              Email = 'john.cordero@redcross.org' Limit 1]; 
            */
            
            List<BGST_Profiles__c> ProfilesList = new List<BGST_Profiles__c>();
            
            BGST_Profiles__c indiv = new BGST_Profiles__c( name  = 'Owner Profile',
            
            Sales_User__c   = 'ARC BGST Sales User');
            
            ProfilesList.add(indiv);
            
            insert ProfilesList;
            
                        // Create Learning Plan record to use it as a course in postClass method
            redwing__Training_Plan__c lPlan = new redwing__Training_Plan__c();
            lPlan.Name = 'Test Plan';
            insert lPlan;
        	
            // Create account 
            Account testAcc = new Account();
            testAcc.Name = 'Test Org';
            testAcc.OwnerId = partnerUser.Id;
            insert testAcc;
            
            Map<String, Object> testData = phss_cc_TestDataFactory.setupAccountAndProducts();
			Account testAccount = (Account) testData.get(phss_cc_TestDataFactory.TEST_ACCOUNT);
			//Opportunity testOpportunity = phss_cc_TestDataFactory.createInsertTestOpportunity(testAccount);
			
                    
            test.startTest();
            System.RunAs(partnerUser) {
                
                List<ccrz__E_Product__c>  ccProduct = [SELECT Id, Name, ccrz__ProductId__c FROM  ccrz__E_Product__c Where Name = 'TEST0'];
    
            	system.debug('***Test Product Select***'+ccProduct);
                
                // Create the mock response based on a static resource
               
                StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
                mock.setStaticResource('PHSS_ClassCompletionService');
                mock.setStatusCode(200);
                mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
                // Associate the callout with a mock response
                Test.setMock(HttpCalloutMock.class, mock);
                
                
                // Call method to test
                HttpResponse result = PHSS_ClassCompletionServiceCallouts.makePostCallout(fileContent);
                // Verify mock response is not null
                System.assertNotEquals(null,result,
                    'The callout returned a null response.');
                // Verify status code
                System.assertEquals(200,result.getStatusCode(),
                  'The status code is not 200.');
                // Verify content type   
                System.assertEquals('application/json;charset=UTF-8',
                  result.getHeader('Content-Type'),
                  'The content type value is not expected.');  
                // Verify the array contains 3 items     
                String results = result.getBody();
                System.debug('Response: ' + results);
                
                
                RestRequest req = new RestRequest();
                RestResponse res = new RestResponse();
                
                req.requestURI = PageReference.forResource('PHSS_ClassCompletionService').getUrl();
                req.httpMethod = 'POST';
                req.requestBody = Blob.valueof(fileContent);
                RestContext.request = req;
                RestContext.response= res;
                
                PHSS_ClassCompletionService.process();
                
                PHSS_ClassCompletionResponseWrapper rw = new PHSS_ClassCompletionResponseWrapper();
                rw.account_Id = '001d000001QuLKHAA3';
                rw.batch_Id = '0005';
                rw.offering_Id= '';
                rw.student_achievement = '';
                rw.student_achievement_createDate = '';
                rw.student_certCompletionQRCode = '';
                rw.student_firstName = '';
                rw.student_lastName = '';
                rw.student_notes = '';

            }
            test.stopTest();
        }
       
    }   

}