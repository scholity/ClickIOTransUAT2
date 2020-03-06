/*************************************************************************************

Class      :  OpenOrderProcessingTriggerHandler.cls
Developer  :  cvaughan@salesforce.com
Created    :  01/26/2020
Objective  :  Trigger handler class for the Open_Order_Processing__c object
Test Class :  OpenOrderProcessingTriggerHandlerTest.cls
Notes      :  Instantiated from OpenOrderProcessingTrigger.trigger

*************************************************************************************/

public with sharing class OpenOrderProcessingTriggerHandler {
    
    @testVisible
    private static final String OOP_STATUS_INVOICED = 'Invoiced';

    @testVisible
    private static final String OOP_STATUS_UPDATED = 'Updated';

    @testVisible
    private static final String OOP_STATUS_ERROR = 'Error';

    /**
    * Method Name: onAfterInsert
    * Method Description: handle all After Insert tigger operations
    */ 
    public void onAfterInsert(List<Open_Order_Processing__c> newOpenOrderProcessings){
        processOpenOrderFromInvoice(newOpenOrderProcessings, null);
    }

    /**
    * Method Name: onAfterUpdate
    * Method Description: handle all After Update tigger operations
    */ 
    public void onAfterUpdate(List<Open_Order_Processing__c> newOpenOrderProcessings, List<Open_Order_Processing__c> oldOpenOrderProcessings, Map<ID, Open_Order_Processing__c> newOpenOrderProcessingMap , Map<ID, Open_Order_Processing__c> oldOpenOrderProcessingMap){
        processOpenOrderFromInvoice(newOpenOrderProcessings, oldOpenOrderProcessings);
    }

    /**
    * Method Name: processOpenOrderFromInvoice
    * Method Description: update account Open_Order_Amount__c when an Open_Order_Processing__c is invoiced
    * @param newOpenOrderProcessings: List of newly inserted/updated Open_Order_Processing__c records
    * @param oldOpenOrderProcessings: List of Open_Order_Processing__c records containing state prior to insert or update
    */
    private void processOpenOrderFromInvoice(List<Open_Order_Processing__c> newOpenOrderProcessings, List<Open_Order_Processing__c> oldOpenOrderProcessings){
        
        Map<Id, Open_Order_Processing__c> newOpenOrderProcessingMap = new Map<Id, Open_Order_Processing__c>(newOpenOrderProcessings);

        Map<Id, Open_Order_Processing__c> oldOpenOrderProcessingMap = ( oldOpenOrderProcessings == null ? null : new Map<Id, Open_Order_Processing__c>(oldOpenOrderProcessings) );

        List<Open_Order_Processing__c> invoicedOpenOrderProcessing = new List<Open_Order_Processing__c>();

        for(Id oopId : newOpenOrderProcessingMap.keySet())
        {
            Open_Order_Processing__c newOOP = newOpenOrderProcessingMap.get(oopId);
            if(OOP_STATUS_INVOICED.equalsIgnoreCase(newOOP.Status__c)){ //check new status = Invoiced
                Open_Order_Processing__c oldOOP = ( oldOpenOrderProcessingMap != null ? oldOpenOrderProcessingMap.get(oopId) : null );
                if(oldOOP == null //is insert
                    || (oldOOP != null //is update && old status != Invoiced
                        && !OOP_STATUS_INVOICED.equalsIgnoreCase(oldOOP.Status__c)) ){

                    invoicedOpenOrderProcessing.add(newOOP);
                }
            }
        }

        system.debug('@@@invoicedOpenOrderProcessing: '+invoicedOpenOrderProcessing);
        
        if(!invoicedOpenOrderProcessing.isEmpty())
        {
            //Set<String> ccOrderNames = new Set<String>();
            Set<Id> fiIds                   = new Set<Id>();
            Map<Id, String> oopErrorMap     = new Map<Id, String>();
            Map<Id, Id> fiToOopMap          = new Map<Id, Id>();

            for(Open_Order_Processing__c oop : invoicedOpenOrderProcessing)
            {
                //ccOrderNames.add(oop.CC_Order__c);
                system.debug('oop***'+oop);
                system.debug('oop.SFDC_Account__c***'+oop.SFDC_Account__c);
                
                if(oop.SFDC_Account__c instanceof Id)
                {
                    String sObjName = Id.valueOf(oop.SFDC_Account__c).getSObjectType().getDescribe().getName();

                    system.debug('***sObjName***'+sObjName);

                    if(sObjName == 'Fulfillment_Item__c')
                    {
                        fiIds.add(oop.SFDC_Account__c);
                        fiToOopMap.put(oop.SFDC_Account__c, oop.Id);
                    }
                }
                else
                {
                    oopErrorMap.put(oop.Id, Label.Open_Order_Processing_Error_No_Order);
                }
            }

            system.debug('***fiIds***' +fiIds);
            system.debug('***fiToOopMap***' +fiToOopMap);

            List<Fulfillment_Item__c> fulfilementItemList = [SELECT Id,
                                                                    Order_Item__c,
                                                                    Order_Item__r.ccrz__ItemTotal__c,
                                                                    Order__r.ccrz__Account__c,
                                                                    Order__r.ccrz__Account__r.Open_Order_Amount__c
                                                               FROM Fulfillment_Item__c
                                                              WHERE Id IN : fiIds];


            List<Account> accountsToUpdate  = new List<Account>();
            List<Id> oopSuccesses           = new List<id>();

            for(Fulfillment_Item__c fi : fulfilementItemList)
            {
                if(fi.Order__r.ccrz__Account__c != null)
                {
                    Account thisAccount                 = new Account();
                    thisAccount.Id                      = fi.Order__r.ccrz__Account__c;
                    Decimal orderAmount                 = fi.Order_Item__r.ccrz__ItemTotal__c == null ? 0 : fi.Order_Item__r.ccrz__ItemTotal__c;
                    Decimal accountTotal                = fi.Order__r.ccrz__Account__r.Open_Order_Amount__c == null ? 0 : fi.Order__r.ccrz__Account__r.Open_Order_Amount__c;
                    Decimal newTotal                    = accountTotal - orderAmount;
                    thisAccount.Open_Order_Amount__c    = newTotal;
                    system.debug('accountTotal>>>'+accountTotal);
                    system.debug('orderAmount>>>'+orderAmount);
                    system.debug('newTotal>>>'+newTotal);
                    accountsToUpdate.add(thisAccount);
                    oopSuccesses.add(fiToOopMap.get(fi.Id));
                }
                else
                {
                    oopErrorMap.put(fiToOopMap.get(fi.Id), Label.Open_Order_Processing_Error_No_Account);
                }
            }
            
            /*List<ccrz__E_Order__c> ccOrders = new List<ccrz__E_Order__c>([
                SELECT Id, Name, ccrz__Account__c, ccrz__TotalAmount__c, ccrz__Account__r.Open_Order_Amount__c
                FROM ccrz__E_Order__c
                WHERE Name IN :ccOrderNames
            ]);
            
            Map<String, ccrz__E_Order__c> ccOrderMap = new Map<String, ccrz__E_Order__c>();
            for(ccrz__E_Order__c ccOrder : ccOrders){
                ccOrderMap.put(ccOrder.Name, ccOrder);
            }*/
            
            /*Map<Id, Account> accountMap = new Map<Id, Account>([
                SELECT Id, Account_Status__c, Open_Order_Amount__c
                FROM Account
                WHERE Id IN :accountIds
            ]);
            
            //List<Account> accountsToUpdate  = new List<Account>();
            //Map<Id, String> oopErrorMap     = new Map<Id, String>();
            //List<Id> oopSuccesses           = new List<id>();

            for(Open_Order_Processing__c oop : invoicedOpenOrderProcessing)
            {
                if(oop.SFDC_Account__c != null)
                { //has an order
                    //if(accountMap.containsKey(oop.SFDC_Account__c)){ //has an account
                        //ccrz__E_Order__c thisOrder          = ccOrderMap.get(oop.CC_Order__c);
                        
                        Account thisAccount                 = new Account();
                        //thisAccount.Id                      = thisOrder.ccrz__Account__c;
                        //Account thisAccount                 = thisOrder.ccrz__Account__c; //accountMap.get(oop.SFDC_Account__c);
                        //Decimal orderAmount                 = thisOrder.ccrz__TotalAmount__c == null ? 0 : thisOrder.ccrz__TotalAmount__c;
                        //Decimal accountTotal                = thisOrder.ccrz__Account__r.Open_Order_Amount__c == null ? 0 : thisOrder.ccrz__Account__r.Open_Order_Amount__c;
                        //Decimal newTotal                    = accountTotal - orderAmount;
                        
                        //thisAccount.Open_Order_Amount__c    = newTotal;

                        accountsToUpdate.add(thisAccount);
                        oopSuccesses.add(oop.Id);
                    }
                    else{ //no account found, add error
                        oopErrorMap.put(oop.Id, Label.Open_Order_Processing_Error_No_Account);
                    }
                }
                else{ //no order found, add error
                    oopErrorMap.put(oop.Id, Label.Open_Order_Processing_Error_No_Order);
                }
            }*/
            if(!accountsToUpdate.isEmpty()){
                update accountsToUpdate;
            }
            updateOpenOrderProcessingAsync(oopSuccesses, oopErrorMap);
        }
        //}
    }

    /**
    * Method Name: updateOpenOrderProcessingAsync
    * Method Description: update Open_Order_Processing__c record status and error message async to avoid locked row issues
    * @param successes: Open_Order_Processing__c records successfully processed
    * @param errors: Open_Order_Processing__c records with error status
    */
    @future
    private static void updateOpenOrderProcessingAsync(List<Id> successes, Map<Id, String> errors){
        List<Open_Order_Processing__c> oopToUpdate = new List<Open_Order_Processing__c>();
        for(Id oopId : successes){
            oopToUpdate.add(
                new Open_Order_Processing__c(
                    Id                  = oopId,
                    Status__c           = OOP_STATUS_UPDATED,
                    Error_Message__c    = null
                )
            );
        }
        for(Id oopId : errors.keySet()){
            oopToUpdate.add(
                new Open_Order_Processing__c(
                    Id                  = oopId,
                    Status__c           = OOP_STATUS_ERROR,
                    Error_Message__c    = errors.get(oopId)
                )
            );
        }
        if(!oopToUpdate.isEmpty()){
            update oopToUpdate;
        }
    }

}