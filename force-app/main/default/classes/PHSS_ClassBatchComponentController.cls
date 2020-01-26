public class PHSS_ClassBatchComponentController {

    //
    private static final String CLASS_ORG_RECORD_TYPE   = 'A';
    private static final String INSTRUCTOR_RECORD_TYPE  = 'B';
    private static final String STUDENT_RECORD_TYPE     = 'C';

    // error messages
    public static final String FAILED_TO_FETCH_SENDER_ACCOUNT = 'Failed to fetch the sender\'s account';
    public static final String FAILED_TO_IDENTIFY_SENDER = 'Failed to identify the sender of the batch';
    public static final String INCONSISTENT_VALUE_FOUND = 'Inconsistent value found';
    public static final String INVALID_RECORD_TYPE = 'Invalid record type';
    public static final String MISSING_BATCH_ID = 'Missing batch identifier';
    public static final String MISSING_FIELD = 'Missing field: ';
    public static final String MISSING_GROUP_ID = 'Missing group identifier';
    public static final String MISSING_RECORD_TYPE = 'Missing record type';
    public static final String MISSING_SENDER_ID = 'Missing sender identifier';
    public static final String NO_BATCH_DATA_TO_PROCESS = 'No batch data was submitted for processing';

    private static PHSS_ClassBatch batch;

    public class PHSS_ClassBatch {
        public Id senderId;
        public String batchId;
        public String groupId;
    }

    public class PHSS_ClassBatchException extends Exception {
    }

    public class PHSS_ClassBatchWrapper {
        public String senderId;
        public String batchId;
        public String groupId;
        public String recordType;
        public String orgId;
        public String orgName;
        public String PO;
        public String courseCode;
        public String courseVersion;
        public String courseEndDate;
        public String totalStudents;
        public String trainingSiteName;
        public String trainingSiteAddress;
        public String trainingSiteCity;
        public String trainingSiteState;
        public String trainingSiteZipCode;
        public String instructorId;
        public String instructorFirstName;
        public String instructorLastName;
        public String instructorEmail;
        public String studentFirstName;
        public String studentLastName;
        public String studentEmail;
        public String studentPhone;
        public String masteryStatus;
    }


    /**
     *
     *
     * @param dataStr
     *
     * @return
     */
    @AuraEnabled
    public static Map<String, Object> processBatch(String dataStr) {

        Map<String, Object> results;
        try {
            List<PHSS_ClassBatchWrapper> dataList = (List<PHSS_ClassBatchWrapper>) JSON.deserialize(dataStr, List<PHSS_ClassBatchWrapper>.class);
            if (dataList == null || dataList.size() == 0) {
                throw new PHSS_ClassBatchException(NO_BATCH_DATA_TO_PROCESS);
            }

            results = validateBatchData(dataList);

        } catch (Exception e) {
            results = new Map<String, Object>{
                    'Error' => 'Failed to process the batch data because of an exception: ' + e.getMessage()
            };
        }

        return results;
    }


    /**
     *
     *
     * @param data
     *
     * @return
     */
    private static Map<String, Object> validateBatchData(List<PHSS_ClassBatchWrapper> data) {

        batch = new PHSS_ClassBatch();

        validateSender(data);
        validateBatchIdentifier(data);
        validateGroupIdentifier(data);
        validateRecords(data);

        Map<String, Object> results = new Map<String, Object>();

        if (results.size() == 0) {
            throw new PHSS_ClassBatchException('no data validated');
        }

        return results;
    }


    /**
     * @description Validates the batch identifier within the batch data.
     *
     * @param data
     */
    private static void validateBatchIdentifier(List<PHSS_ClassBatchWrapper> data) {

        PHSS_ClassBatchWrapper firstRecord = data[0];
        if (String.isBlank(firstRecord.batchId)) {
            throw new PHSS_ClassBatchException(MISSING_BATCH_ID + ' from first record');
        }

        String batchIdentifier = firstRecord.batchId;
        for (PHSS_ClassBatchWrapper wrapper : data) {
            if (String.isBlank(wrapper.batchId)) {
                throw new PHSS_ClassBatchException(MISSING_BATCH_ID);
            }
            if (wrapper.batchId != batchIdentifier) {
                throw new PHSS_ClassBatchException(INCONSISTENT_VALUE_FOUND + '  field name: \'Batch ID\'  expected: ' + batchIdentifier + '  found: ' + wrapper.batchId);
            }
        }

        batch.batchId = batchIdentifier;
    }


    /**
     * @description Validates the record as a class org
     *
     * @param record
     */
    private static void validateClassOrg(PHSS_ClassBatchWrapper record) {
        /*
         Organization ID|Organization Name|PO Number|Course Code|Course Version|Course End Date|Total Students|Training Site Name|Training Site Address|Training Site City|Training Site State|Training Site Zip
         */


    }


    /**
     * @description Validates the group ID within the batch data.
     *
     * @param data
     */
    private static void validateGroupIdentifier(List<PHSS_ClassBatchWrapper> data) {

        PHSS_ClassBatchWrapper firstRecord = data[0];
        if (String.isBlank(firstRecord.groupId)) {
            throw new PHSS_ClassBatchException(MISSING_GROUP_ID + 'from first record');
        }

        String groupIdentifier = firstRecord.groupId;
        for (PHSS_ClassBatchWrapper wrapper : data) {
            if (String.isBlank(wrapper.groupId)) {
                throw new PHSS_ClassBatchException(MISSING_GROUP_ID);
            }
            if (wrapper.groupId != groupIdentifier) {
                throw new PHSS_ClassBatchException(INCONSISTENT_VALUE_FOUND + '  field name: \'Group ID\'  expected: ' + groupIdentifier + '  found: ' + wrapper.groupId);
            }
        }

        batch.groupId = groupIdentifier;
    }


    /**
     * @description Validates the record as an instructor
     *
     * @param record
     */
    private static void validateInstructor(PHSS_ClassBatchWrapper record) {

        /*
        Sender ID|Batch ID|Group ID|Record Type|Instructor ID|Instructor First Name|Instructor Last Name|Instructor Email Address
         */
    }


    /**
     * @description Validates each record within the batch data
     *
     * @param data
     */
    private static void validateRecords(List<PHSS_ClassBatchWrapper> data) {

        for (PHSS_ClassBatchWrapper wrapper : data) {
            if (String.isNotBlank(wrapper.recordType)) {
                if (wrapper.recordType == CLASS_ORG_RECORD_TYPE) {
                    validateClassOrg(wrapper);
                } else if (wrapper.recordType == INSTRUCTOR_RECORD_TYPE) {
                    validateInstructor(wrapper);
                } else if (wrapper.recordType == STUDENT_RECORD_TYPE) {
                    validateStudent(wrapper);

                } else {
                    String possibleRecordTypes = CLASS_ORG_RECORD_TYPE + ', ' + INSTRUCTOR_RECORD_TYPE + ', or ' + STUDENT_RECORD_TYPE;
                    throw new PHSS_ClassBatchException(INVALID_RECORD_TYPE + '  possible values: ' + possibleRecordTypes + '  actual value: ' + wrapper.recordType);
                }

            } else {
                throw new PHSS_ClassBatchException(MISSING_RECORD_TYPE);
            }
        }
    }


    /**
     * @description Validates the sender within the batch data.
     *
     * @param data
     */
    private static void validateSender(List<PHSS_ClassBatchWrapper> data) {

        PHSS_ClassBatchWrapper firstRecord = data[0];
        if (String.isBlank(firstRecord.senderId)) {
            throw new PHSS_ClassBatchException(MISSING_SENDER_ID + 'from first record');
        }

        String senderIdentifier = firstRecord.senderId;
        for (PHSS_ClassBatchWrapper wrapper : data) {
            if (String.isBlank(wrapper.senderId)) {
                throw new PHSS_ClassBatchException(MISSING_SENDER_ID);
            }
            if (wrapper.senderId != senderIdentifier) {
                throw new PHSS_ClassBatchException(INCONSISTENT_VALUE_FOUND + '  field name: \'Sender ID\'  expected: ' + senderIdentifier + '  found: ' + wrapper.senderId);
            }
        }

        try {
            Id accountId = Id.valueOf(senderIdentifier);
            Account account = [SELECT Id, Name FROM Account WHERE Id = :accountId];
            if (account == null) {
                throw new PHSS_ClassBatchException(FAILED_TO_FETCH_SENDER_ACCOUNT);
            }

            batch.senderId = accountId;

        } catch (Exception e) {
            throw new PHSS_ClassBatchException(FAILED_TO_IDENTIFY_SENDER + ': ' + e.getMessage());
        }
    }


    /**
     * @description Validates the record as a student
     *
     * @param record
     */
    private static void validateStudent(PHSS_ClassBatchWrapper record) {

        if (String.isBlank(record.studentFirstName)) { throw new PHSS_ClassBatchException(MISSING_FIELD + 'Participant First Name'); }
        if (String.isBlank(record.studentLastName)) { throw new PHSS_ClassBatchException(MISSING_FIELD + 'Participant Last Name'); }
        if (String.isBlank(record.studentEmail)) { throw new PHSS_ClassBatchException(MISSING_FIELD + 'Participant Email Address'); }
        if (String.isBlank(record.studentPhone)) { throw new PHSS_ClassBatchException(MISSING_FIELD + 'Participant Phone Number'); }
        if (String.isBlank(record.masteryStatus)) { throw new PHSS_ClassBatchException(MISSING_FIELD + 'Mastery Status'); }
        /*
        Sender ID|Batch ID|Group ID|Record Type|Participant First Name|Participant Last Name|Participant Email Address|Participant Phone Number|Mastery Status
         */
    }
}