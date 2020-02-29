public class TransactionPaymentTriggerHelper
{
    public static void OnAfterInsert(List<ccrz__E_TransactionPayment__c> tpRecords)
    {
        system.debug('***tpRecords***'+tpRecords);
        
        List<Account> accountsToUpdate    	  = new List<Account>();
        List<SDOC__SDJob__c> jobList 	  	  = new List<SDOC__SDJob__c> ();
        List<Id> ccOrderIdsList  		  	  = new List<Id> ();
        List<Fulfillment_Item__c> fiList  	  = new List<Fulfillment_Item__c>();
        List<Fulfillment_Item__c> fiToUpdate  = new List<Fulfillment_Item__c>();
        
        
        Map<Id,Fulfillment__c> orderToFulflmntMap			 = new Map<Id,Fulfillment__c>();
        Map<Id,Id> tpToAccountMap 	 					     = new Map<Id,Id>();
        Map<Id,List<ccrz__E_OrderItem__c>> tpToOrderItemsMap = new Map<Id,List<ccrz__E_OrderItem__c>>();
            
        for(ccrz__E_TransactionPayment__c tp : tpRecords)
        {
            tpToAccountMap.put(tp.Id, tp.ccrz__Account__c);
            ccOrderIdsList.add(tp.ccrz__CCOrder__c);
        }
        
        List<ccrz__E_TransactionPayment__c>  tpList = [SELECT Id,
                                                       		  B2B_Transaction_Reference__c,
                                                       		  ccrz__Amount__c,
                                                              ccrz__CCOrder__c,
                                                              ccrz__CCOrder__r.ccrz__Storefront__c,
                                                       		  ccrz__CCOrder__r.Supplemental_Information__c,
                                                       		  ccrz__AccountType__c,
                                                       		  ccrz__PaymentType__c,
                                                       		  ccrz__CCOrder__r.NSSCCConnector_SFCC_Order_Number__c,
                                                       		  ccrz__CCOrder__r.NSSCCConnector_from_SFCC__c, 
                                                       		  ccrz__TransactionType__c,
                                                       		  ccrz__Account__r.Open_Order_Amount__c
                                                        FROM  ccrz__E_TransactionPayment__c
                                                        WHERE Id IN: tpToAccountMap.keySet()];
        
        system.debug('***tpList***'+tpList);
        
        if(ccOrderIdsList.size() > 0)
        {
            List<ccrz__E_Order__c> orderWithOrderItemList = [SELECT Id,
                                                             		(SELECT Id,
                                                                     		ccrz__Product__c,
                                                                     		ILT_Class__c,
                                                                     		ccrz__Quantity__c,
                                                                     		Supplemental_Information__c
                                                                       FROM ccrz__E_OrderItems__r)
                                                                FROM ccrz__E_Order__c
                                                               WHERE Id IN :ccOrderIdsList];
            
            for(ccrz__E_Order__c o : orderWithOrderItemList)
            {
                if(o.ccrz__E_OrderItems__r.size() > 0)
                {
                    tpToOrderItemsMap.put(O.Id,o.ccrz__E_OrderItems__r);
                }
            }
        }
        
        List<Fulfillment_Item__c> fulfillmentItemsList = [SELECT Id,
                                                          		 Status__c
                                                            FROM Fulfillment_Item__c
                                                           WHERE Fulfillment__r.CC_Transaction_Payment__c IN : tpList];
            
        for(ccrz__E_TransactionPayment__c tPayment : tpList)
        {
            //B2C Order Fulfilment
            if(tPayment.ccrz__TransactionType__c == 'CAPTURE' && tPayment.ccrz__CCOrder__r.NSSCCConnector_SFCC_Order_Number__c != null
              && tPayment.ccrz__CCOrder__c != null && tpToOrderItemsMap.containsKey(tPayment.ccrz__CCOrder__c))
            {     
                for(Id orderId : tpToOrderItemsMap.keyset())
                {
                    Fulfillment__c flFlment 			 = new Fulfillment__c();
                    
                    flFlment.Order__c 					 = tPayment.ccrz__CCOrder__c;
                    flFlment.CC_Transaction_Payment__c   = tPayment.Id;
                    flFlment.Fulfillment_Date__c		 = system.Date.today();
                    flFlment.Status__c					 = 'Closed';
                    flFlment.Supplemental_Information__c = tPayment.ccrz__CCOrder__r.Supplemental_Information__c;
                    flFlment.Type__c					 = 'Receipt';
                    
                    orderToFulflmntMap.put(tPayment.ccrz__CCOrder__c,flFlment);
                    
                    system.debug('orderToFulflmntMap***'+orderToFulflmntMap);
                }
            }
            
            if(tPayment.ccrz__TransactionType__c == 'CAPTURE' && tPayment.ccrz__CCOrder__r.NSSCCConnector_from_SFCC__c == false && tPayment.ccrz__CCOrder__r.ccrz__Storefront__c != 'CPS')
            {
                system.debug('Send an email');
                //Update Credit Card To Complete Add Update Fulfillment Item to Complete FLOW LOGIC
                
                for(Fulfillment_Item__c fItem : fulfillmentItemsList)
                {
                    fItem.Status__c = 'Invoiced';   // Changed to invoiced
                    
                    fiToUpdate.add(fItem);
                }
                
                //Add logic for send an email
                SDOC__SDJob__c job = new SDOC__SDJob__c();

                job.SDOC__Start__c      = true;
                job.SDOC__Oid__c        = tPayment.Id;
                job.SDOC__ObjApiName__c = 'ccrz__E_TransactionPayment__c';
                job.SDOC__SendEmail__c  = '1';
                job.SDOC__Doclist__c    = System.Label.SDocsDoclistIdForTP;
                job.SDOC__RunAs__c      = System.Label.SDocsRunAsUserName;

                jobList.add(job);
            }

            //Update Open order amount
            if(tPayment.ccrz__AccountType__c == 'po')
            {
                system.debug('***tpToAccountMap***'+tpToAccountMap);
                
                if(tpToAccountMap.containsKey(tPayment.Id))
                {
                    system.debug('***tpToAccountMap.get(tp.Id)***'+tpToAccountMap.get(tPayment.Id));
                    
                    Account acc = new Account();
                    
                    acc.Id 					 = tpToAccountMap.get(tPayment.Id);
                    acc.Open_Order_Amount__c = tPayment.ccrz__Account__r.Open_Order_Amount__c + tPayment.ccrz__Amount__c;
                    
                    accountsToUpdate.add(acc);
                }
            }
        }
        
        if(orderToFulflmntMap != null && !orderToFulflmntMap.isEmpty())
        {
            system.debug('***orderToFulflmntMap***'+orderToFulflmntMap);
            
            insert orderToFulflmntMap.values();
            
            for(Id oId : tpToOrderItemsMap.keyset())
            {   
                for(ccrz__E_OrderItem__c  oi : tpToOrderItemsMap.get(oId))
                {
                    Fulfillment_Item__c  fi 		= new Fulfillment_Item__c ();
                    
                    fi.Fulfillment__c 				= orderToFulflmntMap.get(oId).Id;
                    fi.Order__c 					= oId;
                    fi.Order_Item__c				= oi.Id;
                    fi.CC_Product__c  				= oi.ccrz__Product__c;
                    fi.Status__c					= 'Invoiced';
                    fi.ILT_Class__c					= oi.ILT_Class__c;
                    fi.Quantity__c					= oi.ccrz__Quantity__c;
                    fi.Transaction_Date__c			= system.Date.today();
                    fi.Supplemental_Information__c	= oi.Supplemental_Information__c;
                    fi.Fulfillment_Date__c			= system.Date.today();
                    
                    fiList.add(fi);
                }
            }
            
            if(fiList.size() > 0)
            {
                insert fiList;
            }
        }
        
        if(jobList.size() > 0)
        {
            insert jobList;
        }
        
        if(accountsToUpdate.size() > 0)
        {
            update accountsToUpdate;
        }
        
        if(fiToUpdate.size() > 0)
        {
            update fiToUpdate;
        }
    }
}