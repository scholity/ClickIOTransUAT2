@isTest
public class LearningPlanAssignmentTriggerHandlerTest
{   
    @isTest
    static void testDataSetup()
    {
        Account a = new Account();
        a.Name='SalesforcetestOrg';
        a.BillingStreet='24 Willie Mays Plaza';
        a.BillingCity='San Francisco';
        a.BillingState='California';
        a.BillingPostalCode='94017';
        a.BillingCountry='US';
        a.Phone='9934200234'; 
        insert a;

        // Learning
        redwing__Learning__c learning = new redwing__Learning__c();
        learning.Name = 'Test learning';
        learning.redwing__Published__c = true;
        learning.RecordTypeId = Schema.SObjectType.redwing__Learning__c.getRecordTypeInfosByName().get('Media').getRecordTypeId();
        insert learning;

        // Learning Plan
        redwing__Training_Plan__c lPlan = new redwing__Training_Plan__c();
        lPlan.Name = 'Test Plan';
        insert lPlan;

        // Learning Assignment
        redwing__Learning_Assignment__c learningAssignment = new redwing__Learning_Assignment__c();
        learningAssignment.redwing__Learning__c = learning.id; // 
        learningAssignment.External_Id__c = 'priyalakshmi.pp@gmail.com'; 
        learningAssignment.redwing__Training_Plan__c = lPlan.Id;
        insert learningAssignment;
		
        redwing__Learning_Assignment__c learningAssignmentupdate = new redwing__Learning_Assignment__c();
        learningAssignmentupdate.id=learningAssignment.id;
        learningAssignmentupdate.redwing__Evaluation_Result__c = 'Passed';
        learningAssignmentupdate.Grade_Reason__c = 'Reason 2'; // Retrieve learning id from page 1
        learningAssignmentupdate.Grade_Additional_Info__c = 'Reason 2'; 
        update learningAssignmentupdate;
        
        // Achievement Category
        redwing__Achievement_Category__c rac = new redwing__Achievement_Category__c();
        rac.name = 'Certificate';
        insert rac;
        
        // Achievement
        redwing__Achievement__c ra = new redwing__Achievement__c();
        ra.redwing__Achievement_Category__c = rac.id;
        ra.Learning_Plan__c = lPlan.Id;
        ra.redwing__Type__c = 'Certifications';
        insert ra;
        
        List<redwing__Achievement__c> achievmet = [SELECT Id, redwing__Achievement_Category__c, Learning_Plan__c FROM redwing__Achievement__c];
        
        // Learning Plan Acheivement
        redwing__Training_Plan_Achievement__c  planAchievement = new redwing__Training_Plan_Achievement__c();
        planAchievement.redwing__Training_Plan__c = lplan.id;
        planAchievement.redwing__Achievement__c = ra.id;
        insert planAchievement;
         
        List<User> user = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator'];
        
        // Achievement Assignment
        redwing__Achievement_Assignment__c achieveAssign = new redwing__Achievement_Assignment__c();
        achieveAssign.redwing__User__c = UserInfo.getUserId();
        achieveAssign.redwing__Training_Plan_Achievement__c = planAchievement.Id;
        achieveAssign.redwing__user__r = user[0];
        achieveAssign.redwing__Status__c = 'Acquired';
        achieveAssign.redwing__Achievement__c = ra.id;
        insert achieveAssign;
        
        List<redwing__Achievement_Assignment__c> aa = [SELECT  Id,
                                                       	 Recertification_Learning_Plan__c,
                                                         redwing__Expiration_Date__c,
                                                         Achievement_Type__c,
                                                         redwing__user__c,
                                                         redwing__user__r.Id
                                                    FROM redwing__Achievement_Assignment__c
                                                   ];
        
        redwing__Training_Plan_Assignment__c planAssignment = new redwing__Training_Plan_Assignment__c();
        planAssignment.redwing__Training_Plan__c = lPlan.Id; //aa[0].Recertification_Learning_Plan__c;
        planAssignment.External_Id__c = 'test.test@gmail.com';
        planAssignment.redwing__User__c = aa[0].redwing__user__r.Id; //user[0].Id;
        insert planAssignment;
    }
    
}