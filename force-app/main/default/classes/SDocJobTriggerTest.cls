@isTest
public class SDocJobTriggerTest
{
    @isTest
    private static void testSDocJobTriggerTest()
    {
        SDOC__SDJob__c sdjob = new SDOC__SDJob__c (SDOC__Status__c = 'Completed');
        insert sdjob;
    }

}