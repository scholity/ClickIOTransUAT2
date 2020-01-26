trigger SDocJobTrigger on SDOC__SDJob__c (before insert)
{
    for (SDOC__SDJob__c sdjob : trigger.new)
    {
        sdjob.SDOC__Email_Params__c = '&useExistingNoContactRecord=true';
        //sdjob.SDOC__RunAs__c        = System.Label.SDocsRunAsUserName;
    }
}