/*************************************************************************************

Developer  :  cvaughan@salesforce.com
Created    :  01/26/2020
Objective  :  Delegate all trigger events for the Fulfillment_Item__c object
Notes      :  

*************************************************************************************/

trigger FulfillmentItemTrigger on Fulfillment_Item__c (after insert, after update) {
    if (!PHSS_TriggerSettings__c.getOrgDefaults().Fulfillment_Item_Trigger_Disabled__c	) {
        FulfillmentItemTriggerHandler handler = new FulfillmentItemTriggerHandler();
        if (Trigger.isAfter && Trigger.isInsert) {
            handler.onAfterInsert(Trigger.new);
        } 
        else if (Trigger.isAfter && Trigger.isUpdate) {
            handler.onAfterUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
        }
    }
}