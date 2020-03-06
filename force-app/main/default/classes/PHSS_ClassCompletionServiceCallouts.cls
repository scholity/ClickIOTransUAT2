public class PHSS_ClassCompletionServiceCallouts {
    
    public static HttpResponse makePostCallout(String fileContent) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://arc-phss--TransUAT.cs26.my.salesforce.com/services/apexrest/PHSSClassCompletion/batch/');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'text/plain');
        request.setBody(fileContent);
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 201) {
            System.debug('The status code returned was not expected: ' +
                response.getStatusCode() + ' ' + response.getStatus());
        } else {
            System.debug(response.getBody());
        }
        return response;
    }       

}