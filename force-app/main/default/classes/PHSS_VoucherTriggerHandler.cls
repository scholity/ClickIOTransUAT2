/************************************************************************************************************************************
** Author: Salesforce Services
** Description: This is the trigger handler class for the voucher trigger
************************************************************************************************************************************/
public class PHSS_VoucherTriggerHandler {
    public PHSS_VoucherTriggerHandler(){}
    // Static variables are local to the context of a Web request 
    // (or testMethod during a runTests call) 
    // Therefore, this variable will be initialized as false 
    // at the beginning of each Web request which accesses it.
    private static boolean alreadyUpdatedVouchers = false;
    public static boolean hasAlreadyUpdatedVouchers() {
        return alreadyUpdatedVouchers;
    }
    // By setting the variable to true, it maintains this 
    // new value throughout the duration of the request
    public static void setAlreadyUpdatedVouchers() {
        alreadyUpdatedVouchers = true;
    }
    /************************************************************************************************************************************
    ** Author: Salesforce Services
    ** Description: This method is used to insure there are a minimum number of open (Issued) vouchers for an online class
    ** It uses a floor and ceiling of 25 and 100 by default (insure that there are at least 100 open vouchers when the total drops below 25)
    ************************************************************************************************************************************/
    public void CheckTotalAvailableOnlineVouchers(list<Voucher__c> newVouchers, List<Voucher__c> oldVouchers, Map<ID,Voucher__c> newVoucherMap , Map<ID,Voucher__c> oldVoucherMap){
        Integer voucherFloor = 25;
        Integer voucherCeiling = 100;
        Integer customVoucherFloor = voucherFloor;
        Integer customVoucherCeiling = voucherCeiling;

        if (PHSS_TriggerSettings__c.getOrgDefaults().VoucherTriggerOnlineHighWatermark__c != null) {
            customVoucherCeiling = (Integer)PHSS_TriggerSettings__c.getOrgDefaults().VoucherTriggerOnlineHighWatermark__c;
        }
        if (PHSS_TriggerSettings__c.getOrgDefaults().VoucherTriggerOnlineLowWatermark__c != null) {
            customVoucherFloor = (Integer)PHSS_TriggerSettings__c.getOrgDefaults().VoucherTriggerOnlineLowWatermark__c;
        }
        if (customVoucherCeiling > customVoucherFloor) voucherCeiling = customVoucherCeiling;
        if (customVoucherFloor < customVoucherCeiling) voucherFloor = customVoucherFloor;
        
        Set<id> onlineClasses = new Set<id>();
        Map<Id, Id> classLearningPlan = new Map<Id,Id>();
        Map<Id, Integer> classIssuedVouchers = new Map<Id, Integer>();
        List<Voucher__c> addVouchers = new List<Voucher__c>();
        
        //find out the vouchers which have a status change away from 'Issued'
        for(Voucher__c vcr : newVouchers){
            if (oldVouchers != null && !oldVouchers.isEmpty()) {
                //check the status in old map and new map to identify the change in voucher status
                if (oldVoucherMap.get(vcr.id).status__c == 'Issued' &&
                        newVoucherMap.get(vcr.id).status__c != oldVoucherMap.get(vcr.id).status__c) {
                    // Vouchers for Online Classes will have Online_Class__c lookup populated (ILT Class vouchers will not)
                    if (vcr.Online_Class__c != null) {
                        classLearningPlan.put(vcr.Online_Class__c, vcr.Learning_Plan__c);
                        onlineClasses.add(vcr.Online_Class__c);
                        classIssuedVouchers.put(vcr.Online_Class__c, 0); // Covers case in which no Issued vouchers remain
                    }
                }
            } else {
                // this handles insert of new voucher - insure number of Issued vouchers is at the high water mark
                if (vcr.Online_Class__c != null) {
                    classLearningPlan.put(vcr.Online_Class__c, vcr.Learning_Plan__c);
                    onlineClasses.add(vcr.Online_Class__c);
                    classIssuedVouchers.put(vcr.Online_Class__c, 0); // Covers case in which no Issued vouchers remain
                }
            }
        }
        System.debug('classLearningPlan='+classLearningPlan);
        System.debug('onlineClasses='+onlineClasses);
        
        if (!onlineClasses.isEmpty()) {
            // Determine the total number of available (Issued) vouchers for each online class impacted by voucher status changes
            List<AggregateResult> issuedVoucherCounts = [
                    Select Online_Class__c, Count(Id) vCount
                    From Voucher__c
                    Where Online_Class__c In :onlineClasses And Status__c = 'Issued'
                    Group by Online_Class__c
            ];
            System.debug('issuedVoucherCounts=' + issuedVoucherCounts);

            For (AggregateResult theCount : issuedVoucherCounts) {
                Integer classIssuedVoucherCount = (Integer) theCount.get('vCount');
                Id theOnlineClass = (Id) theCount.get('Online_Class__c');
                System.debug('classIssuedVoucherCount=' + classIssuedVoucherCount);

                classIssuedVouchers.put(theOnlineClass, classIssuedVoucherCount);
            }

            For (Id theOnlineClass : classIssuedVouchers.keySet()) {
                Integer classIssuedVoucherCount = classIssuedVouchers.get(theOnlineClass);
                // Determine if number of Issued vouchers for each online class is below lower limit
                if (classIssuedVoucherCount < voucherFloor) {
                    Id theLearningPlan = classLearningPlan.get(theOnlineClass);
                    // Generate additional vouchers to bring the total Issued vouchers up to the defined upper limit
                    addVouchers.addAll(createVouchers(theOnlineClass, theLearningPlan, voucherCeiling - classIssuedVoucherCount));
                }
            }

            if (!addVouchers.isEmpty()) {
                insert addVouchers;
            }
        }
    }
	
	private List<Voucher__c> createVouchers(Id onlineClassId, Id learningPlanId, Integer numberOfVouchers) {
		List<Voucher__c> newVouchers = new List<Voucher__c>();
		
		if (numberOfVouchers > 0) {
			for (Integer n=numberOfVouchers; n>0; n--) {
				Voucher__c theNewVoucher = new Voucher__c();
				theNewVoucher.Status__c = 'Issued';
				theNewVoucher.Online_Class__c = onlineClassId;
				theNewVoucher.Learning_Plan__c = learningPlanId;
				newVouchers.add(theNewVoucher);
			}
		}
		System.debug('newVouchers='+newVouchers);
		return newVouchers;
	}

    /************************************************************************************************************************************
    ** Author: Salesforce Services
    ** Description: This method to block the issued vouchers for load balancing and vice versa
    ************************************************************************************************************************************/
    public void BlockIssuedVouchersAndIssueBlockedVouchers(List<Voucher__c> newVouchers, List<Voucher__c> oldVouchers, Map<Id,Voucher__c> newVoucherMap , Map<ID,Voucher__c> oldVoucherMap){
        Set<Id> setUpdatedVoucherClassIds = new Set<Id>();
        Set<Id> setUpdatedParentJobIds = new Set<Id>();
        Set<Id> setNewVouchers = new Set<Id>();
        Set<Id> setStackClosedParentJobIds = new Set<Id>();

        // DE2407 - Exclude vouchers for classes that have been cancelled (SJC - 01-20-2020)
        // DE2564 - Exclude vouchers for classes that have been closed (SJC - 02-25-2020)
        // Note: ILT Class record is updated first for close class, prior to voucher status change (this is assumed in this design)

        // Determine which vouchers have a change in status and are assigned to active ILT Classes

        // DE2564 - Enhancement - Insure that load balancing is disabled for ALL classes in a stack in which ANY class is CLOSED

        for (Voucher__c vcr : newVouchers) {
            // Check the status in old map and new map to identify a change in voucher status
            // Vouchers for ILT Classes will have ILT_Class__c lookup populated (online vouchers will not)
            // ==> Vouchers for Stacked ILT Classes are the only ones that are load balanced (non-stacked and online are excluded)
            if ((vcr.Status__c != oldVoucherMap.get(vcr.Id).Status__c)
                && (vcr.ILT_Class__c != null)) {
                setNewVouchers.add(vcr.Id);
            }
        }

        for (Voucher__c theVoucher : [SELECT Id, ILT_Class__c, ILT_Class__r.Skedulo_Job_Status__c,
                ILT_Class__r.Is_Master_Class__c, ILT_Class__r.Is_Stacked_Class__c, ILT_Class__r.Skedulo_Parent_Job__c
            FROM Voucher__c
            WHERE Id IN :setNewVouchers
            AND ILT_Class__r.Is_Stacked_Class__c = TRUE
            AND ILT_Class__r.Skedulo_Job_Status__c != 'Cancelled'
        ]) {

            setUpdatedVoucherClassIds.add(theVoucher.ILT_Class__c);
            setUpdatedParentJobIds.add(theVoucher.ILT_Class__r.Skedulo_Parent_Job__c);
        }

        for (redwing__ILT_Class__c iltClass : [SELECT Id, Class_Closed_Date__c, Skedulo_Parent_Job__c
            FROM redwing__ILT_Class__c
            WHERE Skedulo_Parent_Job__c IN :setUpdatedParentJobIds
        ]) {
            if (iltClass.Class_Closed_Date__c != null) {
                setStackClosedParentJobIds.add(iltClass.Skedulo_Parent_Job__c);
            }
        }

        // Continue with the trigger if is any change in voucher status
        if(!setUpdatedVoucherClassIds.isEmpty()){
            List<redwing__ILT_Class__c> lstStackedClasses = new List<redwing__ILT_Class__c>();
            Set<Id> setParentJobIds = new Set<Id>();
            Set<Id> setJobIds = new Set<Id>();
            // Collect the parent job ids for all the stacked classes for which a change in voucher status has been received
            // Note: Apex class SkedJobtoILTClass populates parent Skedulo job id field for the parent job with its own job Id
            // This is assumed and required in the logic below which determines group of related stacked classes which share a common parent job id
            for(redwing__ILT_Class__c iltClass : [SELECT Id,Skedulo_Parent_Job__c,Skedulo_Job_Id__c,Is_Stacked_Class__c
                FROM redwing__ILT_Class__c
                WHERE Id IN: setUpdatedVoucherClassIds
            ]) {
                if (iltClass.Skedulo_Parent_Job__c != null) setParentJobIds.add(iltClass.Skedulo_Parent_Job__c); 
                if (iltClass.Skedulo_Job_Id__c != null) setJobIds.add(iltClass.Skedulo_Job_Id__c);    
            }
            System.debug('++setJobIds='+setJobIds);
            System.debug('++setParentJobIds='+setParentJobIds);
            
            // Obtain set of classes related to every parentid and put them in map
            if(!setParentJobIds.isEmpty()){
                Map<Id,List<redwing__ILT_Class__c>> mapStackedParentJobIdToListClasses = new Map<Id,List<redwing__ILT_Class__c>>();
                Map<Id,Integer> mapStackedParentWithMinMaxNoOfStudents = new Map<Id,Integer>();
                for(redwing__ILT_Class__c iltClass : [SELECT Id,Skedulo_Parent_Job__c,Skedulo_Job_Id__c,Is_Stacked_Class__c,redwing__Max_Seats__c,
                        Cloud_Craze_Product__c,Cloud_Craze_Product__r.Course_Catalog__c,Cloud_Craze_Product__r.Course_Catalog__r.Number_of_Students__c
                    FROM redwing__ILT_Class__c
                    WHERE Skedulo_Parent_Job__c IN: setParentJobIds]){
                    lstStackedClasses.add(iltClass);
                    if(mapStackedParentJobIdToListClasses.containsKey(iltClass.Skedulo_Parent_Job__c)){
                        List<redwing__ILT_Class__c> existinglstcls = mapStackedParentJobIdToListClasses.get(iltClass.Skedulo_Parent_Job__c);
                        existinglstcls.add(iltClass);    
                        mapStackedParentJobIdToListClasses.put(iltClass.Skedulo_Parent_Job__c,existinglstcls);
                    } else {
                        List<redwing__ILT_Class__c> lstcls = new List<redwing__ILT_Class__c>();
                        lstcls.add(iltClass);
                        mapStackedParentJobIdToListClasses.put(iltClass.Skedulo_Parent_Job__c,lstcls);
                    }
                } 
                System.debug('mapStackedParentJobIdToListClasses='+mapStackedParentJobIdToListClasses);
                
                Map<Id,Integer> mapStackedParentIdWithNoOfClaimedVouchers = new Map<Id,Integer>();
                Map<Id,Integer> mapJobWithNoOfClaimedVouchers = new Map<Id,Integer>();
                Map<Id,Integer> mapStackedParentIdWithMinNoOfStudents = new Map<Id,Integer>();

                String claimedVoucherStatusCodes = '';
                List<PHSS_Custom_Settings__c> allSettings = PHSS_Custom_Settings__c.getAll().values();

                if(!allSettings.isEmpty() && allSettings.get(0).Claimed_Voucher_Status_Codes__c != null
                        && String.isNotBlank(allSettings.get(0).Claimed_Voucher_Status_Codes__c)) {
                    claimedVoucherStatusCodes = allSettings.get(0).Claimed_Voucher_Status_Codes__c;
                }

                List<String> ClaimedStatuses = claimedVoucherStatusCodes.split(';');
                //List<String> ClaimedStatuses = system.Label.ClaimedVoucherTypes.split(';');
                
                // Count the number of claimed vouchers for every stacked job
                List<Voucher__c> lstvchrs = [SELECT Id, Status__c, User__c, ILT_Class__r.Skedulo_Job_Id__c, ILT_Class__r.Skedulo_Parent_Job__c
                    FROM Voucher__c
                    WHERE ILT_Class__r.Skedulo_Parent_Job__c IN :setParentJobIds];
                System.debug('+++lstvchrs='+lstvchrs);

                // Initialize number of claimed vouchers to zero
                for(Id theParentJobId : setParentJobIds){
                    mapStackedParentIdWithNoOfClaimedVouchers.put(theParentJobId, 0);
                }
                for(Voucher__c ar : lstvchrs){
                    if(ClaimedStatuses.contains(ar.Status__c)){
                    	if (ar.ILT_Class__r.Skedulo_Parent_Job__c != null) {
	                        if(mapStackedParentIdWithNoOfClaimedVouchers.containsKey(ar.ILT_Class__r.Skedulo_Parent_Job__c)){
	                           Integer i = mapStackedParentIdWithNoOfClaimedVouchers.get(ar.ILT_Class__r.Skedulo_Parent_Job__c)+1;
	                           mapStackedParentIdWithNoOfClaimedVouchers.put(ar.ILT_Class__r.Skedulo_Parent_Job__c,i);
	                        } else{
	                           mapStackedParentIdWithNoOfClaimedVouchers.put(ar.ILT_Class__r.Skedulo_Parent_Job__c,1); 
	                        }  
                    	}
                    }   
                }
                
                // Determine minimum maximum no of students for the stacked classes for every parent job id
                for(Id theParentJobId : setParentJobIds){
                    for(redwing__ILT_Class__c iltClass : mapStackedParentJobIdToListClasses.get(theParentJobId)){
                    	if(iltClass.Skedulo_Parent_Job__c != null) {
	                        if(mapStackedParentIdWithMinNoOfStudents.containsKey(iltClass.Skedulo_Parent_Job__c)){
	                            if(mapStackedParentIdWithMinNoOfStudents.get(iltClass.Skedulo_Parent_Job__c) > iltClass.redwing__Max_Seats__c){  
	                                mapStackedParentIdWithMinNoOfStudents.put(iltClass.Skedulo_Parent_Job__c,Integer.valueOf(iltClass.redwing__Max_Seats__c));
	                            }
	                        }  else{
	                        	// Note: iltClass.redwing__Max_Seats__c *should* contain value of Cloud_Craze_Product__r.Course_Catalog__r.Number_of_Students__c when record is created
	                            mapStackedParentIdWithMinNoOfStudents.put(iltClass.Skedulo_Parent_Job__c,Integer.valueOf(iltClass.redwing__Max_Seats__c));
	                        }  
                    	}
                    }
                }           
                
                set<id> OversoldParentJobIds = new set<id>();
                set<id> UndersoldParentJobIds = new set<id>();               
                map<id, Integer> numberOfRemainingSeatsToSell = new map<id, Integer>();
                    
                // Calculate number of open seats per stacked class remaining to sell                             
                // Determine whether minimum no of maximum students is greater than number of claimed vouchers
                // Note: Insure that each class in stack has no more open vouchers than the current number of open seats 
                for(id theParentJobId : setParentJobIds){
                	Integer maxSizeOfClass = 0;
                	Integer numberOfSeatsSold = 0;
                	numberOfRemainingSeatsToSell.put(theParentJobId, 0);
                	
                	if (mapStackedParentIdWithMinNoOfStudents.containsKey(theParentJobId) &&
                		mapStackedParentIdWithNoOfClaimedVouchers.containsKey(theParentJobId)) { 
                			               	
	                	maxSizeOfClass = mapStackedParentIdWithMinNoOfStudents.get(theParentJobId);
	                	numberOfSeatsSold = mapStackedParentIdWithNoOfClaimedVouchers.get(theParentJobId);
	                	
	                	Integer numberOfSeatsOpen = maxSizeOfClass - numberOfSeatsSold;
	                	numberOfRemainingSeatsToSell.put(theParentJobId, Math.max(numberOfSeatsOpen, 0));
	                	
	                    if(maxSizeOfClass <= numberOfSeatsSold){
	 						// Class is oversold - block all remaining vouchers for all classes in stack                     	
	                        OversoldParentJobIds.add(theParentJobId); 
	                    } else {
	                    	// Class is undersold (open) - insure that the number of vouchers open (Issued) for each class in stack
	                    	// does not exceed number of seats left to sell
	                        UndersoldParentJobIds.add(theParentJobId);
	                    }
                	}
                }
                system.debug('Minimum Students = '+ mapStackedParentIdWithMinNoOfStudents );
                system.debug('Minimum Vouchers = '+ mapStackedParentIdWithNoOfClaimedVouchers );
                
                // Update ILT Class records for each member of stack with number of open seats in the stack
                list<redwing__ILT_Class__c> lstClassesToUpdate = new list<redwing__ILT_Class__c>();
                map<id, integer> lstClassOpenSeats = new map<id, integer>();
                
                for (redwing__ILT_Class__c theClass : lstStackedClasses) {
                	if (theClass.Skedulo_Parent_Job__c != null) {
	                	redwing__ILT_Class__c theUpdatedClass = new redwing__ILT_Class__c();
	                	theUpdatedClass.Id = theClass.Id;                		              		
                		theUpdatedClass.Available_Seats__c = numberOfRemainingSeatsToSell.get(theClass.Skedulo_Parent_Job__c);
                		lstClassesToUpdate.add(theUpdatedClass);  
                		
                		lstClassOpenSeats.put(theClass.Id, numberOfRemainingSeatsToSell.get(theClass.Skedulo_Parent_Job__c));                 		              		
                	}
                }
                
                List<Voucher__c> lstVouchersToUpdate = new List<Voucher__c>();

                for(Voucher__c vcr : lstvchrs){
                    // DE2564 - Enhancement - Insure that load balancing is disabled for ALL classes in a stack in which ANY class is CLOSED
                    // In this case we update class inventory (above) but do NOT load balance vouchers (modify their status)
                    if (setStackClosedParentJobIds.contains(vcr.ILT_Class__r.Skedulo_Parent_Job__c)) continue;

                    Boolean updateVoucher = false;
                    Voucher__c theUpdatedVoucher = new Voucher__c();

                    // Hot Fix - SJC - Dynamically change voucher status from Void to Blocked for regression purposes for load balancing
                    // Vouchers should be in Blocked not Void status if not assigned to a student

                    if (vcr.Status__c == 'Void' && String.isBlank(vcr.User__c)) {
                        vcr.Status__c = 'Blocked';
                        theUpdatedVoucher.Id = vcr.Id;
                        theUpdatedVoucher.Status__c = 'Blocked';
                        updateVoucher = true;
                    }

                    if ((vcr.Status__c =='Issued' || vcr.Status__c =='Blocked') && String.isBlank(vcr.User__c)) {
                    //if ((vcr.Status__c =='Issued' || vcr.Status__c =='Blocked' || vcr.Status__c == 'Void') && String.isBlank(vcr.User__c)) {
                    	if (vcr.ILT_Class__c != null && vcr.ILT_Class__r.Skedulo_Parent_Job__c != null) {
	                		// Block the remaining vouchers (Issued) for each oversold class in stack                     	
	                        if(OversoldParentJobIds.contains(vcr.ILT_Class__r.Skedulo_Parent_Job__c) && vcr.status__c =='Issued'){
			                	//voucher__c theUpdatedVoucher = new voucher__c();
			                	theUpdatedVoucher.Id = vcr.Id;	                        	
	                            theUpdatedVoucher.status__c = 'Blocked';
                                //theUpdatedVoucher.status__c = 'Void';
                                updateVoucher = true;
	                            //lstVouchersToUpdate.add(theUpdatedVoucher);
	                        }    
	                        // Open up vouchers to the max remaining number of seats to sell, block all others
	                        if(UndersoldParentJobIds.contains(vcr.ILT_Class__r.Skedulo_Parent_Job__c)) {  
	                        	// Get number of seats remaining to sell for this class (this will be decremented destructively)
	                        	Integer classOpenSeats = lstClassOpenSeats.get(vcr.ILT_Class__c);	 
                    	
	                        	// If at least one, and this voucher is blocked, then reset to issued (else leave in blocked status)
	                        	// If none, and this voucher is open (Issued), then reset to blocked (else leave in issued status)
                                if (classOpenSeats > 0 && (vcr.status__c =='Blocked')){
	                        	//if (classOpenSeats > 0 && (vcr.status__c =='Blocked' || vcr.status__c == 'Void')){
				                	//voucher__c theUpdatedVoucher = new voucher__c();
				                	theUpdatedVoucher.Id = vcr.Id;	                        	
		                            theUpdatedVoucher.status__c = 'Issued';
                                    updateVoucher = true;
		                            //lstVouchersToUpdate.add(theUpdatedVoucher);
	                        	} else if (classOpenSeats <= 0 && vcr.status__c =='Issued'){
				                	//voucher__c theUpdatedVoucher = new voucher__c();
				                	theUpdatedVoucher.Id = vcr.Id;	 	                        		
		                            theUpdatedVoucher.status__c = 'Blocked';
		                            //theUpdatedVoucher.status__c = 'Void';
                                    updateVoucher = true;
		                            //lstVouchersToUpdate.add(theUpdatedVoucher);
	                        	}
		                        if (classOpenSeats > 0) lstClassOpenSeats.put(vcr.ILT_Class__c, --classOpenSeats);	                        	
	                        }   
                    	}
                    }
                    if (updateVoucher) lstVouchersToUpdate.add(theUpdatedVoucher);
                }
                //set the flag to true so that it will not call recursively
                PHSS_VoucherTriggerHandler.setAlreadyUpdatedVouchers();
                
                try {
	                if(!lstVouchersToUpdate.isEmpty()){
	                    update lstVouchersToUpdate; 
	                }
	                if(!lstClassesToUpdate.isEmpty()) {
	                	update lstClassesToUpdate;
	                }
                } catch (Exception e) {
                	
                }
            }
        }
    }

    /************************************************************************************************************************************
    ** Author: Salesforce Services
    ** Description: This method sets the max size and available seats for classes after vouchers are updated
    ************************************************************************************************************************************/
    public void adjustAvailableSeats(list<Voucher__c> newVouchers, List<Voucher__c> oldVouchers, Map<ID,Voucher__c> newVoucherMap , Map<ID,Voucher__c> oldVoucherMap) {
        system.debug('Adjusting available seats');
        set<Id> ILT_classes = new set<id>();
        set<id> setUpdatedVoucherClassIds = new set<id>();

        // DE2149 - We need to query ILT Class object in order to inspect value of Is_Stacked_Class__c
        for (Voucher__c vcr : newVouchers) {
            if (newVoucherMap.get(vcr.id).status__c != oldVoucherMap.get(vcr.id).status__c) {
                if (vcr.ILT_Class__c != null) setUpdatedVoucherClassIds.add(vcr.ILT_Class__c);
            }
        }
        // Filter out stacked classes (inventory for these is taken care of in BlockIssuedVouchersAndIssueBlockedVouchers)
        for (redwing__ILT_Class__c theClass : [SELECT Id, Is_Stacked_Class__c
            FROM redwing__ILT_Class__c
            WHERE Id IN :setUpdatedVoucherClassIds]) {
            if (!theClass.Is_Stacked_Class__c) {
                ILT_classes.add(theClass.Id);
            }
        }
        system.debug('Set of changed classes: ' + ILT_classes);

        if (!ILT_classes.isEmpty()) {
            Map<Id,Integer> mapMaxClassSize = new map<Id,Integer>();
            Map<Id,Integer> mapSeatsClaimed = new Map<Id,Integer>();
            List<redwing__ILT_Class__c> updateClasses = new List<redwing__ILT_Class__c>();

            // DE1755 - No need to calculate the max seats in a class; this is a static value set at class level
            List<Voucher__c> voucherList = [SELECT ILT_Class__c, ILT_Class__r.redwing__Max_Seats__c
                FROM Voucher__c
                WHERE ILT_Class__c IN: ILT_classes];
            //List<AggregateResult> iltAggregateResults = [select ILT_Class__c, count(Id) maxSize from Voucher__c where (Status__c = 'Claimed' or Status__c = 'Issued') and ILT_Class__c IN: ILT_classes group by ILT_Class__c];

            for (Voucher__c theVoucher : voucherList) {
            //for (AggregateResult result : iltAggregateResults) {
                mapMaxClassSize.put(theVoucher.ILT_Class__c, (Integer)theVoucher.ILT_Class__r.redwing__Max_Seats__c);
                //mapMaxClassSize.put((Id) result.get('ILT_Class__c'), (Integer) result.get('maxSize'));

                // DE2019 - Initialize the claimed seats in each class to zero
                // This insures that each class will have a seats claimed value coming out of the next query
                mapSeatsClaimed.put(theVoucher.ILT_Class__c, 0);
                System.debug('Max size for '+ theVoucher.ILT_Class__c + ': ' + (Integer) theVoucher.ILT_Class__r.redwing__Max_Seats__c);
            }

            // DE2019 - Insure that claimed status values are those that are defined at system level

            String claimedVoucherStatusCodes = '';
            List<PHSS_Custom_Settings__c> allSettings = PHSS_Custom_Settings__c.getAll().values();

            if(!allSettings.isEmpty() && allSettings.get(0).Claimed_Voucher_Status_Codes__c != null
                    && String.isNotBlank(allSettings.get(0).Claimed_Voucher_Status_Codes__c)) {
                claimedVoucherStatusCodes = allSettings.get(0).Claimed_Voucher_Status_Codes__c;
            }

            List<String> ClaimedStatuses = claimedVoucherStatusCodes.split(';');
            //List<String> ClaimedStatuses = System.label.ClaimedVoucherTypes.split(';');

            List<AggregateResult> iltAggregateResults = [SELECT ILT_Class__c, COUNT(Id) claimedSeats
                FROM Voucher__c
                WHERE Status__c IN :ClaimedStatuses
                //WHERE (Status__c = 'Claimed' or Status__c = 'Reserved' OR Status__c = 'Temp Hold')
                AND ILT_Class__c IN: ILT_classes GROUP BY ILT_Class__c];

            for (AggregateResult result : iltAggregateResults) {
                mapSeatsClaimed.put((Id) result.get('ILT_Class__c'), (Integer) result.get('claimedSeats'));
                System.debug('claimedSeats for '+ (Id) result.get('ILT_Class__c') + ': ' + (Integer) result.get('claimedSeats'));
            }

            for (Id id : ILT_classes) {
                Integer maxSize = mapMaxClassSize.get(id);
                if (maxSize != null && mapSeatsClaimed.get(id) != null) {
                    redwing__ILT_Class__c classUpdate = new redwing__ILT_Class__c();
                    classUpdate.Id = id;
                    // DE1755 - No need to update max seats; this is a static value set at class level
                    //classUpdate.redwing__Max_Seats__c = maxSize;
                    classUpdate.Available_Seats__c = Math.max((maxSize - mapSeatsClaimed.get(id)), 0);
                    updateClasses.add(classUpdate);
                }
            }
            if(!updateClasses.isEmpty()){
                update updateClasses;
            }
        }
    }
}