@IsTest
public class PHSS_Geolocation_test {

    @IsTest(seeAllData=false)
    public static void testmethod1()
    {
        PHSS_Geolocation_test.createSetting();
        
        redwing__ILT_Location__c loc = new redwing__ILT_Location__c();
  		loc.redwing__Address_1__c = '25274 W Elm Grove Dr';
        loc.redwing__City__c = 'Barrington';
        loc.redwing__State__c = 'IL';
        loc.redwing__Postal_Code__c = '60010';
        insert loc;

        Test.startTest();
        Test.setMock(HttpCalloutMock .class, new PHSS_GeolocationMockImpl());

        //String address = '25274 W Elm Grove Dr.,Barrington,IL,60010';
		PHSS_Geolocation.getGeocode(loc.Id);
		Test.stopTest();

        redwing__ILT_Location__c updatedLoc = [Select id, name, redwing__Address_1__c, redwing__Address_2__c,
                redwing__City__c, redwing__State__c, redwing__Postal_Code__c,GeoLocation__latitude__s,GeoLocation__longitude__s
                From redwing__ILT_Location__c Where Id = :loc.Id];
        
        System.assert(updatedLoc.GeoLocation__latitude__s == 42.169828);
        System.assert(updatedLoc.GeoLocation__longitude__s == -88.1267936);
    }
    
    private static void createSetting()
    {
        PHSS_Geolocation__c setting = new PHSS_Geolocation__c();
        setting.PHSS_Geolocation_API_Key__c = 'AIzaSyAbiSkystXXjCtlOAtH6H-4Ej2GLn_EbNM';
        insert setting;
    }
}