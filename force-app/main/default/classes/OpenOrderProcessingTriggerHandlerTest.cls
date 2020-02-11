@isTest(SeeAllData=false)
public with sharing class OpenOrderProcessingTriggerHandlerTest {
    
    private static Open_Order_Processing__c testOOP;

    private static Open_Order_Processing__c testOOP2;

    private static Account testAccount;

    private static ccrz__E_Order__c testOrder;

    private static void generateTestData(){

        testAccount = new Account(
            Name='SalesforcetestOrg1',
            BillingStreet='24 Willie Mays Plaza',
            BillingCity='San Francisco',
            BillingState='California',
            BillingPostalCode='94017',
            BillingCountry='USA',
            Phone='9934200234',
            Open_Order_Amount__c = 10        
        );
        insert testAccount;

        testOrder = new ccrz__E_Order__c(
            NSSCCConnector_SFCC_Order_Number__c = '3114226',
            NSSCCConnector_from_SFCC__c = true,
            ccrz__Account__c = testAccount.Id,
            ccrz__ShipAmount__c = 5
        );
        insert testOrder;

        testOrder = [SELECT Id, Name, ccrz__TotalAmount__c FROM ccrz__E_Order__c WHERE Id = :testOrder.Id];

        testOOP = new Open_Order_Processing__c(
            Name = 'Test OOP',
            Invoice_Date__c = Date.today(),
            SFDC_Account__c = testAccount.Id,
            CC_Order__c = testOrder.Name,
            Status__c = 'New'
        );  

        testOOP2 = new Open_Order_Processing__c(
            Name = 'Test OOP2',
            Invoice_Date__c = Date.today(),
            SFDC_Account__c = null,
            CC_Order__c = null,
            Status__c = 'New'
        );  
        insert new List<Open_Order_Processing__c>{testOOP, testOOP2};
    }

    @isTest static void testprocessOpenOrderFromInvoice(){
        
        generateTestData();

        Test.startTest();

        testOOP.Status__c = OpenOrderProcessingTriggerHandler.OOP_STATUS_INVOICED;

        update testOOP; //this should succeed

        testOOP2.Status__c = OpenOrderProcessingTriggerHandler.OOP_STATUS_INVOICED;

        update testOOP2; //this should be an error status

        Test.stopTest();

        testOOP2 = [SELECT Id, Status__c FROM Open_Order_Processing__c WHERE Id = :testOOP2.Id];

        system.assertEquals(testOOP2.Status__c, OpenOrderProcessingTriggerHandler.OOP_STATUS_ERROR);

        testOOP = [SELECT Id, Status__c FROM Open_Order_Processing__c WHERE Id = :testOOP.Id];

        system.assertEquals(testOOP.Status__c, OpenOrderProcessingTriggerHandler.OOP_STATUS_UPDATED);

        Decimal expectedOpenOrderAmount = testAccount.Open_Order_Amount__c - testOrder.ccrz__TotalAmount__c;

        testAccount = [SELECT Id, Open_Order_Amount__c FROM Account WHERE Id = :testAccount.Id];

        system.assertEquals(testAccount.Open_Order_Amount__c, expectedOpenOrderAmount);
        
    }
}