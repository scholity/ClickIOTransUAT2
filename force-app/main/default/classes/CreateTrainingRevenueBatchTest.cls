@isTest
public class CreateTrainingRevenueBatchTest
{
    private static Account testAccount;

    private static Fulfillment_Item__c testFulfillmentItem;

    //TODO: This setup code is being used in a number of places. Should consolidate into a test util
    private static void generateTestData(){
        
        testAccount = new Account(
            Name='SalesforcetestOrg1',
            BillingStreet='24 Willie Mays Plaza',
            BillingCity='San Francisco',
            BillingState='California',
            BillingPostalCode='94017',
            BillingCountry='USA',
            Phone='9934200234',
            Open_Order_Amount__c = 1        
        );
        insert testAccount;

        redwing__Learning__c testLearning = new redwing__Learning__c(
            Name = 'testLearning',
            redwing__Published__c = true,
            RecordTypeId = Schema.SObjectType.redwing__Learning__c.getRecordTypeInfosByName().get('ILT Event').getRecordTypeId()
        );
        insert testLearning;
        
        Redwing__ILT_Class__c testITLClass = new Redwing__ILT_Class__c(
            Skedulo_Account__c = testAccount.Id,
            redwing__End_Date__c = Date.Parse('12/19/2018'),
            redwing__End_Time__c= '13:00',
            redwing__Start_Date__c = Date.Parse('12/19/2018'),
            redwing__Start_Time__c = '12:00',
            Name = 'testITLClass',
            Request_Type__c='Community',
            redwing__Learning__c = testLearning.Id
        );
        insert testITLClass;
        
        redwing__ILT_Instructor__c testInstructor = new redwing__ILT_Instructor__c(
            redwing__Instructor__c = UserInfo.getUserId(),
            redwing__ILT_Class__c = testITLClass.id,
            redwing__Primary__c = true
        );
        
        redwing__ILT_Instructor__c testInstructor2 = new redwing__ILT_Instructor__c(
            redwing__Instructor__c = UserInfo.getUserId(),
            redwing__ILT_Class__c = testITLClass.id,
            redwing__Primary__c = false
        );
        insert new List<redwing__ILT_Instructor__c>{testInstructor, testInstructor2};
            
        redwing__Training_Plan__c testLearningPlan = new redwing__Training_Plan__c(
            Name = 'testLearningPlan'
        );
        insert testLearningPlan;
        
        ccrz__E_Product__c testProduct = new ccrz__E_Product__c(
            Name = 'Test Prod',
            ccrz__SKU__c = String.ValueOf(System.Now()),
            ccrz__Quantityperunit__c = 2.0,
            ccrz__StartDate__c =  System.Today().addDays(2),
            ccrz__EndDate__c = System.Today().addDays(20),
            LMS_Learning_Plan__c = testLearningPlan.id
        );
        insert testProduct;
        
        ccrz__E_TransactionPayment__c testTransactionPayment = new ccrz__E_TransactionPayment__c(
            ccrz__AccountType__c = 'po',
            ccrz__Amount__c = 1,
            ccrz__Account__c = testAccount.Id
        );
        insert testTransactionPayment;
        
        ccrz__E_Order__c testOrder = new ccrz__E_Order__c(
            NSSCCConnector_SFCC_Order_Number__c = '3114226',
            NSSCCConnector_from_SFCC__c = true,
            ccrz__Account__c = testAccount.Id
        );
        insert testOrder;
        
        ccrz__E_OrderItem__c testOrderItem = new ccrz__E_OrderItem__c(
            ccrz__Product__c = testProduct.Id,
            Payment_Category__c = '',
            ccrz__Order__c = testOrder.id,
            ccrz__Price__c=100,
            ccrz__Quantity__c=100.00,
            ccrz__SubAmount__c=100.00,
            ILT_Class__c = testITLClass.Id
        );
        insert testOrderItem;
        
        Fulfillment__c testFulfillment = new Fulfillment__c(
            Type__c='Invoice',
            Status__c='Open',
            Order__c = testOrder.Id,
            CC_Transaction_Payment__c= testTransactionPayment.Id
        );
        insert testFulfillment;

        testFulfillmentItem = new Fulfillment_Item__c(
            Type__c = 'Training',
            Status__c ='Invoiced',
            Fulfillment__c = testFulfillment.Id,
            Order__c = testOrder.Id,
            Order_Item__c = testOrderItem.Id,
            CC_Product__c = testProduct.Id,
            ILT_Class__c = testITLClass.Id,
            Quantity__c = 1,
            Supplemental_Information__c = 'Test123',
            Fulfillment_Date__c = Date.Today()
        );
        insert testFulfillmentItem;
    }
    
    @isTest static void testCreateTrainingRevenueRecords(){

        generateTestData();
        
        Test.startTest();
        CreateTrainingRevenueBatch trBatch = new CreateTrainingRevenueBatch();
		database.executeBatch(trBatch,100);
        Test.stopTest();

        //Channel_Compensation__c newChannelCompensation = [SELECT Id FROM Channel_Compensation__c WHERE Fulfillment_Item__c = :testFulfillmentItem.Id LIMIT 1];

        //system.assertNotEquals(newChannelCompensation, null);

        
    }
    
    @isTest 
    public static void testSchedule()
	{
		String CRON_EXP = '0 0 0 15 3 ? 2022';
		Test.startTest();
		System.schedule('ScheduleApexClassTest', CRON_EXP, new CreateTrainingRevenueSchedule());
		Test.stopTest();
	}

}