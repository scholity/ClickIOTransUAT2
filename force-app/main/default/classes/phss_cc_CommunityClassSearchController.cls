public with sharing class phss_cc_CommunityClassSearchController {

    public static final String COMMUNITY_INVENTORY_TYPE     = 'COMMUNITY';

    public static final String COURSES_KEY                  = 'courses';
    @testVisible private static final String INVENTORY_TYPE_KEY          = 'inventoryType';
    @testVisible private static final String DISTANCE_IN_MILES_KEY       = 'mi';
    @testVisible private static final String PRODUCTS_KEY                = 'productMap';
    @testVisible private static final String SFID_KEY                    = 'sfid';

    @testVisible private static final Integer MINUTES_PER_DAY            = 1440;
    @testVisible private static final Integer MINUTES_PER_HOUR           = 60;

    /* Class/Course Field Keys */
    @testVisible private static final String ADDRESS_KEY                 = 'address';
    @testVisible private static final String COURSE_KEY                  = 'course';
    @testVisible private static final String DURATION_KEY                = 'duration';
    @testVisible private static final String ID_KEY                      = 'id';
    @testVisible private static final String ILT_CLASS_ID                = 'iltClassId';
    @testVisible private static final String LOCATION_NAME_KEY           = 'locationName';
    @testVisible private static final String NAME_KEY                    = 'name';
    @testVisible private static final String PRICE_OVERRIDE_KEY          = 'priceOverride';
    @testVisible private static final String SEATS_AVAILABLE_KEY         = 'seatsAvailable';
    @testVisible private static final String START_DATETIME_KEY          = 'startDatetime';
    @testVisible private static final String START_MONTH_KEY             = 'startMonth';
    @testVisible private static final String START_DAY_KEY               = 'startDay';
    @testVisible private static final String START_WEEKDAY_KEY           = 'startWeekday';
    @testVisible private static final String START_WEEKDAY_ABBREV_KEY    = 'startWeekdayAbbreviation';
    @testVisible private static final String START_TIME_KEY              = 'startTime';
    @testVisible private static final String START_TIME_AM_PM_KEY        = 'startTimeAMPM';

    @testVisible private static final String REQUIRES_DATE_ACKNOWLEDGEMENT_KEY   = 'requiresDateAcknowledgement';

    //  error messages
    @testVisible private static final String FAILED_TO_FETCH_TRAINING_CLASSES = 'Failed to fetch training classes.';
    @testVisible private static final String FAILED_TO_GET_AVAILABILITY_FOR_ILT_CLASSES  = 'Failed to get the availability for ILT classes.';
    @testVisible private static final String FAILED_TO_GET_ILT_CLASSES = 'Failed to get the ILT classes';
    @testVisible private static final String FAILED_TO_GET_LOCATION_COORDINATES = 'Failed to get the location coordinates';
    @testVisible private static final String FAILED_TO_GET_SKEDULO_JOBS = 'Failed to get the Skedulo jobs.';


    /**
     * @description Adds classes to the active cart associated with the specified opportunity
     *
     * @param opportunityId
     * @param items
     *
     * @return
     */
    @AuraEnabled
    public static Map<String, Object> addClassesToCart(String opportunityId, String items) {

        Map<String, Object> addToCartResult;
        Map<String, Object> classData = parseClassCourseQuantities(items);

        try {
            addToCartResult = phss_cc_ClassCartUtil.addClassesToCart(opportunityId, classData);
        } catch (Exception e) {
            addToCartResult = phss_cc_Exception.getErrorMessageMap(e.getMessage());
        }

        return addToCartResult;
    }

    /**
     * @description Searches for classes matching specified criteria
     *
     * @param searchTerm
     * @param opportunityId
     * @param startDateStr
     * @param endDateStr
     * @param city
     * @param state
     * @param postalCode
     * @param range
     *
     * @return
     */
    @AuraEnabled
    public static Map<String, Object> classSearch(String searchTerm, String opportunityId, String startDateStr, String endDateStr, String city, String state, String postalCode, Integer range) {

        if (String.isBlank(searchTerm)
                || searchTerm.length() < 3
                || String.isBlank(opportunityId)
                || String.isBlank(startDateStr)
                || String.isBlank(endDateStr)) {
            return null;
        }

        Map<String, Object> result = new Map<String, Object>();

        try {
            Date startDate = (Date) JSON.deserialize(startDateStr, Date.class);
            Date endDate = (Date) JSON.deserialize(endDateStr, Date.class);

            Map<String, Object> courses = searchCommunityCourses(opportunityId, searchTerm);
            Geo_Location__c anchorPoint = getCoordinates(city, state, postalCode);
            List<redwing__ILT_Class__c> trainingClasses = fetchTrainingClasses(courses.keySet(), startDate, endDate, range, anchorPoint);

            Map<Id, Id> jobCourses = new Map<Id, Id>();
            if (trainingClasses != null) {
                for (redwing__ILT_Class__c trainingClass : trainingClasses) {
                    jobCourses.put(trainingClass.Skedulo_Job_Id_External__c, trainingClass.Cloud_Craze_Product__c);
                }
            }

            Map<Id, Integer> seatsAvailable = getAvailabilityForClasses(new Map<Id, redwing__ILT_Class__c>(trainingClasses).keySet());

            Map<Id, sked__Job__c> jobs = getSkeduloJobs(jobCourses.keySet());
            jobs = getNearbyJobs(jobs, city, state, postalCode, range);

            List<Object> classCourses = buildClassCourses(trainingClasses, jobs, courses, jobCourses, seatsAvailable);
            result.put(COURSES_KEY, classCourses);

        } catch (Exception e) {
            result.put('ERROR', e);
        }

        return result;
    }


    @testVisible 
    private static List<redwing__ILT_Class__c> fetchTrainingClasses(Set<String> productIds, Date startDate, Date endDate, Integer distanceVal, Geo_Location__c anchorPoint) {
        if (productIds == null || productIds.size() == 0 || startDate == null || endDate == null) {
            return null;
        }

        List<redwing__ILT_Class__c> trainingClasses;

        try {
            distanceVal = distanceVal + 1; //DISTANCE function only supports < and >, adding 1 so query grabs values that are equal to the original distanceVal
            
            trainingClasses = [
                    SELECT
                            Cloud_Craze_Product__c,
                            Id,
                            redwing__End_Date__c,
                            redwing__End_Time__c,
                            redwing__Learning__c,
                            redwing__Max_Seats__c,
                            redwing__Start_Date__c,
                            redwing__Start_Time__c,
                            Skedulo_Job_Id_External__c,
                            Price_Override__c
                    FROM
                            redwing__ILT_Class__c
                    WHERE
                            Cloud_Craze_Product__c IN :productIds
                                AND redwing__Start_Date__c >= :startDate
                                AND redwing__Start_Date__c <= :endDate
                                AND DISTANCE(redwing__Location__r.Skedulo_Location__r.sked__GeoLocation__c, :anchorPoint.Coordinates__c, 'mi') < :distanceVal
                    ORDER BY
                            redwing__Start_Date__c
                    LIMIT 50000
            ];
            system.debug('@@@fetchTrainingClasses trainingClasses size: '+trainingClasses.size());
        } catch (Exception e) {
            throw new phss_cc_Exception(FAILED_TO_FETCH_TRAINING_CLASSES, e);
        }

        return trainingClasses;
    }


    /**
     * @description Searches for courses matching the specified search term
     *
     * @param opportunityId
     * @param searchTerm
     *
     * @return
     */
    @testVisible 
    private static Map<String, Object> searchCommunityCourses(String opportunityId, String searchTerm) {

        Map<String, Object> searchResult = phss_cc_ProductUtil.productSearch(opportunityId, searchTerm);
        Map<String, Object> products = (Map<String, Object>) searchResult.get(PRODUCTS_KEY);
        Map<String, Object> courses = new Map<String, Object>();

        if (products != null) {
            for (String id : products.keySet()) {
                Map<String, Object> product = (Map<String, Object>) products.get(id);
                if (product.get(INVENTORY_TYPE_KEY) == COMMUNITY_INVENTORY_TYPE) {
                    courses.put((String) product.get(SFID_KEY), product);
                }
            }
        }

        return courses;
    }

    /**
     * @description Fetches the available vouchers for the specified ILT classes
     *
     * @param classIdentifiers
     *
     * @return
     */
    @testVisible 
    private static Map<Id, Integer> getAvailabilityForClasses(Set<Id> classIdentifiers) {

        Map<Id, Integer> availabilityMap = new Map<Id, Integer>();

        try {
            AggregateResult[] results = [
                    SELECT ILT_Class__c, COUNT(Id) seatsAvailable
                    FROM Voucher__c
                    WHERE ILT_Class__c IN :classIdentifiers
                    AND Status__c = 'Issued'
                    GROUP BY ILT_Class__c
            ];

            for (AggregateResult vouchers : results) {
                availabilityMap.put((Id) vouchers.get('ILT_Class__c'), (Integer) vouchers.get('seatsAvailable'));
            }

        } catch (Exception e) {
            throw new phss_cc_Exception(FAILED_TO_GET_AVAILABILITY_FOR_ILT_CLASSES, e);
        }

        return availabilityMap;
    }

    /**
     * @description Fetches Skedulo jobs
     *
     * @param jobIdentifiers
     *
     * @return
     */
    @testVisible 
    private static Map<Id, sked__Job__c> getSkeduloJobs(Set<Id> jobIdentifiers) {

        Map<Id, sked__Job__c> jobMap = new Map<Id, sked__Job__c>();

        try {
            List<sked__Job__c> jobList = [
                    SELECT Id, Job_Month__c, Location_Name__c, Name, Number_of_Students__c, sked__Address__c, sked__Duration__c, sked__Location__r.sked__GeoLocation__c, sked__Start__c, sked__Timezone__c
                    FROM sked__Job__c
                    WHERE Id IN :jobIdentifiers];

            for (sked__Job__c job : jobList) {
                jobMap.put(job.Id, job);
            }
        } catch (Exception e) {
            throw new phss_cc_Exception(FAILED_TO_GET_SKEDULO_JOBS, e);
        }

        return jobMap;
    }

    /**
     * @description Filters a list of jobs based on proximity to a location
     *
     * @param jobs
     * @param city
     * @param state
     * @param postalCode
     * @param range
     *
     * @return
     */
    @testVisible 
    private static Map<Id, sked__Job__c> getNearbyJobs(Map<Id, sked__Job__c> jobs, String city, String state, String postalCode, Integer range) {

        Map<Id, sked__Job__c> nearbyJobs = new Map<Id, sked__Job__c>();
        //Set<Location> locations = getCoordinates(city, state, postalCode);

        for (Id id : jobs.keySet()) {
            sked__Job__c job = jobs.get(id);
            /*
            for (Location location : locations) {
                if (job.sked__Location__c != null && job.sked__Location__r.sked__GeoLocation__c != null) {
                    Double distance = job.sked__Location__r.sked__GeoLocation__c.getDistance(location, DISTANCE_IN_MILES_KEY);
                    if (distance <= range) {
                        nearbyJobs.put(id, job);
                        break;
                    }
                }
            }
            */
            nearbyJobs.put(id, job);
        }
        system.debug('@@@nearbyJobs count: '+nearbyJobs.size());
        return nearbyJobs;
    }

    /**
     * @description Returns a list of GeoLocations matching the specified city, state, and postal code.
     *
     * @param city
     * @param state
     * @param postalCode
     *
     * @return
     */
    @testVisible
    private static Geo_Location__c getCoordinates(String city, String state, String postalCode) {
        //May need function to find central postal code when a city/state supplied and no postal code
        Geo_Location__c locationOfInterest;
        List<Geo_Location__c> locations = new List<Geo_Location__c>();
        try {
            if (String.isNotBlank(postalCode)) {
                if (String.isNotBlank(state)) {
                    if (String.isNotBlank(city)) {
                        locations = [
                                SELECT Id, Coordinates__c
                                FROM Geo_Location__c
                                WHERE City_UC__c = :city.toUpperCase()
                                AND State_Abbreviation__c = :state
                                AND Postal_Code__c LIKE :postalCode
                        ];
                    }
                    else {
                        locations = [
                                SELECT Id, Coordinates__c
                                FROM Geo_Location__c
                                WHERE State_Abbreviation__c = :state
                                AND Postal_Code__c = :postalCode
                        ];
                    }
                }
                else {
                    locations = [
                            SELECT Id, Coordinates__c
                            FROM Geo_Location__c
                            WHERE Postal_Code__c = :postalCode
                    ];
                }
            }
            else if (String.isNotBlank(city) && String.isNotBlank(state)) {
                locations = [
                        SELECT Id, Coordinates__c
                        FROM Geo_Location__c
                        WHERE City_UC__c = :city.toUpperCase()
                        AND State_Abbreviation__c = :state
                ];
            }
        } catch (Exception e) {
            throw new phss_cc_Exception(FAILED_TO_GET_LOCATION_COORDINATES, e);
        }
        if(!locations.isEmpty()){
            locationOfInterest = locations[0]; //we need to choose a single location to use lat/long value from in the DISTANCE query params
        }
        return locationOfInterest;
    }

    /**
     * @description Builds a map of ILT class- and course-related data
     *
     * @param classes
     * @param jobs
     * @param courses
     * @param jobCourses
     *
     * @return
     */
    public static List<Object> buildClassCourses(List<redwing__ILT_Class__c> classes, Map<Id, sked__Job__c> jobs, Map<String, Object> courses, Map<Id, Id> jobCourses, Map<Id, Integer> seatsAvailable) {

        List<Object> classCourses = new List<Object>();
        system.debug('***classes***'+classes);

        for (redwing__ILT_Class__c iClass : classes) {
            sked__Job__c job = jobs.get(iClass.Skedulo_Job_Id_External__c);
            if (job != null) {
                Map<String, Object> classMap = new Map<String, Object>();
                classMap.put(ILT_CLASS_ID, iClass.Id);

                Datetime startDate = getDatetime(iClass.redwing__Start_Date__c, iClass.redwing__Start_Time__c);
                Datetime endDate = getDatetime(iClass.redwing__End_Date__c, iClass.redwing__End_Time__c);
                if (startDate != null) {
                    classMap.put(START_DATETIME_KEY, startDate);
                    classMap.put(START_MONTH_KEY, startDate.format('MMM'));
                    classMap.put(START_DAY_KEY, startDate.format('d'));
                    classMap.put(START_WEEKDAY_KEY, startDate.format('EEEE'));
                    classMap.put(START_WEEKDAY_ABBREV_KEY, startDate.format('EEE.'));
                    classMap.put(START_TIME_KEY, startDate.format('H:mm'));
                    classMap.put(START_TIME_AM_PM_KEY, startDate.format('a'));

                    if (endDate != null) {
                        Long millisecondsElapsed = endDate.getTime() - startDate.getTime();
                        Long minutesElapsed = millisecondsElapsed / 1000 / 60;
                        classMap.put(DURATION_KEY, formatDuration(minutesElapsed.intValue()));
                    }

                    if (startDate < Datetime.now()) {
                        classMap.put(REQUIRES_DATE_ACKNOWLEDGEMENT_KEY, true);
                    }
                }

                if (String.isNotBlank(job.Id)) {
                    classMap.put(ID_KEY, job.Id);
                }
                if (String.isNotBlank(job.Location_Name__c)) {
                    classMap.put(LOCATION_NAME_KEY, job.Location_Name__c);
                }
                if (String.isNotBlank(job.sked__Address__c)) {
                    classMap.put(ADDRESS_KEY, job.sked__Address__c);
                }

                classMap.put(NAME_KEY, job.Name);

                Integer seatCount = seatsAvailable.get(iClass.Id);
                if (seatCount == null) {
                    seatCount = 0;
                }
                classMap.put(SEATS_AVAILABLE_KEY, seatCount);

                if (iClass.Price_Override__c != null) {
                    classMap.put(PRICE_OVERRIDE_KEY, iClass.Price_Override__c);
                }

                Id courseId = jobCourses.get(job.Id);
                if (courseId != null) {
                    Map<String, Object> course = (Map<String, Object>) courses.get(courseId);
                    if (course != null) {
                        classMap.put(COURSE_KEY, course);
                    }
                }

                classCourses.add(classMap);
            }
        }

        return classCourses;
    }

    /**
     * @description Returns a duration formatted as a String
     *
     * @param duration time in minutes
     *
     * @return
     */
    @testVisible
    private static String formatDuration(Integer duration) {
        String result = '';

        if (duration >= MINUTES_PER_DAY) {
            Integer days = duration / MINUTES_PER_DAY;
            result += (days + 'd ');
            duration = Math.mod(duration, MINUTES_PER_DAY);
        }

        if (duration >= MINUTES_PER_HOUR) {
            Integer hours = duration / MINUTES_PER_HOUR;
            result += (hours + 'h ');
            duration = Math.mod(duration, MINUTES_PER_HOUR);
        }

        if (duration > 0) {
            result += (duration + 'm');
        }

        return result.trim();
    }

    /**
     * @description Creates a Datetime from a Date and a time String
     *
     * @param d
     * @param t
     *
     * @return
     */
    @testVisible
    private static Datetime getDatetime(Date d, String timeStr) {
        Datetime dt;

        Time t;
        if (String.isNotBlank(timeStr)) {
            List<String> components = timeStr.split(':');
            if (components.size() == 2) {
                Integer hours = Integer.valueOf(components[0]);
                Integer minutes = Integer.valueOf(components[1]);
                t = Time.newInstance(hours, minutes, 0, 0);
            }
        }
        else {
            t = Time.newInstance(0, 0, 0, 0);
        }

        if (d != null && t != null) {
            dt = Datetime.newInstance(d, t);
        }

        return dt;
    }

    /**
     * @description Parses quantities of ILT classes and courses
     *
     * @param input
     *
     * @return
     */
    @testVisible
    private static Map<String, Object> parseClassCourseQuantities(String input) {
        if (String.isBlank(input)) {
            return null;
        }

        List<Id> classList = new List<Id>();
        Map<String, String> classCourseMap = new Map<String, String>();
        Map<String, Integer> classQuantityMap = new Map<String, Integer>();

        List<Object> items = (List<Object>) JSON.deserializeUntyped(input);
        for (Object item : items) {
            if (item instanceof Map<String, Object>) {
                Map<String, Object> classMap = (Map<String, Object>) item;
                String classId = (String) classMap.get(phss_cc_ClassCartUtil.CLASS_ID_KEY);
                String courseId = (String) classMap.get(phss_cc_ClassCartUtil.COURSE_ID_KEY);
                Integer quantity = (Integer) classMap.get(phss_cc_ClassCartUtil.COUNT_KEY);

                if (classId != null && courseId != null && quantity != null) {
                    classList.add(classId);
                    classCourseMap.put(classId, courseId);
                    classQuantityMap.put(classId, quantity);
                }
            }
        }

        Map<String, Object> result = new Map<String, Object>{
                phss_cc_ClassCartUtil.CLASS_ID_LIST => classList,
                phss_cc_ClassCartUtil.CLASS_COURSE_MAP => classCourseMap,
                phss_cc_ClassCartUtil.CLASS_QUANTITY_MAP => classQuantityMap
        };

        return result;
    }
}