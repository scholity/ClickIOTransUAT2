/**
 * Created by jbarker on 2019-12-17.
 */

public without sharing class PHSS_ClassCompletionStudent
{
    
    

    //private static final String FAILED_TO_FETCH_USERS_BY_EMAIL_ADDRESS = 'Failed to fetch users by email address.';

    /**
     * @description Creates students for batch participants
     *
     * @param batchParticipants
     * @param batchClass
     *
     * @return
     */
    public static void createAll(List<CCS_Batch_Participant__c> batchParticipants, CCS_Batch_Class__c batchClass, redwing__ILT_Class__c trainingClass)
    {
        system.debug('***batchParticipants***'+batchParticipants);
        system.debug('***batchClass***'+batchClass);
        system.debug('***trainingClass***'+trainingClass);
        
        if (batchParticipants != null && batchParticipants.size() > 0 && batchClass != null)
        {
            //START
            Id learningPlanId   = trainingClass.Learning_Plan__c;
            Map<id,id> rtpa     = new map<id,id>();
            Map<id,id> rtpaac   = new map<id, id>();

            map<id,list<redwing__Training_Plan_Achievement__c>> mapTrainingPlanWithTrainingPlanAchievements = new map<id,list<redwing__Training_Plan_Achievement__c>>();
			system.debug('***Step 1 ***');
            for (redwing__Training_Plan_Achievement__c rtpalist :[SELECT Id, Name, redwing__Training_Plan__c, redwing__Achievement__c FROM redwing__Training_Plan_Achievement__c WHERE redwing__Training_Plan__c=: learningPlanId])
            {
                rtpa.put(rtpalist.redwing__Training_Plan__c, rtpalist.Id);
                
                rtpaac.put(rtpalist.redwing__Training_Plan__c, rtpalist.redwing__Achievement__c);
                
                if(mapTrainingPlanWithTrainingPlanAchievements.containskey(rtpalist.redwing__Training_Plan__c))
                {
                    mapTrainingPlanWithTrainingPlanAchievements.get(rtpalist.redwing__Training_Plan__c).add(rtpalist);
                }
                else
                {
                    list<redwing__Training_Plan_Achievement__c> lstRTPA = new list<redwing__Training_Plan_Achievement__c>();

                    lstRTPA.add(rtpalist);

                    mapTrainingPlanWithTrainingPlanAchievements.put(rtpalist.redwing__Training_Plan__c,lstRTPA);
                }
            }

            List<redwing__Achievement_Assignment__c> AchievementAssignmentList = new List<redwing__Achievement_Assignment__c>();
            system.debug('***Step 2 ***');
            for (CCS_Batch_Participant__c participant : batchParticipants)
            {    
                if (mapTrainingPlanWithTrainingPlanAchievements.containskey(learningPlanId))
                {
                    for(redwing__Training_Plan_Achievement__c rtpalist : mapTrainingPlanWithTrainingPlanAchievements.get(learningPlanId))
                    {
                        System.debug('Going to create Achievement assignment');

                        redwing__Achievement_Assignment__c      rac = new redwing__Achievement_Assignment__c();

                        rac.redwing__Training_Plan_Achievement__c   = rtpalist.id;
                        rac.Firstname__c                            = participant.First_Name__c;
                        rac.Lastname__c                             = participant.Last_Name__c;
                        rac.Email__c                                = participant.Email_Address__c;
                        rac.Phone__c                                = participant.Phone_Number__c;
                        rac.Account__c                              = batchClass.Account__c;
                        rac.redwing__Status__c                      = 'Eligible';
                        rac.Evaluation_Result__c                    = participant.Mastery_Status__c;
                        //rac.Grade_Reason__c                         = participant.Evaluation_Notes__c;
                        rac.Grade_Additional_Info__c              = participant.Evaluation_Notes__c;

                        if (participant.Mastery_Status__c == 'Successful')
                        {
                            rac.redwing__Status__c                  = 'OnHold';
                            rac.redwing__Acquisition_Date__c        = batchClass.Course_End_Date__c;       // Use ILT Class close date
                        }
                        
                        rac.ILT_Class__c                            = trainingClass.Id;
                        rac.External_Id__c                          = participant.First_Name__c+participant.Last_Name__c+participant.Email_Address__c+trainingClass.Id;
                        
                        rac.redwing__Achievement__c                 = rtpalist.redwing__Achievement__c;

                        System.debug('Achievement Assignment created' +rac.redwing__Achievement__c);
                        AchievementAssignmentList.add(rac);

                        System.debug('AchievementAssignmentListvalue '+AchievementAssignmentList);
                        
                    }
                }
            } 
 
            if(AchievementAssignmentList.size() > 0)
            {
                if(!Test.isRunningTest()) {
                	insert AchievementAssignmentList;
                }
            }
                        
        }


        //END
        

/*        List<Contact> students;

        Map<String, User> userMap = new Map<String, User>();
        List<User> users = fetchUsersForParticipants(batchParticipants, batchClass);
        for (User user : users) {
            String key = createUserKey(user.FirstName, user.LastName, user.Email);
            if (String.isNotBlank(key)) {
                userMap.put(key, user);
            }
        }

        List<Contact> newContacts = new List<Contact>();
        List<User> newUsers = new List<User>();
        for (CCS_Batch_Participant__c participant : batchParticipants) {
            String key = createUserKey(participant.First_Name__c, participant.Last_Name__c, participant.Email_Address__c);
            if (!userMap.containsKey(key)) {

                Contact contact = new Contact();
                contact.FirstName = participant.First_Name__c;
                contact.LastName = participant.Last_Name__c;
                contact.Email = participant.Email_Address__c;
                contact.MobilePhone = participant.Phone_Number__c;
                contact.AccountId = batchClass.Account__c;      // new Account(DM_External_Id__c = (student.LastName+student.FirstName+student.Email).toLowerCase());
                contact.DM_External_Id__c = key;
                newContacts.add(contact);

            }
        }


        List<redwing__Training_Plan_Assignment__c> assignments = new List<redwing__Training_Plan_Assignment__c>();
        for (String key : userMap.keySet()) {
            User user = userMap.get(key);
            redwing__Training_Plan_Assignment__c assignment = new redwing__Training_Plan_Assignment__c();
            assignment.redwing__Training_Plan__c = trainingClass.Learning_Plan__c;
            assignment.redwing__Contact__c = user.ContactId;
            assignment.redwing__User__c = user.Id;
            assignment.External_Id__c = batchClass.ILT_Class__c;
            assignment.redwing__Status__c = 'Completed';
            assignments.add(assignment);
        }
        insert assignments;

        return students; */
    }


    /**
     * @description Creates a unique key based on a user's first name, last name, and email address
     *
     * @param firstName
     * @param lastName
     * @param emailAddress
     *
     * @return
     */
    /*private static String createUserKey(String firstName, String lastName, String emailAddress) {
        String key = '';

        if (String.isNotBlank(lastName)) {
            key += lastName.toLowerCase();
        }
        if (String.isNotBlank(firstName)) {
            key += firstName.toLowerCase();
        }
        if (String.isNotBlank(emailAddress)) {
            key += emailAddress.toLowerCase();
        }

        return key;
    }*/


    /**
     * @description Fetches users by their email address
     *
     * @param emailAddresses
     * @param batchClass
     *
     * @return
     */
    /*private static List<User> fetchUsersForParticipants(List<CCS_Batch_Participant__c> batchParticipants, CCS_Batch_Class__c batchClass) {

        List<User> users;

        List<String> firstNames = new List<String>();
        List<String> lastNames = new List<String>();
        List<String> emailAddresses = new List<String>();

        for (CCS_Batch_Participant__c participant : batchParticipants) {
            if (String.isNotBlank(participant.First_Name__c)) {
                firstNames.add(participant.First_Name__c);
            }
            if (String.isNotBlank(participant.Last_Name__c)) {
                lastNames.add(participant.Last_Name__c);
            }
            if (String.isNotBlank(participant.Email_Address__c)) {
                emailAddresses.add(participant.Email_Address__c);
            }
        }

        try {
            users = [
                    SELECT
                            ContactId,
                            Email,
                            FirstName,
                            Id,
                            LastName,
                            Username
                    FROM
                            User
                    WHERE
                            LastName IN :lastNames
                            AND FirstName IN :firstNames
                            AND (Email = NULL OR Email = '' OR Email IN :emailAddresses)
            ];

        } catch (Exception e) {
            throw new phss_cc_Exception(FAILED_TO_FETCH_USERS_BY_EMAIL_ADDRESS, e);
        }

        return users;
    }*/
}