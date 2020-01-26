/**
 * Created by jbarker on 2019-12-17.
 */

public with sharing class PHSS_ClassCompletionStudent {

    private static final String FAILED_TO_FETCH_USERS_BY_EMAIL_ADDRESS = 'Failed to fetch users by email address.';


    /**
     * @description Creates students for batch participants
     *
     * @param batchParticipants
     * @param batchClass
     *
     * @return
     */
    public static List<Contact> createAll(List<CCS_Batch_Participant__c> batchParticipants, CCS_Batch_Class__c batchClass, redwing__ILT_Class__c trainingClass) {

        if (batchParticipants == null || batchParticipants.size() == 0 || batchClass == null) {
            return null;
        }

        List<Contact> students;

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

        return students;
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
    private static String createUserKey(String firstName, String lastName, String emailAddress) {
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
    }


    /**
     * @description Fetches users by their email address
     *
     * @param emailAddresses
     * @param batchClass
     *
     * @return
     */
    private static List<User> fetchUsersForParticipants(List<CCS_Batch_Participant__c> batchParticipants, CCS_Batch_Class__c batchClass) {

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
    }
}