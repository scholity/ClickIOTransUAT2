@isTest
private class PHSS_ClassCompletionServiceTest {
    
    @isTest static  void testGetCallout() {
        String fileContent = '001d000001QuLKHAA3|0005|a3J21000000HXXX|A|001d000001QuLKHAA3|Cardio Partners, Inc.|My Test PO|AP-HSSBBP101|02/11/2020|02/11/2020|4|Cardio Partners, Inc. HQ|6105 Rockwell Dr. NE|Cedar Rapids|IA|52402\n'
            + '001d000001QuLKHAA3|0005|a3J21000000HXXX|B|christian.hernandez@cardiopartners.com.transuat|Christian|Hernandez|christian.hernandez@cardiopartners.com.transuat\n'
            + '001d000001QuLKHAA3|0005|a3J21000000HXXX|C|Isaac|Barker||800-345-4444|Successful||ibarker123@maildrop.cc\n'
            + '001d000001QuLKHAA3|0005|a3J21000000HXXX|C|Suzanne|Miller||800-123-4444|Successful|smiller123@maildrop.cc\n'
            + '001d000001QuLKHAA3|0005|a3J21000000HXXX|C|Johnny|Rocket||800-321-4444|Successful|jrocker123@maildrop.cc\n'
            + '001d000001QuLKHAA3|0005|a3J21000000HXXX|C|Jack|Black||800-666-4444|Unsuccessful|test note\n';
		
        
        //String fileContent = '';
        
        User runAsUser = [Select Id,FirstName,LastName,Alias,Email,Username,ProfileId,UserRoleId,TimeZoneSidKey,
                          EmailEncodingKey,LanguageLocaleKey,LocaleSidKey from User Where IsActive = True And
                          Name != 'Salesforce Automation Account' And UserRoleId != NULL
                          And Profile.Name = 'System Administrator' Limit 1];
        
        List<BGST_Profiles__c> ProfilesList = new List<BGST_Profiles__c>();
        
        BGST_Profiles__c indiv = new BGST_Profiles__c( name  = 'Owner Profile',
        
        Sales_User__c   = 'ARC BGST Sales User');
        
        ProfilesList.add(indiv);
        
        insert ProfilesList;
        
        System.RunAs(runAsUser) {
            test.startTest();
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
            
            
            
            /*
            
            PHSS_ClassCompletionBatch testBatchService = new PHSS_ClassCompletionBatch();
            
            List<String> records = new List<String>();
            records.add('001d000001QuLKHAA3|0005|a3J21000000HXXX|A|001d000001QuLKHAA3|Cardio Partners, Inc.|My Test PO|AP-HSSBBP101|02/11/2020|02/11/2020|2|Cardio Partners, Inc. HQ|6105 Rockwell Dr. NE|Cedar Rapids|IA|52402');
            records.add('001d000001QuLKHAA3|0005|a3J21000000HXXX|B|christian.hernandez@cardiopartners.com.transuat|Christian|Hernandez|christian.hernandez@cardiopartners.com.transuat');
            records.add('001d000001QuLKHAA3|0005|a3J21000000HXXX|C|Isaac|Barker||800-345-4444|Successful||ibarker123@maildrop.cc');
            records.add('001d000001QuLKHAA3|0005|a3J21000000HXXX|C|Suzanne|Miller||800-123-4444|Successful|smiller123@maildrop.cc');

            testBatchService.processData(records);

            */
            
            test.stopTest();
			
        }
   
    }   

}