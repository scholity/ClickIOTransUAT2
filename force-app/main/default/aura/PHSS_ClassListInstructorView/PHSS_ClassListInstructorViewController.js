({
    doInit : function(component, event, helper) {
        component.set("v.objName","Account");
        helper.getValues(component);
        //helper.getData(component);
    },
    
    /*Note:
        This component is very inefficient and could be refactored to store data in memory and not query server each time an inst ro acct changes
    */
    getInstructorValues : function(component, event, helper) {
        if(component.get("v.selectedAccount") == "") {
            component.set("v.selectedInstructor","");
            component.set("v.historyClasses", []);
            component.set("v.currentClasses", []);
        }    
        else { 
            component.set("v.objName","User");
            helper.getValues(component);
            helper.getData(component);
        }
    },
    
    handleSelectTab : function(component, event, helper){
        var nameTab = event.getParam('id');
        var selectedTab = component.get("v.selectedTab");
        var isNeedUpdatedData = true;
        if(selectedTab === nameTab){
            isNeedUpdatedData = false;
        } else{
            component.set("v.isHistory", !component.get("v.isHistory"));
        }
        var selectedAccount = component.get("v.selectedAccount");
        if(isNeedUpdatedData && selectedAccount){
            helper.getData(component);
        }
        component.set("v.selectedTab", nameTab);
    },
    
    handleOrgSelection : function(component, event, helper) {
        if(component.get("v.selectedAccount") == "") {
            component.set("v.selectedInstructor","");
        }    
        helper.getData(component);
    },
    
    getInstClasses : function(component, event, helper) {
        helper.getData(component);
    },
    
    goToDetail : function(component, event, helper){
        var url = location.href;
        url= url.split('/s/');
        //window.location.href = url[0] + '/s/ilt-detail?recordId=' + event.target.dataset.id + '&pId=' + (event.target.dataset.pid ? event.target.dataset.pid : 'null'); 
        window.open('../s/ilt-detail?recordId=' + event.target.dataset.id + '&pId=' + (event.target.dataset.pid ? event.target.dataset.pid : 'null'), '_parent');
    },
    
    sortField : function(component, event, helper) {
        var dataset = event.target.dataset;
        helper.sortFields(component, dataset.array, dataset.field, dataset.order);
    },
    
    downloadDocumentCurrent : function(component, event, helper){
        var sendData = component.get("v.sendData");
        
        console.log('dataToSend='+component.get("v.currentClasses"));        
        var dataToSend = component.get("v.currentClasses");
        
        //invoke vf page js method
        sendData(dataToSend, 'PDF', 'Current', function(){
            //handle callback
        });
    },
    
    exportDocumentCurrent : function(component, event, helper){
        var sendData = component.get("v.sendData");
        
        console.log('dataToSend='+component.get("v.currentClasses"));        
        var dataToSend = component.get("v.currentClasses");
        
        //invoke vf page js method
        sendData(dataToSend, 'XLS', 'Current', function(){
            //handle callback
        });
    },
    
    downloadDocumentHistory : function(component, event, helper){
        var sendData = component.get("v.sendData");
        
        console.log('dataToSend='+component.get("v.historyClasses"));        
        var dataToSend = component.get("v.historyClasses");
        
        //invoke vf page js method
        sendData(dataToSend, 'PDF', 'History', function(){
            //handle callback
        });
    },
    
    exportDocumentHistory : function(component, event, helper){
        var sendData = component.get("v.sendData");
        
        console.log('dataToSend='+component.get("v.historyClasses"));        
        var dataToSend = component.get("v.historyClasses");
        
        //invoke vf page js method
        sendData(dataToSend, 'XLS', 'History', function(){
            //handle callback
        });
    }
})