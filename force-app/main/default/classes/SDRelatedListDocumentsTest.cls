@isTest
private class SDRelatedListDocumentsTest {
    
    public static final Integer accountCount            = 1;
    public static final Integer oppsOnEachAccount       = 1;
    
    @testsetup 
    public static void initializeClassTestData()
    {
        CreateTestAccountsAndOpportunities(accountCount, oppsOnEachAccount);
    }
    
	@isTest
    private static void testSDRelatedListDocuments() {
        Opportunity testOpp = [SELECT Account.Id FROM Opportunity LIMIT 1];
        
        Test.setCurrentPage(Page.SDRelatedListDocuments);
        ApexPages.currentPage().getParameters().put('parentId', String.valueOf(testOpp.Account.Id));
		ApexPages.currentPage().getParameters().put('childObjName', 'Contact');
		ApexPages.currentPage().getParameters().put('lookupFieldName', 'Account');
		ApexPages.currentPage().getParameters().put('doclist', '');
		ApexPages.currentPage().getParameters().put('sendEmail', '0');
        
        SDRelatedListDocumentsController sdrldc = new SDRelatedListDocumentsController();
        sdrldc.createSDocJobs();
        Boolean tmp = sdrldc.jobsAreCompleted;
        sdrldc.returnToParentRecord();
        sdrldc.emailDocuments();
    }
    
    public static void CreateTestAccountsAndOpportunities(Integer accounts, Integer oppsPerAccount)
    {
        Database.DMLOptions dml = new Database.DMLOptions();        
        dml.DuplicateRuleHeader.allowSave = true;
        
        List<account> accountList = new List<Account>();
        
        for(Integer a = 0; a< accounts; a++)
        {
            accountList.add(new Account(Name='Testing Company'+ String.ValueOf(a)));
        }
        
        database.insert(accountList, dml);        
        
        //Insert cutom setting
        List<BGST_Profiles__c> ProfilesList = new List<BGST_Profiles__c>();
        
		BGST_Profiles__c indiv = new BGST_Profiles__c(	name 			= 'Owner Profile',
														Sales_User__c 	= 'ARC BGST Sales User');
		ProfilesList.add(indiv);
		
		insert ProfilesList;    
        
        List<Opportunity> opportunitiesList = new List<Opportunity>();
        
        for(Account act : accountList)
        {
            system.debug('Inside account');
            for(Integer o = 0; o< oppsPerAccount; o++)
            {
                opportunitiesList.add(new Opportunity(  Name                = 'Test'+ String.ValueOf(o),
                                                        AccountId           = act.id,
                                                        Type                = 'New Business - FS',
                                                        CloseDate           = Date.Today(),
                                                        StageName           = 'Approach',
                                                        Approval_Status__c  = 'Approved'));
            }
        }
        
        Database.insert(opportunitiesList, dml);
        
    }
}