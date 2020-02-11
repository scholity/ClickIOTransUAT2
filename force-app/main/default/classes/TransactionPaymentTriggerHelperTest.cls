@isTest
public class TransactionPaymentTriggerHelperTest
{
    @testSetup 
    public static void initTestData()
    {
        Account a = new Account();
        a.Name='SalesforcetestOrg';
        a.DM_External_Id__c ='SalesforcetestOrgtest@test.com';
        a.BillingStreet='24 Willie Mays Plaza';
        a.BillingCity='San Francisco';
        a.BillingState='California';
        a.BillingPostalCode='94017';
        a.BillingCountry='USA';
        a.Phone='9934200234'; 
        insert a;
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Bucket Account').getRecordTypeId();
        
        //Bucket Custom settings
        Bucket_Account_Settings__c bas = Bucket_Account_Settings__c.getOrgDefaults();
        bas.Bucket_Account_Owner_ID__c = UserInfo.getUserID();
        bas.Bucket_Account_RecordTypeID__c = recordTypeId;
        bas.Default_Bucket_Name__c = 'Bucket Account';
        bas.Maximum_Size_of_Bucket__c = 5000;
        insert bas;
        
        List<BGST_Profiles__c> ProfilesLists = new List<BGST_Profiles__c>();
        BGST_Profiles__c indivl = new BGST_Profiles__c();
        indivl.name = 'Owner Profile';
        indivl.Sales_User__c = 'ARC BGST Sales User';
        ProfilesLists.add(indivl);
        insert ProfilesLists;
        
		Switch__c esettings = new Switch__c();
        esettings.Name = 'EmailMessageServiceSwitch';
        esettings.Switch_Description__c = 'some desc';
        esettings.Switch__c = false;
        insert esettings;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = a.Id;
        opp.StageName = 'Approach';
        opp.CloseDate = date.today();
        opp.Pricing_Approval_Level__c = 'Manager';
        insert opp;
        
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'SalesforcetestOrg';
        con.Email = 'test@test.com';
        con.AccountId = a.id;
        con.NSSCCConnector__Contact_Status__c = 'Created';
        insert con;
        
        redwing__Learning__c learning = new redwing__Learning__c();
        learning.Name = 'Test learning';
        learning.redwing__Published__c = true;
        learning.RecordTypeId = Schema.SObjectType.redwing__Learning__c.getRecordTypeInfosByName().get('ILT Event').getRecordTypeId();
        insert learning;
        

        redwing__Training_Plan__c lPlan2 = new redwing__Training_Plan__c();
        lPlan2.Name = 'Plan2';
        insert lPlan2;

        ccrz__E_Product__c product1 = new ccrz__E_Product__c();
        product1.Name = 'Test Prod';
        product1.ccrz__SKU__c = String.ValueOf(System.Now());
        product1.ccrz__Quantityperunit__c = 2.0;
        product1.ccrz__StartDate__c =  System.Today().addDays(2);
        product1.ccrz__EndDate__c = System.Today().addDays(20);
        product1.LMS_Learning_Plan__c = lPlan2.id;
        insert product1;
        
        Redwing__ILT_Class__c clsRecord = new Redwing__ILT_Class__c();
        clsRecord.Skedulo_Account__c = a.id;
        clsRecord.redwing__End_Date__c = Date.Parse('12/19/2018');
        clsRecord.redwing__End_Time__c= '13:00';
        clsRecord.redwing__Start_Date__c = Date.Parse('12/19/2018');// Assuming Start date = End date
        clsRecord.redwing__Start_Time__c = '12:00';
        clsRecord.Name = 'Test';
        clsRecord.Learning_Plan__c = lPlan2.Id;
        clsRecord.redwing__Learning__c = learning.Id;
        insert clsRecord;
        
        ccrz__E_Order__c cco=new ccrz__E_Order__c();
        cco.NSSCCConnector_SFCC_Order_Number__c ='3114226';
        cco.NSSCCConnector_from_SFCC__c=true;
        cco.Opportunity_Order__c = opp.Id;  
        insert cco;
        
        ccrz__E_Order__c cco1 =new ccrz__E_Order__c();
        cco1.NSSCCConnector_SFCC_Order_Number__c ='3114227';
        cco1.NSSCCConnector_from_SFCC__c=true;
        cco1.Opportunity_Order__c = opp.Id;
        insert cco1;
        
        ccrz__E_Order__c ccoChild =new ccrz__E_Order__c();
        ccoChild.NSSCCConnector_SFCC_Order_Number__c ='3114229';
        ccoChild.NSSCCConnector_from_SFCC__c=true;
        ccoChild.ccrz__Order__c  = cco.Id;
        ccoChild.Is_Return_Order__c  = true;
        ccoChild.Opportunity_Order__c = opp.Id;
        insert ccoChild;
        
        ccrz__E_OrderItem__c ccoItems= new ccrz__E_OrderItem__c();
        ccoItems.ccrz__Product__c =product1.Id;
        ccoItems.ccrz__Order__c=cco.id;
        ccoItems.ccrz__Price__c=100;
        ccoItems.ccrz__Quantity__c=2.00;
        ccoItems.ccrz__SubAmount__c=100.00;
        ccoItems.ILT_Class__c=clsRecord.Id;
        ccoItems.ccrz__OrderItemStatus__c = 'Shipped';
        insert ccoItems;
        
        ccrz__E_OrderItem__c ccoItems1 = new ccrz__E_OrderItem__c();
        ccoItems1.ccrz__Product__c =product1.Id;
        ccoItems1.ccrz__Order__c=cco1.id;
        ccoItems1.ccrz__Price__c=100;
        ccoItems1.ccrz__Quantity__c= 1.00;
        ccoItems1.ccrz__SubAmount__c=100.00;
        ccoItems1.ILT_Class__c=clsRecord.Id;
        ccoItems1.ccrz__OrderItemStatus__c = 'Shipped';
        insert ccoItems1;
        
        ccrz__E_OrderItem__c ccoItems2 = new ccrz__E_OrderItem__c();
        ccoItems2.ccrz__Product__c =product1.Id;
        ccoItems2.ccrz__Order__c=ccoChild.id;
        ccoItems2.ccrz__Price__c=100;
        ccoItems2.ccrz__Quantity__c=100.00;
        ccoItems2.ccrz__SubAmount__c=100.00;
        ccoItems2.ILT_Class__c=clsRecord.Id;
        ccoItems2.ccrz__ParentOrderItem__c  = ccoItems.Id;
        ccoItems2.Is_Return__c = true;
        insert ccoItems2;
    }

    @isTest
    static void testTrigger()
    {
        List<ccrz__E_Order__c> ccorder = [SELECT Id FROM ccrz__E_Order__c WHERE NSSCCConnector_SFCC_Order_Number__c != null];
        
        ccrz__E_TransactionPayment__c ctp= new ccrz__E_TransactionPayment__c();
        
        ctp.ccrz__TransactionType__c = 'CAPTURE';
        ctp.ccrz__CCOrder__c		 = ccorder[0].Id;
        insert ctp;
    }
    
    @isTest
    static void testTrigger1()
    {
        ccrz__E_StoredPayment__c sPayment = new ccrz__E_StoredPayment__c(Name 				 	= 'test',
                                                                         ccrz__Enabled__c  		= true,
                                                                         Original_PO_Amount__c 	= 10000.00);
        insert sPayment;
        
        List<Account> acc = [SELECT Id, Open_Order_Amount__c FROM Account];
        
        List<ccrz__E_Order__c> ccorder = [SELECT Id FROM ccrz__E_Order__c];
        
        ccrz__E_TransactionPayment__c ctp= new ccrz__E_TransactionPayment__c();
        
        ctp.ccrz__AccountType__c	 = 'po';
        ctp.ccrz__CCOrder__c		 = ccorder[0].Id;
        ctp.ccrz__StoredPayment__c	 = sPayment.Id;
        ctp.ccrz__Amount__c			 = 100;
        ctp.ccrz__Account__c		 = acc[0].Id;
        
        insert ctp;
    }
    
}