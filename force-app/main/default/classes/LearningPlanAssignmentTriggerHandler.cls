/*********************************************
 * Developed By Human, on the planet earth.	 *
 ********************************************/

public without sharing class LearningPlanAssignmentTriggerHandler
{   
    public static void OnAfterInsert(List<redwing__Training_Plan_Assignment__c> newLearningPlanAssignment)
    {
        List<Id>   userIdList 	 = new List<Id>();
        Map<Id,Id> userToLpMap   = new Map<Id,Id>();
        
        Map<Id,List<redwing__Achievement_Assignment__c>> aaUserToLpMap = new Map<Id,List<redwing__Achievement_Assignment__c>>();
        
        for(redwing__Training_Plan_Assignment__c tpa : newLearningPlanAssignment)
        {
            userIdList.add(tpa.redwing__User__c);
            userToLpMap.put(tpa.redwing__User__c,tpa.redwing__Training_Plan__c);
        }
        
        List<User> usersWithAA = [SELECT Id,
                                  		 (SELECT Id,
                                          		 redwing__Achievement__r.Learning_Plan__c, 
                                          		 redwing__Expiration_Date__c
                                            FROM redwing__Achievement_Assignments__r
                                           WHERE Achievement_Type__c = 'Certifications'
                                             AND redwing__Status__c  = 'Acquired'
                                         	 AND Recertification_Learning_Plan__c != null)
                                 	 FROM User
                                  	WHERE Id IN :userIdList]; // Add expire date logics - Exp date in 90 days
        
        system.debug('usersWithAA***'+usersWithAA);
        
        for(User u : usersWithAA)
        {
            if(u.redwing__Achievement_Assignments__r.size() > 0)
            {
                aaUserToLpMap.put(u.Id,u.redwing__Achievement_Assignments__r);
            }
        }
                
        if(!aaUserToLpMap.isEmpty() && aaUserToLpMap != null)
        {
            for(redwing__Training_Plan_Assignment__c tpa : newLearningPlanAssignment)
            {
                Id userId = tpa.redwing__User__c;
                
                Id tpId;
                
                if(userToLpMap.containsKey(userId))
                {
                    tpId = userToLpMap.get(userId);
                    
                    system.debug('***tpId***'+tpId);
                }
                
                //Check for Recertication Learning plan is same as the new learning plan on learning plan assigment. 
                //Process is for re-regtistraion for insturctor.
                
                if(aaUserToLpMap.containsKey(userId))
                {
                    for(redwing__Achievement_Assignment__c a : aaUserToLpMap.get(userId))
                    {
                        system.debug('a.Recertification_Learning_Plan__c***'+a.redwing__Achievement__r.Learning_Plan__c);
                        system.debug('tpId***'+tpId);
                        
                        if(a.redwing__Achievement__r.Learning_Plan__c == tpId)
                        {
                            system.debug('a.Recertification_Learning_Plan__c***'+a.redwing__Achievement__r.Learning_Plan__c);
                            system.debug('tpId***'+tpId);
                            
                            tpa.redwing__Due_Date__c = a.redwing__Expiration_Date__c;
                            tpa.Recertification__c	 = true;
                        }
                    }
                }
                
            }
        }
    }
}