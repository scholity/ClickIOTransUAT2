trigger SDocJobTrigger on SDOC__SDJob__c (before insert)
{
    for (SDOC__SDJob__c sdjob : trigger.new)
    {
        if(sdjob.Email_To__c != null)
        {
            sdjob.SDOC__Email_Params__c = '&useExistingNoContactRecord=true&emailTo='+sdjob.Email_To__c;
        }
        else
        {
            sdjob.SDOC__Email_Params__c = '&useExistingNoContactRecord=true';
        }
        
    }
}