@isTest(SeeAllData=true)
private class TestPHSS_ClassCompletionService
{   
    @isTest static  void testGetCallout()
    {
        
        Account acc = [SELECT Id FROM Account WHERE RecordType.Name = 'SB Organization Account' AND Name LIKE 'SB_Test LTP%' LIMIT 1];
        String fileContent =
    			  acc.Id + '|0005|a3J21000000HXXX|A|' + acc.Id + '|Cardio Partners, Inc.|My Test PO|AP-HSSSFA401|02/11/2020|02/11/2020|4|Cardio Partners, Inc. HQ|6105 Rockwell Dr. NE|Cedar Rapids|IA|52402\n'
                + acc.Id + '|0005|a3J21000000HXXX|B|figaroadmin123@maildrop.cc|SB_TEST Figaro1|Admin|figaroadmin123@maildrop.cc\n'
                + acc.Id + '|0005|a3J21000000HXXX|C|Isaac|Barker||800-345-4444|Successful|test note\n';
                      
            test.startTest();
            
                RestRequest req = new RestRequest();
                RestResponse res = new RestResponse();
                
                req.requestURI = '/services/apexrest/PHSSClassCompletion/batch/';
                req.httpMethod = 'POST';
                req.requestBody = Blob.valueof(fileContent);
                RestContext.request = req;
                RestContext.response= res;
                
                PHSS_ClassCompletionService.process();
                
                PHSS_ClassCompletionResponseWrapper rw = new PHSS_ClassCompletionResponseWrapper();
                rw.account_Id = acc.Id;
                rw.batch_Id = '0005';
                rw.offering_Id= '';
                rw.student_achievement = '';
                rw.student_achievement_createDate = '';
                rw.student_certCompletionQRCode = '';
                rw.student_firstName = '';
                rw.student_lastName = '';
                rw.student_notes = '';

            test.stopTest();
        }
}