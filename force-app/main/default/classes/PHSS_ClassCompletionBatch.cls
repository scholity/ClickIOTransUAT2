/**
 * Created by jbarker on 2019-12-10.
 */

public with sharing class PHSS_ClassCompletionBatch {

    private static final Boolean DEBUG_MODE = true;

    private static final String FIELD_DELIMITER = '\\|';

    private static final String CLASS_RECORD_TYPE       = 'A';
    private static final String INSTRUCTOR_RECORD_TYPE  = 'B';
    private static final String PARTICIPANT_RECORD_TYPE = 'C';

    private static final String SUCCESSFUL_MASTERY_STATUS       = 'Successful';
    private static final String UNSUCCESSFUL_MASTERY_STATUS     = 'Unsuccessful';
    private static final String NOT_EVALUATED_MASTERY_STATUS    = 'Not Evaluated';

    // field indices
    private static final Integer SENDER_FIELD_INDEX                 = 0;
    private static final Integer BATCH_FIELD_INDEX                  = 1;
    private static final Integer CLASS_FIELD_INDEX                  = 2;
    private static final Integer RECORD_TYPE_FIELD_INDEX            = 3;
    private static final Integer ORG_ID_FIELD_INDEX                 = 4;
    private static final Integer ORG_NAME_FIELD_INDEX               = 5;
    private static final Integer PO_NUMBER_FIELD_INDEX              = 6;
    private static final Integer COURSE_CODE_FIELD_INDEX            = 7;
    private static final Integer COURSE_START_DATE_FIELD_INDEX      = 8;
    private static final Integer COURSE_END_DATE_FIELD_INDEX        = 9;
    private static final Integer TOTAL_STUDENTS_FIELD_INDEX         = 10;
    private static final Integer TRAINING_SITE_NAME_FIELD_INDEX     = 11;
    private static final Integer TRAINING_SITE_ADDRESS_FIELD_INDEX  = 12;
    private static final Integer TRAINING_SITE_CITY_FIELD_INDEX     = 13;
    private static final Integer TRAINING_SITE_STATE_FIELD_INDEX    = 14;
    private static final Integer TRAINING_SITE_ZIP_CODE_FIELD_INDEX = 15;

    private static final Integer INSTRUCTOR_ID_FIELD_INDEX          = 4;
    private static final Integer INSTRUCTOR_FIRST_NAME_FIELD_INDEX  = 5;
    private static final Integer INSTRUCTOR_LAST_NAME_FIELD_INDEX   = 6;
    private static final Integer INSTRUCTOR_EMAIL_FIELD_INDEX       = 7;

    private static final Integer PARTICIPANT_FIRST_NAME_FIELD_INDEX = 4;
    private static final Integer PARTICIPANT_LAST_NAME_FIELD_INDEX  = 5;
    private static final Integer PARTICIPANT_EMAIL_FIELD_INDEX      = 6;
    private static final Integer PARTICIPANT_PHONE_FIELD_INDEX      = 7;
    private static final Integer PARTICIPANT_MASTERY_FIELD_INDEX    = 8;
    private static final Integer PARTICIPANT_EVAL_NOTES_FIELD_INDEX = 9;

    // result keys/values
    public static final String SUCCESS_KEY = 'success';

    // error messages
    private static final String INVALID_MASTERY_STATUS_VALUE = 'Invalid value for Mastery Status';
    private static final String MISSING_FIELD_VALUE = 'Missing field value';


    private Datetime batchTimestamp;
    private Map<String, CCS_Batch_Class__c> batchMap;


    /**
     * @description Initializes specific variables for the batch
     */
    public PHSS_ClassCompletionBatch() {
        batchTimestamp = System.now();
        batchMap = new Map<String, CCS_Batch_Class__c>();
    }


    /**
     * @description Processes a list of batch records
     *
     * @param records
     *
     * @return
     */
    public Map<String, Object> processData(List<String> records) {
        if (DEBUG_MODE) { System.debug('processing batch data'); }

        Savepoint sp = Database.setSavepoint();

        try {

            List<CCS_Batch_Instructor__c> batchInstructors = new List<CCS_Batch_Instructor__c>();
            List<CCS_Batch_Participant__c> batchParticipants = new List<CCS_Batch_Participant__c>();

            // store batch data
            for (String record : records) {
                List<String> values = record.split(FIELD_DELIMITER);
                String recordType = values[RECORD_TYPE_FIELD_INDEX];

                if (recordType == CLASS_RECORD_TYPE) {
                    CCS_Batch_Class__c batchClass = createClass(values);
                    insert batchClass;
                    batchMap.put(batchClass.Name, batchClass);

                } else if (recordType == INSTRUCTOR_RECORD_TYPE) {
                    CCS_Batch_Instructor__c instructor = createInstructor(values);
                    batchInstructors.add(instructor);

                } else if (recordType == PARTICIPANT_RECORD_TYPE) {
                    CCS_Batch_Participant__c participant = createParticipant(values);
                    batchParticipants.add(participant);

                } else {
                    if (DEBUG_MODE) { System.debug('unknown record type: ' + recordType); }
                }
            }

            if (batchInstructors.size() > 0) { insert batchInstructors; }
            if (batchParticipants.size() > 0) { insert batchParticipants; }


            // iterate through batches to validate and create training classes, instructors, and students
            for (String batchName : batchMap.keySet()) {

                CCS_Batch_Class__c batchClass = batchMap.get(batchName);

                redwing__ILT_Class__c trainingClass = PHSS_ClassCompletionTrainingClass.create(batchClass);
                if (trainingClass != null) {

                    List<redwing__ILT_Instructor__c> trainingInstructors;

                    if (batchInstructors != null && batchInstructors.size() > 0) {
                        trainingInstructors = PHSS_ClassCompletionInstructor.createAll(batchInstructors, batchClass, trainingClass);
                        if (trainingInstructors.size() > 0) {
                            insert trainingInstructors;
                        }
                    }

//                    List<Contact> students;
//
//                    if (batchParticipants != null && batchParticipants.size() > 0) {
//                        students = PHSS_ClassCompletionStudent.createAll(batchParticipants, batchClass, trainingClass);
//                        if (students != null && students.size() > 0) {
//                            insert students;
//                        }
//                    }
                }
            }

        } catch (Exception e) {
            Database.rollback(sp);
            throw e;
        }

        return new Map<String, Object>{ SUCCESS_KEY => true };
    }


    /**
     * @description Creates a batch class
     *
     * @param values
     */
    private CCS_Batch_Class__c createClass(List<String> values) {

        if (String.isBlank(values[SENDER_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Sender ID');
        } else if (String.isBlank(values[BATCH_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Batch ID');
        } else if (String.isBlank(values[CLASS_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Offering ID');
        } else if (String.isBlank(values[ORG_ID_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Organization ID');
//        } else if (String.isBlank(values[ORG_NAME_FIELD_INDEX])) {                                //  optional
//            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Organization Name');
//        } else if (String.isBlank(values[PO_NUMBER_FIELD_INDEX])) {                               //  optional
//            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': PO Number');
        } else if (String.isBlank(values[COURSE_CODE_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Course Code');
        } else if (String.isBlank(values[COURSE_START_DATE_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Course Start Date');
        } else if (String.isBlank(values[COURSE_END_DATE_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Course End Date');
        } else if (String.isBlank(values[TOTAL_STUDENTS_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Total Students');
//        } else if (String.isBlank(values[TRAINING_SITE_NAME_FIELD_INDEX])) {                      //  optional
//            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Training Site Name');
//        } else if (String.isBlank(values[TRAINING_SITE_ADDRESS_FIELD_INDEX])) {                   //  optional
//            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Training Site Address');
//        } else if (String.isBlank(values[TRAINING_SITE_CITY_FIELD_INDEX])) {                      //  optional
//            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Training Site City');
//        } else if (String.isBlank(values[TRAINING_SITE_STATE_FIELD_INDEX])) {                     //  optional
//            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Training Site State');
//        } else if (String.isBlank(values[TRAINING_SITE_ZIP_CODE_FIELD_INDEX])) {                  //  optional
//            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Training Site Zip Code');
        }

        CCS_Batch_Class__c batchClass = new CCS_Batch_Class__c(
                Account__c = values[SENDER_FIELD_INDEX],
                Name = values[BATCH_FIELD_INDEX],
                ILT_Class__c = values[CLASS_FIELD_INDEX],
                PO_Number__c = values[PO_NUMBER_FIELD_INDEX],
                Course_Code__c = values[COURSE_CODE_FIELD_INDEX],
                Course_Start_Date__c = Date.parse(values[COURSE_START_DATE_FIELD_INDEX]),
                Course_End_Date__c = Date.parse(values[COURSE_END_DATE_FIELD_INDEX]),
                Number_of_Students__c = Integer.valueOf(values[TOTAL_STUDENTS_FIELD_INDEX]),
                Training_Site_Name__c = values[TRAINING_SITE_NAME_FIELD_INDEX],
                Training_Site_Address__c = values[TRAINING_SITE_ADDRESS_FIELD_INDEX],
                Training_Site_City__c = values[TRAINING_SITE_CITY_FIELD_INDEX],
                Training_Site_State__c = values[TRAINING_SITE_STATE_FIELD_INDEX],
                Training_Site_Zip_Code__c = values[TRAINING_SITE_ZIP_CODE_FIELD_INDEX]
        );

        return batchClass;
    }


    /**
     * @description Creates a batch instructor
     *
     * @param values
     */
    private CCS_Batch_Instructor__c createInstructor(List<String> values) {
        if (String.isBlank(values[SENDER_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Sender ID');
        } else if (String.isBlank(values[BATCH_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Batch ID');
        } else if (String.isBlank(values[CLASS_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Offering ID');
        } else if (String.isBlank(values[INSTRUCTOR_ID_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Instructor ID');
        }

        String batchId = values[BATCH_FIELD_INDEX];
        CCS_Batch_Class__c batchClass = batchMap.get(batchId);
        CCS_Batch_Instructor__c instructor = new CCS_Batch_Instructor__c(
                Batch_Class__c = batchClass.Id,
                Instructor_Id__c = values[INSTRUCTOR_ID_FIELD_INDEX],
                First_Name__c = values[INSTRUCTOR_FIRST_NAME_FIELD_INDEX],
                Last_Name__c = values[INSTRUCTOR_LAST_NAME_FIELD_INDEX],
                Email_Address__c = values[INSTRUCTOR_EMAIL_FIELD_INDEX]
        );

        if (DEBUG_MODE) { System.debug('BatchInstructor created'); }

        return instructor;
    }


    /**
     * @description Creates a batch participant
     *
     * @param values
     */
    private CCS_Batch_Participant__c createParticipant(List<String> values) {
        if (String.isBlank(values[SENDER_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Sender ID');
        } else if (String.isBlank(values[BATCH_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Batch ID');
        } else if (String.isBlank(values[CLASS_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Offering ID');
        } else if (String.isBlank(values[PARTICIPANT_FIRST_NAME_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Participant First Name');
        } else if (String.isBlank(values[PARTICIPANT_LAST_NAME_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Participant Last Name');
        } else if (String.isBlank(values[PARTICIPANT_EMAIL_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Participant Email Address');
        } else if (String.isBlank(values[PARTICIPANT_MASTERY_FIELD_INDEX])) {
            throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Mastery Status');
        }

        List<String> possibleStatuses = new List<String>{
                SUCCESSFUL_MASTERY_STATUS,
                UNSUCCESSFUL_MASTERY_STATUS,
                NOT_EVALUATED_MASTERY_STATUS
        };

        String status = values[PARTICIPANT_MASTERY_FIELD_INDEX];
        if (!possibleStatuses.contains(status)) {
            throw new phss_cc_Exception(INVALID_MASTERY_STATUS_VALUE + ': ' + status);
        } else if (status == UNSUCCESSFUL_MASTERY_STATUS) {
            if (String.isBlank(values[PARTICIPANT_EVAL_NOTES_FIELD_INDEX])) {
                throw new phss_cc_Exception(MISSING_FIELD_VALUE + ': Evaluation Notes');
            }
        }

        String batchId = values[BATCH_FIELD_INDEX];
        CCS_Batch_Class__c batchClass = batchMap.get(batchId);
        CCS_Batch_Participant__c participant = new CCS_Batch_Participant__c(
                Batch_Class__c = batchClass.Id,
                First_Name__c = values[PARTICIPANT_FIRST_NAME_FIELD_INDEX],
                Last_Name__c = values[PARTICIPANT_LAST_NAME_FIELD_INDEX],
                Email_Address__c = values[PARTICIPANT_EMAIL_FIELD_INDEX],
                Phone_Number__c = values[PARTICIPANT_PHONE_FIELD_INDEX],
                Mastery_Status__c = values[PARTICIPANT_MASTERY_FIELD_INDEX],
                Evaluation_Notes__c = values[PARTICIPANT_EVAL_NOTES_FIELD_INDEX]
        );

        return participant;
    }
}