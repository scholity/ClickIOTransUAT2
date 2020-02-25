global class PHSS_GeolocationMockImpl implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response.
        // Set response values, and 
        // return response.
        
        String goodResp = '{ "results" : [ { "address_components" : [ { "long_name" : "25274", "short_name" : "25274", "types" : [ "street_number" ] }, { "long_name" : "West Elm Grove Drive", "short_name" : "W Elm Grove Dr", "types" : [ "route" ] }, { "long_name" : "Barrington", "short_name" : "Barrington", "types" : [ "locality", "political" ] }, { "long_name" : "Cuba Township", "short_name" : "Cuba Township", "types" : [ "administrative_area_level_3", "political" ] }, { "long_name" : "Lake County", "short_name" : "Lake County", "types" : [ "administrative_area_level_2", "political" ] }, { "long_name" : "Illinois", "short_name" : "IL", "types" : [ "administrative_area_level_1", "political" ] }, { "long_name" : "United States", "short_name" : "US", "types" : [ "country", "political" ] }, { "long_name" : "60010", "short_name" : "60010", "types" : [ "postal_code" ] }, { "long_name" : "2928", "short_name" : "2928", "types" : [ "postal_code_suffix" ] } ], "formatted_address" : "25274 W Elm Grove Dr, Barrington, IL 60010, USA", "geometry" : { "bounds" : { "northeast" : { "lat" : 42.1699157, "lng" : -88.12665389999999 }, "southwest" : { "lat" : 42.1696876, "lng" : -88.1268932 } }, "location" : { "lat" : 42.169828, "lng" : -88.1267936 }, "location_type" : "ROOFTOP", "viewport" : { "northeast" : { "lat" : 42.1711506302915, "lng" : -88.12542456970849 }, "southwest" : { "lat" : 42.1684526697085, "lng" : -88.12812253029149 } } }, "place_id" : "ChIJ20I1HR2hD4gRZiOVeAk-qTQ", "types" : [ "premise" ] } ], "status" : "OK" }';
        HTTPResponse resp = new HTTPResponse();
        resp.setBody(goodResp);
        return resp;
    }
}