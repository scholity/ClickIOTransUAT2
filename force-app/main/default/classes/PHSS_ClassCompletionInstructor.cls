/**
 * Created by jbarker on 2019-12-16.
 */

public without sharing class PHSS_ClassCompletionInstructor {

    //  error messages
    private static final String FAILED_TO_CREATE_ALL_INSTRUCTORS = 'Failed to create all instructors.';
    private static final String FAILED_TO_FETCH_USERS = 'Failed to fetch users.';
    private static final String UNRECOGNIZED_INSTRUCTORS = 'Unrecognized instructor(s)';


    /**
     * @description Creates an ILT Instructor based on a batch's instructor and class
     *
     * @param batchInstructor
     * @param batchClass
     *
     * @return
     */
    public static List<redwing__ILT_Instructor__c> createAll(List<CCS_Batch_Instructor__c> batchInstructors, CCS_Batch_Class__c batchClass, redwing__ILT_Class__c trainingClass) {

        if (batchInstructors == null || batchInstructors.size() == 0 || batchClass == null) {
            return null;
        }

        List<redwing__ILT_Instructor__c> trainingInstructors = new List<redwing__ILT_Instructor__c>();

        try {
            List<String> usernames = new List<String>();
            for (CCS_Batch_Instructor__c batchInstructor : batchInstructors) {
                usernames.add(batchInstructor.Instructor_Id__c);
            }

            Map<String, User> userMap = new Map<String, User>();
            if (usernames.size() > 0) {
                List<User> users = fetchUsers(usernames);
                if (users != null && users.size() > 0) {
                    for (User user : users) {
                        userMap.put(user.Username, user);
                    }

                    List<CCS_Batch_Instructor__c> missingInstructors = new List<CCS_Batch_Instructor__c>();
                    for (CCS_Batch_Instructor__c batchInstructor : batchInstructors) {
                        if (!userMap.containsKey(batchInstructor.Instructor_Id__c)) {
                            missingInstructors.add(batchInstructor);
                        }
                    }
                    if (missingInstructors.size() > 0) {
                        String instructorUsernames = String.join(missingInstructors, ', ');
                        throw new phss_cc_Exception(UNRECOGNIZED_INSTRUCTORS + ': ' + instructorUsernames);
                    }
                }
            }

            Map<String, redwing__ILT_Instructor__c> usernameInstructorMap = new Map<String, redwing__ILT_Instructor__c>();
            for (CCS_Batch_Instructor__c batchInstructor : batchInstructors) {

                String username = batchInstructor.Instructor_Id__c;
                if (!usernameInstructorMap.containsKey(username)) {
                    User user = userMap.get(batchInstructor.Instructor_Id__c);

                    redwing__ILT_Instructor__c trainingInstructor = new redwing__ILT_Instructor__c();
                    trainingInstructor.redwing__Instructor__c = user.Id;
                    trainingInstructor.redwing__ILT_Class__c = trainingClass.Id;
                    trainingInstructor.redwing__Primary__c = true;
                    trainingInstructors.add(trainingInstructor);

                    // TODO: Do we need to account for additional instructors?
                    // Or will all instructors assigned to a training class be marked as the primary instructor?
                    // Or should no instructors be assigned as the primary instructor?

                }
            }
            if (usernameInstructorMap.keySet().size() > 0) {
                trainingInstructors = usernameInstructorMap.values();
            }

        } catch (Exception e) {
            throw new phss_cc_Exception(FAILED_TO_CREATE_ALL_INSTRUCTORS, e);
        }

        return trainingInstructors;
    }


    /**
     * @description Fetches a list of users
     *
     * @param usernames
     *
     * @return
     */
    private static List<User> fetchUsers(List<String> usernames) {

        List<User> users;

        try {
            users = [
                    SELECT
                            Id,
                            FirstName,
                            LastName,
                            Username
                    FROM
                            User
                    WHERE
                            Username IN :usernames
            ];

        } catch (Exception e) {
            throw new phss_cc_Exception(FAILED_TO_FETCH_USERS, e);
        }

        return users;
    }
}