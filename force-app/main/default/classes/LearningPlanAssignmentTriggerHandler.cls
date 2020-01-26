public class LearningPlanAssignmentTriggerHandler
{   
    public static void OnAfterInsert(List<redwing__Training_Plan_Assignment__c> newLearningPlanAssignment)
    {
        /*List<redwing__Training_Plan_Assignment__c> lpAssignmentList = [SELECT Id,
                                                                      		  redwing__Contact__c,
                                                                      		  redwing__Status__c,
                                                                       		  redwing__Due_Date__c,
                                                                       		  redwing__Training_Plan__c,
                                                                       		  redwing__User__c,
                                                                       		  redwing__Completed_On__c,
                                                                       		  LastModifiedDate,
                                                                       		  OwnerId
                                                                         FROM redwing__Training_Plan_Assignment__c
                                                                        WHERE Id IN : newLearningPlanAssignment];*/
        
        List<Id>   userIdList 	 = new List<Id>();
        Map<Id,Id> userToLpMap   = new Map<Id,Id>();
        Map<Id,List<redwing__Achievement_Assignment__c>> aaUserToLpMap = new Map<Id,List<redwing__Achievement_Assignment__c>>();
        
        for(redwing__Training_Plan_Assignment__c tpa : newLearningPlanAssignment)
        {
            userIdList.add(tpa.redwing__User__c);
            userToLpMap.put(tpa.redwing__User__c,tpa.redwing__Training_Plan__c);
        }
        
        List<User> usersWithAA = [SELECT Id,
                                  		 (SELECT Recertification_Learning_Plan__c
                                            FROM redwing__Achievement_Assignments__r
                                           WHERE Achievement_Type__c = 'Certifications'
                                             AND redwing__Status__c  = 'Acquired'
                                         	 AND Recertification_Learning_Plan__c != null)
                                 	 FROM User
                                  	WHERE Id IN :userIdList]; // Add expire date logic
        
        for(User u : usersWithAA)
        {
            if(u.redwing__Achievement_Assignments__r.size() > 0)
            {
                //aaUserToLpMap.put(u.Id,u.redwing__Achievement_Assignments__r);
                List<Id> recertLPIdList = new List<Id>();
                
                for(redwing__Achievement_Assignment__c a : u.redwing__Achievement_Assignments__r)
                {
                    recertLPIdList.add(a.Recertification_Learning_Plan__c);
                }
                
            }
        }
        
        if(!aaUserToLpMap.isEmpty() && aaUserToLpMap != null)
        {
            for(redwing__Training_Plan_Assignment__c tpa : newLearningPlanAssignment)
            {
                Id userId = tpa.redwing__User__c;
                
                if(userToLpMap.containsKey(userId))
                {
                    Id tpId = userToLpMap.get(userId);
                    
                    system.debug('***tpId***'+tpId);
                }
                
                if(aaUserToLpMap.containsKey(userId))
                {
                    for(redwing__Achievement_Assignment__c a : aaUserToLpMap.get(userId))
                    {
                        //if
                    }
                }
            }
        }
        
        
        /*
        
        List<redwing__Achievement_Assignment__c> aaList = [SELECT Id,
                                                           		  redwing__User__c,
                                                           		  Recertification_Learning_Plan__c
                                                          	 FROM redwing__Achievement_Assignment__c
                                                            WHERE Recertification_Learning_Plan__c != null
                                                          	  AND Achievement_Type__c = 'Certifications'
                                                              AND redwing__Status__c  = 'Acquired'];*/

        
        
        /*
        for(redwing__Training_Plan_Assignment__c la : lpAssignmentList)
        {
            system.debug('***la***'+la);
            
        }*/
    }
}