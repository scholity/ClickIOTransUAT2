@isTest(SeeAllData=false)
public with sharing class OpenOrderProcessingTriggerHandlerTest {
    
    private static Open_Order_Processing__c testOOP;

    private static Open_Order_Processing__c testOOP2;
    
    private static Open_Order_Processing__c testOOP3;

    private static Account testAccount;

    private static ccrz__E_Order__c testOrder;

    private static void generateTestData(){

        testAccount = new Account(
            Name				 = 'SalesforcetestOrg1',
            BillingStreet		 = '24 Willie Mays Plaza',
            BillingCity			 = 'San Francisco',
            BillingState		 = 'California',
            BillingPostalCode	 = '94017',
            BillingCountry		 = 'USA',
            Phone				 = '9934200234',
            Open_Order_Amount__c = 10        
        );
        insert testAccount;
        
        redwing__Learning__c testLearning = new redwing__Learning__c(
            Name 					= 'testLearning',
            redwing__Published__c 	= true,
            RecordTypeId 			= Schema.SObjectType.redwing__Learning__c.getRecordTypeInfosByName().get('ILT Event').getRecordTypeId()
        );
        insert testLearning;
        
        redwing__Training_Plan__c testLearningPlan = new redwing__Training_Plan__c(
                Name = 'testLearningPlan'
            );
        insert testLearningPlan;
        
        Redwing__ILT_Class__c testITLClass = new Redwing__ILT_Class__c(
            Skedulo_Account__c 		= testAccount.Id,
            redwing__End_Date__c 	= Date.Parse('12/19/2018'),
            redwing__End_Time__c	= '13:00',
            redwing__Start_Date__c 	= Date.Parse('12/19/2018'),
            redwing__Start_Time__c 	= '12:00',
            Name 					= 'testITLClass',
            Request_Type__c			= 'Community',
            redwing__Learning__c 	= testLearning.Id
        );
        insert testITLClass;
        
        ccrz__E_Product__c testProduct = new ccrz__E_Product__c(
            Name 						= 'Test Prod',
            ccrz__SKU__c 				= String.ValueOf(System.Now()),
            ccrz__Quantityperunit__c 	= 2.0,
            ccrz__StartDate__c 			= System.Today().addDays(2),
            ccrz__EndDate__c 			= System.Today().addDays(20),
            LMS_Learning_Plan__c 		= testLearningPlan.id,
            //CC_Category__c = ccCategory.Id,
            AP_Code__c 					= '6243',
            ccrz__InventoryType__c 		= 'COURSE',
            ccrz__ProductType__c 		= 'KIT'
        );
        insert testProduct;

        testOrder = new ccrz__E_Order__c(
            NSSCCConnector_SFCC_Order_Number__c = '3114226',
            NSSCCConnector_from_SFCC__c 		= true,
            ccrz__Account__c 					= testAccount.Id
            //ccrz__ShipAmount__c 				= 5
        );
        insert testOrder;
        
        ccrz__E_Order__c testOrder1 = new ccrz__E_Order__c(
            NSSCCConnector_SFCC_Order_Number__c = '3114227',
            NSSCCConnector_from_SFCC__c 		= true
            //ccrz__ShipAmount__c 				= 5
        );
        insert testOrder1;
        
        ccrz__E_OrderItem__c testOrderItem = new ccrz__E_OrderItem__c(
            ccrz__Product__c 	= testProduct.Id,
            ccrz__Order__c 		= testOrder.id,
            ccrz__Price__c		= 1,
            ccrz__Quantity__c	= 1,
            ccrz__SubAmount__c	= 10,
            ILT_Class__c 		= testITLClass.Id
        );
        insert testOrderItem;
        
        ccrz__E_OrderItem__c testOrderItem1 = new ccrz__E_OrderItem__c(
            ccrz__Product__c 	= testProduct.Id,
            ccrz__Order__c 		= testOrder1.id,
            ccrz__Price__c		= 10,
            ccrz__Quantity__c	= 1,
            ccrz__SubAmount__c	= 10,
            ILT_Class__c 		= testITLClass.Id
        );
        insert testOrderItem1;
        
        ccrz__E_StoredPayment__c sPayment = new ccrz__E_StoredPayment__c(Name 				 	= 'test',
                                                                         ccrz__Enabled__c  		= true,
                                                                         Original_PO_Amount__c 	= 10000.00);
        
        ccrz__E_TransactionPayment__c testTransactionPayment = new ccrz__E_TransactionPayment__c(ccrz__AccountType__c 	 = 'po',                                                                                
                                                                                                 ccrz__CCOrder__c		 = testOrder.Id,
                                                                                                 ccrz__StoredPayment__c	 = sPayment.Id,
                                                                                                 ccrz__Amount__c		 = 10,
                                                                                                 ccrz__Account__c		 = testAccount.Id);
        insert testTransactionPayment;
        
        Fulfillment__c testFulfillment  = new Fulfillment__c(
            Type__c						= 'Invoice',
            Status__c					= 'Open',
            Order__c 					= testOrder.Id,
            CC_Transaction_Payment__c	= testTransactionPayment.Id
        );
        insert testFulfillment;
        
        Fulfillment_Item__c testFulfillmentItem = new Fulfillment_Item__c(
            Type__c 					= 'Training',
            Status__c 					= 'Ready',
            Fulfillment__c 				= testFulfillment.Id,
            Order__c 					= testOrder.Id,
            Order_Item__c 				= testOrderItem.Id,
            CC_Product__c 				= testProduct.Id,
            Quantity__c 				= 1,
            Supplemental_Information__c = 'Test123'
        );
        
        insert testFulfillmentItem;
        
        Fulfillment_Item__c testFulfillmentItem1 = new Fulfillment_Item__c(
            Type__c 					= 'Training',
            Status__c 					= 'Ready',
            Fulfillment__c				= testFulfillment.Id,
            Order__c 					= testOrder1.Id,
            Order_Item__c 				= testOrderItem1.Id,
            CC_Product__c 				= testProduct.Id,
            Supplemental_Information__c = 'Test123'
        );
        
        insert testFulfillmentItem1;

        testOrder = [SELECT Id, Name, ccrz__TotalAmount__c FROM ccrz__E_Order__c WHERE Id = :testOrder.Id];

        testOOP 			= new Open_Order_Processing__c(
            Name 			= 'Test OOP',
            Invoice_Date__c = Date.today(),
            SFDC_Account__c = string.valueOf(testFulfillmentItem.Id),
            CC_Order__c 	= testOrder.Name,
            Status__c 		= 'New'
        );  

        testOOP2 			= new Open_Order_Processing__c(
            Name 			= 'Test OOP2',
            Invoice_Date__c = Date.today(),
            SFDC_Account__c = null,
            CC_Order__c		= null,
            Status__c 		= 'New'
        );
        testOOP3 			= new Open_Order_Processing__c(
            Name 			= 'Test OOP3',
            Invoice_Date__c = Date.today(),
            SFDC_Account__c = string.valueOf(testFulfillmentItem1.Id),
            CC_Order__c		= null,
            Status__c 		= 'New'
        ); 
        insert new List<Open_Order_Processing__c>{testOOP, testOOP2,testOOP3};
    }

    @isTest static void testprocessOpenOrderFromInvoice(){
        
        generateTestData();

        Test.startTest();

        testOOP.Status__c = OpenOrderProcessingTriggerHandler.OOP_STATUS_INVOICED;

        update testOOP; //this should succeed

        testOOP2.Status__c = OpenOrderProcessingTriggerHandler.OOP_STATUS_INVOICED;

        update testOOP2; //this should be an error status
        
        testOOP3.Status__c = OpenOrderProcessingTriggerHandler.OOP_STATUS_INVOICED;

        update testOOP3; //this should be an error status

        Test.stopTest();

        testOOP2 = [SELECT Id, Status__c FROM Open_Order_Processing__c WHERE Id = :testOOP2.Id];

        system.assertEquals(testOOP2.Status__c, OpenOrderProcessingTriggerHandler.OOP_STATUS_ERROR);

        testOOP = [SELECT Id, Status__c FROM Open_Order_Processing__c WHERE Id = :testOOP.Id];

        system.assertEquals(testOOP.Status__c, OpenOrderProcessingTriggerHandler.OOP_STATUS_UPDATED);

        

        List<Account> AccountList = [SELECT Id, Open_Order_Amount__c FROM Account WHERE Id = :testAccount.Id];
        
        Decimal expectedOpenOrderAmount = AccountList[0].Open_Order_Amount__c - testOrder.ccrz__TotalAmount__c;
        
        /*In the test class we are placing an order on PO so it increase the Open order amount the account
        Due to this Open order amount will remain same when this test class runs.*/
        
        system.assertEquals(AccountList[0].Open_Order_Amount__c, 10);
        
    }
}