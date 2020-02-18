public class PHSS_Geolocation {
    
    private virtual class baseResult {
        public boolean hasError {get;set;}
        public string errorMessage {get;set;}
        public string status { get; set; }
        
        public baseResult() {
            this.hasError = false;
        }
    }

    private class geocodeResult extends baseResult {
        public List<geocodeResultItem> results { get; set; }
        
        public geocodeResult() {
            super();
        }
    }

    private class geocodeResultItem {
        public Geometry geometry { get; set; }
    }
    
    private class Geometry {
        public GeoLocation location { get; set; }
    }
    
    private class GeoLocation {
        public double lat { get; set; }
        public double lng { get; set; }
    }

    @future (callout=true)
    public static void getGeocode(Id theLocationId) {
    //public static Location getGeocode(String location) {
        geocodeResult result = new geocodeResult();

        redwing__ILT_Location__c theLocation = [Select id, name, redwing__Address_1__c, redwing__Address_2__c,
                redwing__City__c, redwing__State__c, redwing__Postal_Code__c
                From redwing__ILT_Location__c Where Id = :theLocationId];

        String lookupAddress = '';
        if (String.isNotBlank(theLocation.redwing__Address_1__c))   lookupAddress += theLocation.redwing__Address_1__c;
        if (String.isNotBlank(theLocation.redwing__Address_2__c))   lookupAddress += ','+theLocation.redwing__Address_2__c;
        if (String.isNotBlank(theLocation.redwing__City__c))        lookupAddress += ','+theLocation.redwing__City__c;
        if (String.isNotBlank(theLocation.redwing__State__c))       lookupAddress += ','+theLocation.redwing__State__c;
        if (String.isNotBlank(theLocation.redwing__Postal_Code__c)) lookupAddress += ','+theLocation.redwing__Postal_Code__c;
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        string requestString = 'https://maps.googleapis.com/maps/api/geocode/json?address=' + EncodingUtil.URLENCODE(lookupAddress, 'UTF-8');
        
        PHSS_Geolocation__c geolocationSettings = [SELECT PHSS_Geolocation_API_Key__c from PHSS_Geolocation__c LIMIT 1];
        System.debug(geolocationSettings);
        if (!string.isBlank(geolocationSettings.PHSS_Geolocation_API_Key__c)) {
            requestString += '&key=' + geolocationSettings.PHSS_Geolocation_API_Key__c;
        }
        
        req.setEndpoint(requestString);
        req.setMethod('GET');
        req.setTimeout(60000);
        try {
            HttpResponse res = h.send(req);
            string jsonResult = res.getBody();
            System.debug(jsonResult);
            result = (geocodeResult)(Json.deserialize(jsonResult, geocodeResult.class));

            if (result != null && result.results.size() > 0) {
                redwing__ILT_Location__c theUpdatedLocation = new redwing__ILT_Location__c();
                theUpdatedLocation.Id = theLocationId;
                theUpdatedLocation.GeoLocation__Latitude__s = result.results[0].geometry.location.lat;
                theUpdatedLocation.GeoLocation__Longitude__s = result.results[0].geometry.location.lng;
                theUpdatedLocation.redwing__Directions__c = String.ValueOf(theUpdatedLocation.GeoLocation__Latitude__s)+','+String.ValueOf(theUpdatedLocation.GeoLocation__Longitude__s);
                update theUpdatedLocation;
            }
            
            if (result.status != 'OK') {
                result.HasError = true;
                result.ErrorMessage = result.status;
            } else {
                result.HasError = false;
            }
        } catch (Exception e) {
            result.HasError = true;
            result.ErrorMessage = e.getMessage() + '\n' + e.getStackTraceString();
        }

        return;
        /*
        return (result.results.size() > 0) ?
            Location.newInstance(result.results[0].geometry.location.lat, 
                                 result.results[0].geometry.location.lng) : NULL;
        */
    }
}