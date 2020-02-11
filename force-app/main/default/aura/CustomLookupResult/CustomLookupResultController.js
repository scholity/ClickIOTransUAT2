({
   doInit : function(component, event, helper){
      var oRecord = component.get("v.oRecord");
      console.log("@@@oRecord:", oRecord.Name);
      var ObjectAPIName = component.get("v.ObjectAPIName").toLowerCase();
      console.log("@@@ObjectAPIName:", ObjectAPIName);
      var additionalText = "";
      if(ObjectAPIName == "account" && oRecord.BillingAddress){
         additionalText += 
            (oRecord.BillingAddress.street ? oRecord.BillingAddress.street : "") +
            (oRecord.BillingAddress.city ? ", "+oRecord.BillingAddress.city: "") +
            (oRecord.BillingAddress.state ? ", "+oRecord.BillingAddress.state : "") +
            (oRecord.BillingAddress.postalCode ? " "+oRecord.BillingAddress.postalCode : "");
      }
      else{
         additionalText += 
            (oRecord.redwing__Address_1__c ? oRecord.redwing__Address_1__c : "") +
            (oRecord.redwing__Address_2__c ? ", "+oRecord.redwing__Address_2__c : "") +  
            (oRecord.redwing__City__c ? ", "+oRecord.redwing__City__c : "") +
            (oRecord.redwing__State__c ? ", "+oRecord.redwing__State__c : "") +
            (oRecord.redwing__Postal_Code__c ? " "+oRecord.redwing__Postal_Code__c : "");
      }
      console.log("@@@additionalText:", additionalText);
      component.set("v.additionalText", additionalText);
   },

   selectRecord : function(component, event, helper){      
      
      var getSelectRecord = component.get("v.oRecord");

      var compEvent = component.getEvent("oSelectedRecordEvent");
    
         compEvent.setParams({"recordByEvent" : getSelectRecord });

         compEvent.fire();
    },
})