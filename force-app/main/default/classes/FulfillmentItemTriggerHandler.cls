/*************************************************************************************

Class      :  FulfillmentItemTriggerHandler.cls
Developer  :  cvaughan@salesforce.com
Created    :  01/26/2020
Objective  :  Trigger handler class for the Fulfillment_Item__c object
Test Class :  FulfillmentItemTriggerHandlerTest.cls
Notes      :  Instantiated from FulfillmentItemTrigger.trigger

*************************************************************************************/

public with sharing class FulfillmentItemTriggerHandler {

    @testVisible
    private static final String FULFILLMENT_ITEM_STATUS_INVOICED = 'Invoiced';
	
    @testVisible
    private static map<Integer, String> fiscalMothAbbreviationMap = new Map<Integer, String>{
        1 => 'JAN', 2 => 'FEB', 3 => 'MAR', 4 => 'APR',
        5 => 'MAY', 6 => 'JUN', 7 => 'JUL', 8 => 'AUG',
        9 => 'SEP', 10=> 'OCT', 11=> 'NOV', 12=> 'DEC'
    };
    
    /**
    * Method Name: onAfterInsert
    * Method Description: handle all After Insert tigger operations
    */ 
    public void onAfterInsert(List<Fulfillment_Item__c> newFulfillmentItems){
        createTrainingRevenueRecords(newFulfillmentItems, null);
    }

    /**
    * Method Name: onAfterUpdate
    * Method Description: handle all After Update tigger operations
    */ 
    public void onAfterUpdate(List<Fulfillment_Item__c> newFulfillmentItems, List<Fulfillment_Item__c> oldFulfillmentItems, Map<ID, Fulfillment_Item__c> newFulfillmentItemMap , Map<ID, Fulfillment_Item__c> oldFulfillmentItemMap){
        createTrainingRevenueRecords(newFulfillmentItems, oldFulfillmentItems);
    }

    /**
    * Method Name: createTrainingRevenueRecords
    * Method Description: create a Training Revenue (Channel_Compensation__c) records from a Fulfillment_Item__c records
    * @param newFulfillmentItems: List of newly inserted/updated Fulfillment_Item__c records
    * @param oldFulfillmentItems: List of Fulfillment_Item__c records containing state prior to insert or update
    */
    @testVisible
    private void createTrainingRevenueRecords(List<Fulfillment_Item__c> newFulfillmentItems, List<Fulfillment_Item__c> oldFulfillmentItems){

        Map<Id, Fulfillment_Item__c> newFulfillmentItemMap = new Map<Id, Fulfillment_Item__c>(newFulfillmentItems);

        Map<Id, Fulfillment_Item__c> oldFulfillmentItemMap = ( oldFulfillmentItems == null ? null : new Map<Id, Fulfillment_Item__c>(oldFulfillmentItems) );

        List<Fulfillment_Item__c> fulfillmentItemsToProcess = new List<Fulfillment_Item__c>();

        for(Id fulfillmentItemId : newFulfillmentItemMap.keySet()){
            Fulfillment_Item__c newFI = newFulfillmentItemMap.get(fulfillmentItemId);
            if(FULFILLMENT_ITEM_STATUS_INVOICED.equalsIgnoreCase(newFI.Status__c)){ //check new status = Invoiced
                Fulfillment_Item__c oldFI = ( oldFulfillmentItemMap != null ? oldFulfillmentItemMap.get(fulfillmentItemId) : null );
                if(oldFI == null //is insert
                    || (oldFI != null //is update && old status != Invoiced
                        && !FULFILLMENT_ITEM_STATUS_INVOICED.equalsIgnoreCase(oldFI.Status__c)) ){

                    fulfillmentItemsToProcess.add(newFI);
                }
            }
            if(!fulfillmentItemsToProcess.isEmpty()){
                List<Channel_Compensation__c> trainingRevenueRecordsToInsert = new List<Channel_Compensation__c>();
                for(Fulfillment_Item__c fi : fulfillmentItemsToProcess){
                    trainingRevenueRecordsToInsert.add(
                        new Channel_Compensation__c(
                            Account__c = fi.Order__r.ccrz__Account__c,
                            //BATCH_Id__c = fi.Fulfillment_Date__c,
                            BATCH_Id__c = date.today(),
                            Channel__c = (fi.Fulfillment__c != null ? fi.Fulfillment__r.Channel_Formula__c : null),
                            Data_Source__c = fi.Order__r.ccrz__Storefront__c,
                            End_Date__c = Date.valueOf(fi.Transaction_Date__c),
                            FOCIS_Category__c = (fi.Fulfillment__c != null ? fi.Fulfillment__r.FOCIS_Category__c : null),
                            FOCIS_Subject_Area__c = fi.CC_Product__r.ccrz__SKU__c,
                            //Fiscal_Month_Abbr__c = fiscalMothAbbreviationMap.get(fi.Fulfillment_Date__c.month()),
                            Fiscal_Month_Abbr__c = fiscalMothAbbreviationMap.get(date.today().month()),
                            Focis_Location__c = fi.Opportunity_Profile__c,
                            Focis_Program__c = fi.CC_Product__r.Product_3__c,
                            Fulfillment_Item__c = fi.Id,
                            Org_Id__c = (String.isNotBlank(fi.Order__r.ccrz__Account__r.SABA_LMS_Code__c) ? fi.Order__r.ccrz__Account__r.SABA_LMS_Code__c : null),
                            Org_Name__c = fi.Order__r.ccrz__Account__r.Name,
                            Org_Type__c = fi.Order__r.ccrz__Account__r.SABA_Org_Type__c,
                            Registration_Count__c = fi.Quantity__c,
                            State__c = fi.State_Formula__c,
                            SubPG__c = fi.CC_Product__r.Product_2__c,
                            Transaction_Amt__c = fi.Fulfillment_Item_Total__c,
                            User_Field__c = fi.Opportunity_Owner_Email__c,
                            Zip_Code__c = fi.Zip_Formula__c
                        )
                    );
                }
                insert(trainingRevenueRecordsToInsert);
            }
        }
    }
}