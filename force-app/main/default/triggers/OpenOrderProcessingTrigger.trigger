/*************************************************************************************

Developer  :  cvaughan@salesforce.com
Created    :  01/26/2020
Objective  :  Delegate all trigger events for the Open_Order_Processing__c object
Notes      :  

*************************************************************************************/

trigger OpenOrderProcessingTrigger on Open_Order_Processing__c (after insert, after update) {
    system.debug('@@@OpenOrderProcessingTrigger start...');
    if (!PHSS_TriggerSettings__c.getOrgDefaults().Open_Order_Processing_Trigger_Disabled__c) {
        OpenOrderProcessingTriggerHandler handler = new OpenOrderProcessingTriggerHandler();
        if (Trigger.isAfter && Trigger.isInsert) {
            handler.onAfterInsert(Trigger.new);
        } 
        else if (Trigger.isAfter && Trigger.isUpdate) {
            system.debug('@@@OpenOrderProcessingTrigger after update...');
            handler.onAfterUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
        }
    }
}