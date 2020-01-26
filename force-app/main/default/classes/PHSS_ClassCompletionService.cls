@RestResource(urlMapping='/PHSSClassCompletion/batch/*')
global with sharing class PHSS_ClassCompletionService {

    private static final Boolean DEBUG_MODE     = true;

    private static final String EOL_WINDOWS     = '\r\n';
    private static final String EOL_UNIX        = '\n';
    private static final String EOL_MAC_OLD     = '\r';

    // error messages
    private static final String NO_DATA_FOUND   = 'No data found.';


    @HttpPost
    global static String process() {

        String buffer = EncodingUtil.base64Decode(EncodingUtil.base64Encode(RestContext.request.requestBody)).toString();
        if (String.isBlank(buffer)) {
            return NO_DATA_FOUND;
        }

        Map<String, Object> result;
        try {
            List<String> records = parseData(buffer);

            PHSS_ClassCompletionBatch batch = new PHSS_ClassCompletionBatch();
            result = batch.processData(records);


        } catch (Exception e) {
            return e.getMessage();
        }

        if (!result.containsKey(PHSS_ClassCompletionBatch.SUCCESS_KEY)) {
            return String.valueOf(result);
        }

        return 'Done';
    }


    private static List<String> parseData(String buffer) {

        String eol = null;
        if (buffer.contains(EOL_WINDOWS)) {
            if (DEBUG_MODE) { System.debug('delimiter: Windows'); }
            eol = EOL_WINDOWS;
        } else if (buffer.contains(EOL_UNIX)) {
            if (DEBUG_MODE) { System.debug('delimiter: Unix'); }
            eol = EOL_UNIX;
        } else if (buffer.contains(EOL_MAC_OLD)) {
            if (DEBUG_MODE) { System.debug('delimiter: Mac (old)'); }
            eol = EOL_MAC_OLD;
        }

        List<String> records = new List<String>();
        if (eol != null) {
            records = buffer.split(eol);
        } else {
            records.add(buffer);
        }

        if (DEBUG_MODE) { System.debug('Number of records received: ' + records.size()); }

        return records;
    }
}