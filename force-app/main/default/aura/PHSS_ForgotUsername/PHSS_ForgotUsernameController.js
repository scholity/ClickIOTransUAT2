({
     showForgotUsername : function (component, event, helper) {
         component.set("v.stepNumber","One")
         
     },
    
     cancel : function(component, event, helper){
         $A.get("e.force:refreshView").fire();
         component.set("v.stepNumber", "Zero");
     },
    
     findUser : function(component, event, helper) {
            component.set("v.searchBool", true);
            var action = component.get("c.fetchUser");
            action.setParams({
                emailAddress : component.get("v.email")
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.userRecord", response.getReturnValue());
                    component.set("v.stepNumber", "Two");
                }
            });
            $A.enqueueAction(action);
     }
})