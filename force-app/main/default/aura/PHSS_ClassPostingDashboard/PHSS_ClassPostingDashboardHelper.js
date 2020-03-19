({
	initializeWrapper : function(component, event, helper) {
		var action = component.get("c.initWrapper");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 

                var resp = response.getReturnValue();    
                component.set("v.cpsWrap",resp);
                component.set("v.initialWrap",resp);
                console.log('response..'+JSON.stringify(resp));
                
                var zones = [];
                var zoneResp = resp.timeZoneList;
                for(var key in zoneResp){
                    zones.push({value:zoneResp[key], key:key}); 
                }
                component.set("v.zoneList",zones); 
      
                console.log('map..'+component.get("v.zoneList"));
                
                console.log("accId***"+resp.accId);
                
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.errorMessage",errors[0].message);
                        component.set("v.showError",true);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);	
	},

    initalizeProductQuantityMap : function(component, event, helper) {
        
		var action = component.get("c.initProductQuantityMap");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                var resp = response.getReturnValue();    
                component.set("v.myProductQuantityMap",resp);
                //alert("Initalized ProductQuantityMap");
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.errorMessage",errors[0].message);
                        component.set("v.showError",true);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);        
        
    },
    
    updateProductQuantityMap : function(component, event, helper) {
        //alert("myProductQuantityMap Before "+ JSON.stringify(component.get("v.myProductQuantityMap")) );
       	var action = component.get("c.updateProductQuantityMap");
        action.setParams({ productQuantityMap : component.get("v.myProductQuantityMap"),
                           ccProductId : component.get("v.cpsWrap.ccProductId"),
                           quantity : component.get("v.cpsWrap.quantity") });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                var resp = response.getReturnValue();    
                component.set("v.myProductQuantityMap",resp);
                //alert("updateProductQuantityMap Successful");
                //alert("myProductQuantityMap After "+ JSON.stringify(component.get("v.myProductQuantityMap")) );
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                //alert("updateProductQuantityMap Error");
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.errorMessage",errors[0].message);
                        component.set("v.showError",true);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    validateFields : function(component, event, helper) {
        component.set("v.allValid",true);
        component.set("v.isUrlValid",true);
        component.set("v.courseError",false);
        component.set("v.formatError",false);
        component.set("v.zoneError",false);
        component.set("v.scheduleError",false);
        component.set("v.showError",false);
        component.set("v.errorMessage","");
        
        // Course validation
        
        var courseId 	= component.get("v.selectedCourse").Id;
        component.set("v.cpsWrap.courseId",courseId);
        //component.set("v.cpsWrap.courseName",component.get("v.selectedCourse").Name);
        /*
        alert(component.get("v.CCProductId"));
        if(!component.get("v.cpsWrap.ccProductId")) {
        	component.set("v.courseError",true);
        	component.set("v.allValid",false);  
            console.log('cpsWrap.ccProductId is failed');
        }
        
        
        var action = component.get("c.getLearningPlanId");
        console.log("CCProductId***"+component.get("v.cpsWrap.ccProductId"));
        action.setParams({ccProdId : component.get("v.cpsWrap.ccProductId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                
                var storeResponse = response.getReturnValue();
                var courseId 	= storeResponse.LMS_Learning_Plan__c;
                console.log("storeResponse***>>>"+storeResponse.LMS_Learning_Plan__r.Name);
                component.set("v.cpsWrap.courseId", courseId);
                component.set("v.cpsWrap.courseName",storeResponse.LMS_Learning_Plan__r.Name);
                
                var courseId 	= component.get("v.cpsWrap.courseId");
        		if(courseId == undefined){
                    console.log('courseId failed');
                    component.set("v.courseError",true);
                    component.set("v.allValid",false); 
                }
            }
        });
        $A.enqueueAction(action);
        */
        //alert(component.get("v.cpsWrap.classDuration"));
        //alert(component.get("v.ScheduledTime"));
        // Class Schedule validation
		console.log(component.get("v.cpsWrap.classDuration") +" "+ component.get("v.ScheduledTime") );
        if(component.get("v.ScheduledTime") < component.get("v.cpsWrap.classDuration")){
        	component.set("v.scheduleError",true);
        	component.set("v.allValid",false);
            console.log('ScheduledTime');
        }
        
        
        // Class format validation
        //component.set("v.cpsWrap.classFormat",component.get("v.LPClassroomSetting"));
        console.log("Class Format " + component.get("v.cpsWrap.classFormat"));
		/*
        if(!component.get("v.cpsWrap.classFormat")) {
            component.set("v.formatError",true);
       		component.set("v.allValid",false);
            console.log('classFormat failed');
            //document.getElementById('formatSelect').classList.add('requiredSelect');
        }
        */
        // Time Zone validation
        var tempList = component.get("v.cpsWrap.sessionList");
        tempList.forEach(function(session) {
            
        	session.timeZone = document.getElementById('zoneSelect').value;

            if(session.timeZone) {
            	document.getElementById('zoneSelect').classList.remove('requiredSelect');    
        	}
        	else {
            	component.set("v.zoneError",true);
        		component.set("v.allValid",false);
            	document.getElementById('zoneSelect').classList.add('requiredSelect');
            	console.log('classes..'+document.getElementById('zoneSelect').classList);
        	}

        });    
        component.set("v.cpsWrap.sessionList",tempList);
        
        // Other fields validation
        var allValid = component.find('field').reduce(function (validSoFar, inputCmp) {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        
        if(!allValid) {
        	component.set("v.allValid",allValid);    
        }
        
        if(!component.get("v.allValid")) {
            component.set("v.showError","true");
            component.set("v.errorMessage","Please fill all the mandatory details");
        }
        
        // Registration - URL or Phone validation
        if(component.get("v.allValid") && !component.get("v.cpsWrap").regUrl  && !component.get("v.cpsWrap").regPhone) {
            component.set("v.showError","true");
            var errMsg = "Either \'URL for registration\' or \'Phone for registration\' fields must be filled.";
            component.set("v.errorMessage",errMsg);
            component.set("v.isUrlValid",false);
        } else if(component.get("v.allValid") && component.get("v.cpsWrap").regUrl  && component.get("v.cpsWrap").regPhone) {
            component.set("v.showError","true");
            var errMsg = "You can only have a \'URL for registration\' or \'Phone for registration\' not both.";
            component.set("v.errorMessage",errMsg);
            component.set("v.isUrlValid",false)
        }
        
        component.set("v.cpsWrap.OfferingInformation.selectedAccount",component.get("v.selectedLookUpRecord1"));
        component.set("v.cpsWrap.OfferingInformation.selectedFacility",component.get("v.selectedLookUpRecord5"));
        
    },
    
	formatTime : function(component, event, helper) {
    	// Format Start Time and End Time
		var updatedSessions = [];
		component.get("v.cpsWrap.sessionList").forEach(function(session) {
			console.log(session);
            var startTime = session.startTime;
            var startTimeHrs = startTime.substring(0,2);
            var startTimeAmOrPm;
            console.log('startTimeHrs..'+startTimeHrs);
            console.log('con..'+(startTimeHrs == '00'));
            console.log('parsed..'+parseInt(startTimeHrs));
            
            if(startTimeHrs == '12') {
                startTimeAmOrPm = 'PM';
            }
            else if(startTimeHrs == '00') {
                startTimeHrs = '12';
                startTimeAmOrPm = 'AM';
            }
            else if(parseInt(startTimeHrs) > 12 && parseInt(startTimeHrs) < 24) {
                    startTimeHrs = parseInt(startTimeHrs) - 12; 
                startTimeAmOrPm = 'PM';
            }
            else {
                startTimeAmOrPm = 'AM';
            }
            startTime = startTimeHrs + ':' + startTime.substring(3,5) + ' ' + startTimeAmOrPm;
            console.log('startTime..'+startTime);  
            // component.set("v.formattedStartTime",startTime);
            // session.startTime = startTime;
            session.formattedStartTime = startTime;
            var endTime = session.endTime;
            var endTimeHrs = endTime.substring(0,2);
            var endTimeAmOrPm;
            console.log('endTimeHrs..'+endTimeHrs);
            console.log('con..'+(endTimeHrs == '00'));
            console.log('parsed..'+parseInt(endTimeHrs));
            
            if(endTimeHrs == '12') {
                endTimeAmOrPm = 'PM';
            }
            else if(endTimeHrs == '00') {
                endTimeHrs = '12';
                endTimeAmOrPm = 'AM';
            }
            else if(parseInt(endTimeHrs) > 12 && parseInt(endTimeHrs) < 24) {
                    endTimeHrs = parseInt(endTimeHrs) - 12; 
                endTimeAmOrPm = 'PM';
            }
            else {
                endTimeAmOrPm = 'AM';
            }
            endTime = endTimeHrs + ':' + endTime.substring(3,5) + ' ' + endTimeAmOrPm;
            console.log('endTime..'+endTime); 
            //component.set("v.formattedEndTime",endTime);
            // session.endTime = endTime; 
            session.formattedEndTime = endTime;
	    	updatedSessions.push(session);
        });
		component.set("v.cpsWrap.sessionList", updatedSessions);
    },
    updateClass : function(component, event, helper) {
    	 //alert('here'+JSON.stringify(component.get("v.cpsWrap")));
           //console.log(JSON.stringify(component.get("v.cpsWrap")));
            //alert('Opportunity ID '+offering.oppId+ " CCProductID "+offering.ccProductId);
            //alert('***Offerings.. '+JSON.stringify((offering)));
            if(!component.get("v.cpsWrap.iltClassId")){
                alert('can not find the iltClassId');
                return false;
            }
            //alert(component.get("v.cpsWrap.courseName"));
            console.log('here'+JSON.stringify(component.get("v.cpsWrap")));
            //return false;
            var action = component.get("c.updateClass"); 
            
            //alert(JSON.stringify(component.get("v.cpsWrap")));
            
            action.setParams({ jsonStr : JSON.stringify(component.get("v.cpsWrap")) });
            action.setCallback(this, function(response) {
				
                //alert('inside');
                var state = response.getState();
                
                if (state === "SUCCESS") {
                    console.log('success');
                    document.getElementById("Accspinner").style.display = "none";
                    $A.get("e.force:refreshView").fire();
                    alert('Class updated successfully. Please wait 24 hours to see the changes.');
                    //component.set("v.stepNumber", "Zero");
                    //this.initializeWrapper(component, event, helper);
                    //component.set("v.selectedCourse",null);
                } 
                else if (state === "ERROR") {
                    //alert(JSON.stringify(response));
                    document.getElementById("Accspinner").style.display = "none";
                    var errors = response.getError();
                    //component.set("v.offeringsPosted", false);
                    alert("Error " + state + "\n" + errors[0].message);
          
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                            component.set("v.showError","true");
                            component.set("v.errorMessage",errors[0].message);	
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
            $A.enqueueAction(action);
        //});   
		//component.set("v.offeringsList", tempList);
    }, 
    createClass : function(component, event, helper) {
        //alert('***Offerings.. '+JSON.stringify(component.get("v.offeringsList")));
        var tempList = component.get("v.offeringsList"); 
        tempList.forEach(function(offering) {
            //alert('Opportunity ID '+offering.oppId+ " CCProductID "+offering.ccProductId);
            //alert('***Offerings.. '+JSON.stringify((offering)));
            
            
            var action = component.get("c.postClass");
            action.setParams({ jsonStr : JSON.stringify(offering) });
            action.setCallback(this, function(response) {
                var resp = response.getReturnValue();
                console.log('response..'+resp);
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log('success');
                    var postCount = component.get("v.offeringsPosted");
                    postCount = postCount + 1;
                    component.set("v.offeringsPosted", postCount);
                    //alert(component.get("v.offeringsPosted") + " == " + component.get("v.offeringId"));
                    if(component.get("v.offeringsPosted") == component.get("v.offeringId")){
                        if(component.get("v.offeringId") > 1){
                            alert('Classes posted successfully!!!');
                        } else {
                            alert('Class posted successfully!!!');
                        }
                    }

                    //alert('Class posted successfully!!!');
                    //component.set("v.stepNumber", "Zero");
                    //this.initializeWrapper(component, event, helper);
                    //component.set("v.selectedCourse",null);
                } 
                else if (state === "ERROR") {
                    var errors = response.getError();
                    //component.set("v.offeringsPosted", false);
                    alert("Error " + state + "\n" + errors[0].message);
                    
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                            component.set("v.showError","true");
                            component.set("v.errorMessage",errors[0].message);	
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
            $A.enqueueAction(action);
        });   
		//component.set("v.offeringsList", tempList);
    },

    getLearningPlanAttributes : function(component, event, helper) {
        var action = component.get("c.getLearningPlanAttributes");
        action.setParams({ccProdId : component.get("v.CCProductId")});
		//alert('get learning plan');
        	//alert(component.get("v.CCProductId")+'---');
        action.setCallback(this, function(response) {
            //var state = response.getState();
            //if (state === "SUCCESS") {

                var getResponse = response.getReturnValue();

                var learningPlan = getResponse.LMS_Learning_Plan__c;

                if (learningPlan != undefined) {
                    var courseName = getResponse.LMS_Learning_Plan__r.Name;
                    var courseFormat = getResponse.LMS_Learning_Plan__r.Classroom_Setting__c;
                    var courseDuration = getResponse.LMS_Learning_Plan__r.redwing__Duration__c;
                    //alert("LP Defined CourseDuration " + courseDuration);
                    var hours = 0;
                    if(courseDuration < 60){
                        hours = courseDuration; 
                    } else {
                        var hours = Math.floor(courseDuration / 60); 
                    }
 					
                	console.log("Hours: " + hours);
                    component.set("v.LPDuration", hours);
                    component.set("v.LPName", courseName);
                    component.set("v.LPClassroomSetting", courseFormat);
                    //alert('courseName:'+getResponse.LMS_Learning_Plan__r.Name);
                    component.set("v.cpsWrap.courseId", learningPlan);
                    component.set("v.cpsWrap.courseName", getResponse.LMS_Learning_Plan__r.Name);
                    component.set("v.cpsWrap.classFormat", courseFormat);                   
                    component.set("v.cpsWrap.classDuration", hours);
                    //component.set("v.ScheduledTime", hours);
                } else {
                    
                    component.set("v.LPName", 'Not Found');
                    component.set("v.LPClassroomSetting", '');
                    component.set("v.LPDuration", 0);
                    
                    component.set("v.cpsWrap.courseId", '');
                    component.set("v.cpsWrap.courseName", 'Not Found');
                    component.set("v.cpsWrap.classFormat", courseFormat); 
                    component.set("v.cpsWrap.classDuration", '');
                    alert("LP Not Defined CourseDuration " + courseDuration);
                }
            //}
        });
        $A.enqueueAction(action);
    },
    getLearningPlanAttributesByName : function(component, event, helper) {
        var action = component.get("c.getLearningPlanAttributesByName");
        action.setParams({LPName : component.get("v.cpsWrap.courseName")});
        action.setCallback(this, function(response) {
            //var state = response.getState();
            //if (state === "SUCCESS") {

                var getResponse = response.getReturnValue();

                var learningPlan = getResponse.LMS_Learning_Plan__c;
            //alert(getResponse.ccrz__ProductId__c);
            //alert('ok');
				//component.set("v.cpsWrap.CCProductId",getResponse.ccrz__ProductId__c);
                if (learningPlan != undefined) {
                    var courseName = getResponse.LMS_Learning_Plan__r.Name;
                    var courseFormat = getResponse.LMS_Learning_Plan__r.Classroom_Setting__c;
                    var courseDuration = getResponse.LMS_Learning_Plan__r.redwing__Duration__c;
                    //alert("LP Defined CourseDuration " + courseDuration);
                    var hours = 0;
                    if(courseDuration < 60){
                        hours = courseDuration; 
                    } else {
                        var hours = Math.floor(courseDuration / 60); 
                    }
 					
                	console.log("Hours: " + hours);
                    component.set("v.LPDuration", hours);
                    component.set("v.LPName", courseName);
                    component.set("v.LPClassroomSetting", courseFormat);

                    component.set("v.cpsWrap.courseId", learningPlan);
                    component.set("v.cpsWrap.courseName", getResponse.LMS_Learning_Plan__r.Name);
                    component.set("v.cpsWrap.classFormat", courseFormat);                   
                    component.set("v.cpsWrap.classDuration", hours);
                    //component.set("v.ScheduledTime", hours);
                } else {
                    
                    component.set("v.LPName", 'Not Found');
                    component.set("v.LPClassroomSetting", '');
                    component.set("v.LPDuration", 0);
                    
                    component.set("v.cpsWrap.courseId", '');
                    component.set("v.cpsWrap.courseName", 'Not Found');
                    component.set("v.cpsWrap.classFormat", courseFormat); 
                    component.set("v.cpsWrap.classDuration", '');
                    //alert("LP Not Defined CourseDuration " + courseDuration);
                }
            //}
        });
        $A.enqueueAction(action);
    },
    clearForm : function(component,event,helper) {
		component.set("v.cpsWrap.offeringId","0");
        //component.set("v.cpsWrap.accId","");
        //component.set("v.cpsWrap.accName","");
        component.set("v.cpsWrap.oppId",component.get("v.oppIdParent"));
        component.set("v.showError","false");
        component.set("v.errorMessage","");
        component.set("v.productChange", false);
    	component.set("v.CCProductId","");
    	component.set("v.LPName","");
        component.set("v.LPClassroomSetting","");
        component.set("v.LPDuration",0);
        component.set("v.ScheduledTime",0);
        component.set("v.cpsWrap.courseName","");
    	component.set("v.cpsWrap.ccProductId","");
    	component.set("v.cpsWrap.courseId","");    
    	component.set("v.cpsWrap.classFormat","");
    	component.set("v.cpsWrap.classDuration","");
    	component.set("v.cpsWrap.quantity","1");
        component.set("v.cpsWrap.sessionList",[]);
        var tempList = component.get("v.cpsWrap.sessionList");
        tempList.push({'classDate':'',
                       'startTime':'',
                       'endTime':''});
        component.set("v.cpsWrap.sessionList",tempList);
        component.set("v.myProductQuantityMap", component.get("v.myProductQuantityMap"));
        //component.set("v.cpsWrap.siteName","");
        //component.set("v.cpsWrap.address1","");
        //component.set("v.cpsWrap.address2","");
        //component.set("v.cpsWrap.city","");
        //component.set("v.cpsWrap.state","");
        //component.set("v.cpsWrap.zip","");
        //component.set("v.cpsWrap.regUrl","");
        //component.set("v.cpsWrap.regPhone","");
        //component.set("v.cpsWrap.regFee","");
        //component.set("v.selectedLookUpRecord5","");
        //component.set("v.selectedLookUpRecord1","");
        
        //$A.get("e.force:refreshView").fire();
        //component.destroy();
	
    },
    requiredSchedule : function(component,event,helper){
        //alert('requiredSchedule');
        //alert('classDuration'+component.get('v.cpsWrap.classDuration'));
        // Required Time Counter decrement value
        var classFormat = component.get('v.cpsWrap.classFormat');
        var required_time = component.get('v.cpsWrap.classDuration');
        //alert("classDuration " + component.get('v.cpsWrap.classDuration'));
        component.set("v.ScheduledTime",0);
        if(classFormat != "" && !required_time){
            component.set("v.scheduleError",true);
            component.set('v.cpsWrap.classDuration', 'NaN');
        } else {
            component.get("v.cpsWrap.sessionList").forEach(function(session) { 
                if(session.classDate && session.startTime && session.endTime){
                    var diff = Math.abs(new Date(session.classDate + " " + session.startTime) - new Date(session.classDate + " " + session.endTime)); 
                    var minutes = Math.floor(diff/60000);
                    //alert("Minutes: " + minutes);
                    var hours = Math.floor(minutes / 60); 
                    //alert("Hours: " + hours);
                    if(required_time < 60){
                        hours = minutes;
                    }
                    var timeScheduled = (component.get('v.ScheduledTime') +  hours);
                    //alert("timeScheduled: " + timeScheduled);
                    if(timeScheduled >= required_time && component.get('v.cpsWrap.classDuration') != 0){ 
                        component.set("v.scheduleError",false);
                    } else {
                        component.set("v.scheduleError",true);
                    }
                    
                    component.set("v.ScheduledTime",timeScheduled);
                }
                
            });
        }

    },
    setTimeZoneSelected : function(component, event, helper){
        /*
       var time_zone=component.get("v.cpsWrap.timeZone"));
    	
        if(time_zone=="US/Eastern")
		{
        
        }
        else(time_zone=="US/Central")
        }
        else(time_zone=="US/Mountain")
        }
         else(time_zone=="US/Pacific")
        }
        else(time_zone=="US/Eastern")
        }
        else(time_zone=="US/Eastern")
        }

}
elseif(US/Central")

if("US/Central"
if("US/Mountain"
if("US/Pacific"
if("US/Alaska"
if("US/Arizona"
if("US/Hawaii"
if("America/Puerto_Rico"
        */
        var tempList = component.get("v.cpsWrap.sessionList");
        tempList.forEach(function(session) {
            session.timeZone = component.get("v.cpsWrap.timeZone");
            if(session.timeZone) {
                document.getElementById('zoneSelect').classList.remove('requiredSelect');
            }
            else {
                document.getElementById('zoneSelect').classList.add('requiredSelect');
            }
        });
        
    },
    getGeocode : function(component, event, helper){
        var $this=this;
        //alert('calling getGeocode');
        //this.updateGeoLatLong(component,event,helper);
        var address = this.getFullAddress(component, event, helper);
         //alert('calling getGeocode2');
        var xmlHttp = new XMLHttpRequest();
        var url = 'https://maps.googleapis.com/maps/api/geocode/json?address='+address+',+CA&key=AIzaSyAbiSkystXXjCtlOAtH6H-4Ej2GLn_EbNM';
        //var url = 'http://maps.googleapis.com/maps/api/geocode/json?address='+address+',+CA&key=AIzaSyAbiSkystXXjCtlOAtH6H-4Ej2GLn_EbNM';
		//alert('calling getGeocode3');
        console.log(encodeURI(url));
    	xmlHttp.open( "GET", encodeURI(url),true);
        //alert('calling getGeocode4');
	    //xmlHttp.setRequestHeader('Content-Type', 'application/json');
		xmlHttp.responseType = 'json';
           //alert('calling getGeocode5');
		xmlHttp.onload      = function () {
            //alert('ok2');
            //   alert('calling getGeocode6');
    	    console.log("onload");
              // alert('calling getGeocode7');
        	console.log(xmlHttp.readyState);
              // alert('calling getGeocode8');
        	console.log(xmlHttp.status);
            
            //alert(xmlHttp.status);
            
            
    		if (xmlHttp.readyState === 4) {
                //alert('ready state 4');
          		
    	    	if (xmlHttp.status === 200) {
                    console.log("Response: " + JSON.stringify(xmlHttp.response));
                    //console.log("Response Text: " + JSON.stringify(xmlHttp.responseText));
                    console.log("Step 1");
                    if(xmlHttp.response.results[0] && xmlHttp.response.results[0].geometry){
                    	var lat = 0;
                        var lng = 0;
                    	console.log("Step 2 " + JSON.stringify(xmlHttp.response.results[0].geometry.location));
                        
                        if(xmlHttp.response.results[0].geometry.location.lat)
                            lat = xmlHttp.response.results[0].geometry.location.lat;
                        else 
                            lat = 'undefined';
                        
                        console.log("Step 3 " + lat);
                        document.getElementById('geoCodeLat').value = lat;
                        
                        if(xmlHttp.response.results[0].geometry.location.lng)
                        	lng = xmlHttp.response.results[0].geometry.location.lng;
                        else
                            lng = 'undefined';
                        
                        //alert('lng'+lng+' lat'+lat);
                        
                       // alert('lat '+lat+'  long '+lng);
                        
                        
                        console.log("Step 4 " + lng);
                        document.getElementById('geoCodeLng').value = lng;
						console.log("Lat: " + document.getElementById('geoCodeLat').value + " Lng: " + document.getElementById('geoCodeLng').value);
                        //console.log("Returned GEO Codes Lat: " + component.get("v.geoLat") + " Long:" + component.get("v.geoLong") );
						//alert('lat '+lat+'  long '+lng);
                        $this.updateGeoLatLong(component,event,helper);
                    }

		        }
	    	}
		};
	    xmlHttp.send();
    	
	    console.log("geo Request sent");
    }, 
    getFullAddress : function(component, event, helper){
            return ('"' + component.get("v.cpsWrap.address1") + ',' + component.get("v.cpsWrap.city") + ',' + component.get("v.cpsWrap.state")  + ',' +  component.get("v.cpsWrap.zip") + '"');
    },
    updateGeoLatLong : function (component, event, helper) {
    	component.set("v.cpsWrap.geoLat", document.getElementById('geoCodeLat').value);
        component.set("v.cpsWrap.geoLng", document.getElementById('geoCodeLng').value); 
    },
    createIltLocation : function(component) {
		//alert(component.get('v.cpsWrap.siteName'));
        //	alert(component.get('v.cpsWrap.geoLng'));
        //return false;
        // call apex method with the respective parameters
        var action = component.get('c.createIltLocation');
        
        //alert(JSON.stringify(component.get('v.cpsWrap')));
        
        action.setParams({
            accountId: component.get('v.cpsWrap.accId'),
            name: component.get('v.cpsWrap.siteName'),
            address1: component.get('v.cpsWrap.address1'),
            address2: component.get('v.cpsWrap.address2'),
            postcode: component.get('v.cpsWrap.zip'),
            state: component.get('v.cpsWrap.state'),
            city: component.get('v.cpsWrap.city'),
            lat: component.get('v.cpsWrap.geoLat'),
            lng: component.get('v.cpsWrap.geoLng')
        });
	   	    
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert(state);
            if (state === 'SUCCESS') {
                var storeResponse = response.getReturnValue();
                console.log('response from createIltLocation: '+ storeResponse);
                component.set('v.locationId', storeResponse);
                component.set('v.cpsWrap.locationId', storeResponse);
                //alert("Location ID "+storeResponse);
            }
            else if (state === "ERROR") {
                    var errors = response.getError();
                    //component.set("v.offeringsPosted", false);
                    alert("Error " + state + "\n" + errors[0].message);
                    //alert('oh no');
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                            component.set("v.showError","true");
                            component.set("v.errorMessage",errors[0].message);	
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            //alert("Location ID "+component.get('v.cpsWrap.locationId'));
        });
        $A.enqueueAction(action);
    },
   
   deleteClass : function(component) {
       
		 var action = component.get('c.deleteClass');
	
       //alert('ok'+component.get("v.cpsWrap.iltClassId"));
         //    return false;
      
        action.setParams({
            iltClassId: component.get("v.cpsWrap.iltClassId")
        });
	   	    
           //alert('d');
        action.setCallback(this, function(response) {
            //alert('aa4');
            var state = response.getState();
            alert('aa');
            if (state === 'SUCCESS') {
                alert('deleted');
                //var storeResponse = response.getReturnValue();
                //alert("Location ID "+storeResponse);
            }
            else if (state === "ERROR") {
                    var errors = response.getError();
                    //component.set("v.offeringsPosted", false);
                    alert("Error " + state + "\n" + errors[0].message);
                    
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                            component.set("v.showError","true");
                            component.set("v.errorMessage",errors[0].message);	
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
        });
    },
    
    getOfferings : function(component) {
      //alert('getofferings');
        // call apex method with the respective parameters
        var action = component.get('c.getOfferings');
        
        //alert('alert:'+component.get('v.cpsWrap.accId'));
        //alert('data:'+component.get('v.cpsWrap.accName'));
        action.setParams({
            accountId: component.get('v.cpsWrap.accId'),
            accountName: component.get('v.cpsWrap.accName')
        })

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                //alert('Account '+component.get('v.cpsWrap.accName') + " - " + component.get('v.cpsWrap.accId'));
				//alert('***Offerings.. '+JSON.stringify((response.getReturnValue())));
                component.set("v.offeringsList", response.getReturnValue());
            }
            else{
                //alert('error:' +JSON.stringify(response));
                //alert('***Offerings.. '+JSON.stringify((response.getReturnValue())));
                //alert(response.getReturnValue());
            }

        });
        $A.enqueueAction(action);
    },
})