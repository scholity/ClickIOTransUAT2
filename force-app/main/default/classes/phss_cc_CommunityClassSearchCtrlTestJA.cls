@isTest (SeeAllData = true)
public with sharing class phss_cc_CommunityClassSearchCtrlTestJA
{
    private static String formatDateAsYYYYMMDD(Date d) {
        String dateStr;

        if (d != null) {
            dateStr = '' + d.year() + '-' + d.month() + '-' + d.day();
        }

        return dateStr;
    }
    
    @isTest static void testClassSearch()
    {
        String testSearchTerm = 'First';
        
        Id testOpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        //date testStartDate = date.today();
        //date testEndDate	= date.today();
        String testStartDate = formatDateAsYYYYMMDD(phss_cc_TestDataFactory.TEST_COMMUNITY_CLASS_SEARCH_START_DATE);
        String testEndDate = formatDateAsYYYYMMDD(phss_cc_TestDataFactory.TEST_COMMUNITY_CLASS_SEARCH_END_DATE);
        string testCity	= 'Fairfield';
        string testState = 'NJ';
        //string testPostalCode = '07004';
        
        //String searchTerm, String opportunityId, String startDateStr, String endDateStr, String city, String state, String postalCode, Integer range
        Test.startTest();

        	phss_cc_CommunityClassSearchController.classSearch(testSearchTerm, testOpportunityId, testStartDate, testEndDate, testCity, testState, null, 1);
        
        Test.stopTest();

    }

    @isTest
    static void testAddToCart() {
/*
        setup();
        String testOpportunityId = testOpportunity.Id;
        String testIltClassId = testIltClass.Id;
        String testCourseId = testProduct.Id;
        Map<String, Object> items = new Map<String, Object>{
                phss_cc_ClassCartUtil.CLASS_ID_KEY => testIltClassId,
                phss_cc_ClassCartUtil.COURSE_ID_KEY => testCourseId,
                phss_cc_ClassCartUtil.COUNT_KEY => 1
        };
        List<Map<String, Object>> classList = new List<Map<String, Object>>();
        classList.add(items);
        String json = JSON.serialize(classList);
        Test.startTest();
        Map<String, Object> result = phss_cc_CommunityClassSearchController.addClassesToCart(testOpportunityId, json);
        Test.stopTest();*/
    }
    
    @isTest
    static void testbuildClassCourses()
    {
        
    }

}