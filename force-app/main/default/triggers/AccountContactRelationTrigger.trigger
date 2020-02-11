trigger AccountContactRelationTrigger on AccountContactRelation (after insert, after update) {
    if(!PHSS_TriggerSettings__c.getOrgDefaults().AccountContactRelationTrigger_Disabled__c){
        AccountContactRelationTriggerHandler handler = new AccountContactRelationTriggerHandler();
        if(Trigger.isAfter && Trigger.isInsert){
            handler.onAfterInsert(Trigger.new);
        } 
        else if(Trigger.isAfter && Trigger.isUpdate){
            handler.onAfterUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
        }
    }
}