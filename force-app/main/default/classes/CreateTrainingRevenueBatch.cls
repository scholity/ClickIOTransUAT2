global class CreateTrainingRevenueBatch implements Database.Batchable<sObject>
{
    @testVisible
    private static final String FULFILLMENT_ITEM_STATUS_INVOICED = 'Invoiced';
	
    @testVisible
    private static map<Integer, String> fiscalMothAbbreviationMap = new Map<Integer, String>
    {
        1 => 'JAN', 2 => 'FEB', 3 => 'MAR', 4 => 'APR',
        5 => 'MAY', 6 => 'JUN', 7 => 'JUL', 8 => 'AUG',
        9 => 'SEP', 10=> 'OCT', 11=> 'NOV', 12=> 'DEC'
    };
        
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        //SELECT Id FROM Fulfillment_Item__c WHERE Status__c = 'Invoiced'
        
        String query = 'SELECT 	Id,' 											+
                                'Order__r.ccrz__Account__c,' 					+
                                'Fulfillment__r.Channel_Formula__c,' 			+
                                'Order__r.ccrz__Storefront__c,' 				+
                                'Transaction_Date__c,' 							+
                                'Fulfillment__r.FOCIS_Category__c,' 			+
                                'CC_Product__r.ccrz__SKU__c,' 					+
                                'Opportunity_Profile__c,' 						+
                                'CC_Product__r.Product_3__c,' 					+
                                'Order__r.ccrz__Account__r.SABA_LMS_Code__c,' 	+
                                'Order__r.ccrz__Account__r.Name,' 				+
                                'Order__r.ccrz__Account__r.SABA_Org_Type__c,' 	+
                                'Quantity__c,' 									+
                                'State_Formula__c,' 							+
                                'CC_Product__r.Product_2__c,' 					+
                                'Fulfillment_Item_Total__c,' 					+
                                'Opportunity_Owner_Email__c,' 					+
                                'Zip_Formula__c '								+
            			   'FROM Fulfillment_Item__c '							+
            			  'WHERE Status__c = \'Invoiced\'';
        
        system.debug(query);
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Fulfillment_Item__c> scope)
    {
        system.debug('***scope***'+scope);
        
        List<Channel_Compensation__c> trainingRevenueRecordsToInsert = new List<Channel_Compensation__c>();
        List<Fulfillment_Item__c>	fulfillmentItemsToUpdate		 = new List<Fulfillment_Item__c>();
        
        for(Fulfillment_Item__c fi : scope)
        {
            trainingRevenueRecordsToInsert.add(
                new Channel_Compensation__c(
                    Account__c 				= fi.Order__r.ccrz__Account__c,
                    //BATCH_Id__c 			= fi.Fulfillment_Date__c,
                    BATCH_Id__c 			= date.today(),
                    Channel__c 				= (fi.Fulfillment__c != null ? fi.Fulfillment__r.Channel_Formula__c : null),
                    Data_Source__c 			= fi.Order__r.ccrz__Storefront__c,
                    End_Date__c 			= Date.valueOf(fi.Transaction_Date__c),
                    FOCIS_Category__c 		= (fi.Fulfillment__c != null ? fi.Fulfillment__r.FOCIS_Category__c : null),
                    FOCIS_Subject_Area__c 	= fi.CC_Product__r.ccrz__SKU__c,
                    //Fiscal_Month_Abbr__c 	= fiscalMothAbbreviationMap.get(fi.Fulfillment_Date__c.month()),
                    Fiscal_Month_Abbr__c 	= fiscalMothAbbreviationMap.get(date.today().month()),
                    Focis_Location__c 		= fi.Opportunity_Profile__c,
                    Focis_Program__c 		= fi.CC_Product__r.Product_3__c,
                    Fulfillment_Item__c		= fi.Id,
                    Org_Id__c 				= (String.isNotBlank(fi.Order__r.ccrz__Account__r.SABA_LMS_Code__c) ? fi.Order__r.ccrz__Account__r.SABA_LMS_Code__c : null),
                    Org_Name__c 			= fi.Order__r.ccrz__Account__r.Name,
                    Org_Type__c 			= fi.Order__r.ccrz__Account__r.SABA_Org_Type__c,
                    Registration_Count__c 	= fi.Quantity__c,
                    State__c 				= fi.State_Formula__c,
                    SubPG__c 				= fi.CC_Product__r.Product_2__c,
                    Transaction_Amt__c 		= fi.Fulfillment_Item_Total__c,
                    User_Field__c 			= fi.Opportunity_Owner_Email__c,
                    Zip_Code__c 			= fi.Zip_Formula__c
                )
            );
            
            fi.Status__c 					= 'Complete';
            
            fulfillmentItemsToUpdate.add(fi);
        }
        
        insert(trainingRevenueRecordsToInsert);
        update(fulfillmentItemsToUpdate);
    }
    
    global void finish(Database.BatchableContext bc)
    {
        //Add email logic to sent email on complition
    }    
}