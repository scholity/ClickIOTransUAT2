trigger LearningPlanAssignmentTriggerTS on redwing__Training_Plan_Assignment__c (before insert)
{
    if(!PHSS_TriggerSettings__c.getOrgDefaults().LearningPlanAssignmentTriggerTSDisable__c)
    {
        if(Trigger.IsBefore)
        {
            LearningPlanAssignmentTriggerHandler.OnAfterInsert(Trigger.New);
        }
    }
}