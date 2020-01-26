trigger LearningPlanAssignmentTriggerTS on redwing__Training_Plan_Assignment__c (after insert)
{
    if(!PHSS_TriggerSettings__c.getOrgDefaults().LearningPlanAssignmentTriggerTSDisable__c)
    {
        if(Trigger.IsInsert)
        {
            LearningPlanAssignmentTriggerHandler.OnAfterInsert(Trigger.New);
        }
    }
}