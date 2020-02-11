@isTest(SeeAllData=false)
public with sharing class AccountContactRelationTriggerHandlerTest {
    
    private static User testUser;

    private static Contact testContact;

    private static Account testAccount;

    private static Profile learnerProfile = [SELECT Id FROM Profile WHERE Name = 'Learner Community Profile' LIMIT 1];
    
    private static void generateTestData(){

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Bucket Account').getRecordTypeId();
        
        //Bucket Custom settings
        Bucket_Account_Settings__c bas = Bucket_Account_Settings__c.getOrgDefaults();
        bas.Bucket_Account_Owner_ID__c = UserInfo.getUserID();
        bas.Bucket_Account_RecordTypeID__c = recordTypeId;
        bas.Default_Bucket_Name__c = 'Bucket Account';
        bas.Maximum_Size_of_Bucket__c = 5000;
        insert bas;

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
        
        testContact = new Contact(
            FirstName = 'test',
            LastName = 'learneruser',
            Email = 'learneruser@321test123fake.net',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        testUser = new User(
            Alias = 'newUser', 
            Email ='newuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'test',
            LastName = 'learneruser', 
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', 
            ProfileId = learnerProfile.Id, 
            ContactId = testContact.Id,
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'learneruser@321test123fake.net'
        );
        insert testUser;        
    }

    @isTest static void testUpdateInstructorProfiles(){

        generateTestData();

        Test.StartTest();

        AccountContactRelation testAccountContactRelation = [SELECT Id, Roles FROM AccountContactRelation WHERE AccountId = :testAccount.Id AND ContactId = :testContact.Id LIMIT 1];

        system.assertNotEquals(testAccountContactRelation, null);

        testAccountContactRelation.Roles = 
            String.isBlank(testAccountContactRelation.Roles) ? 
            AccountContactRelationTriggerHandler.ACR_ROLE_INSTRUCTOR : 
            (testAccountContactRelation.Roles+';'+AccountContactRelationTriggerHandler.ACR_ROLE_INSTRUCTOR);

        update testAccountContactRelation;

        Test.stopTest();

        testUser = [SELECT Id, ProfileId, UserRole.Name FROM User WHERE Id = :testUser.Id];

        system.debug('@@@testUser: '+testUser);
        
        system.assertEquals(testUser.ProfileId, AccountContactRelationTriggerHandler.instructorProfile.Id);

    }

    @isTest static void testUpdateAdminProfiles(){

        generateTestData();

        Test.StartTest();

        AccountContactRelation testAccountContactRelation = [SELECT Id, Roles FROM AccountContactRelation WHERE AccountId = :testAccount.Id AND ContactId = :testContact.Id LIMIT 1];

        system.assertNotEquals(testAccountContactRelation, null);

        testAccountContactRelation.Roles = 
            String.isBlank(testAccountContactRelation.Roles) ? 
            AccountContactRelationTriggerHandler.ACR_ROLE_ADMINISTRATOR : 
            (testAccountContactRelation.Roles+';'+AccountContactRelationTriggerHandler.ACR_ROLE_ADMINISTRATOR);

        update testAccountContactRelation;

        Test.stopTest();

        testUser = [SELECT Id, ProfileId, UserRole.Name FROM User WHERE Id = :testUser.Id];
        
        system.assertEquals(testUser.ProfileId, AccountContactRelationTriggerHandler.adminProfile.Id);

    }
}