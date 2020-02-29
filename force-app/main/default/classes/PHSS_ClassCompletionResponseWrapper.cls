public with sharing class  PHSS_ClassCompletionResponseWrapper {
    
    @AuraEnabled
    public String account_Id {get;set;}
    @AuraEnabled
    public String batch_Id {get;set;}
    @AuraEnabled
    public String offering_Id {get;set;}
    @AuraEnabled
    public String cre_ilt_class_Id {get;set;}
    @AuraEnabled
    public String student_firstName {get;set;}
    @AuraEnabled
    public String student_lastName {get;set;}
    @AuraEnabled
    public String student_certCompletionQRCode {get;set;}    
    @AuraEnabled
    public String student_achievement {get;set;}
    @AuraEnabled
    public String student_achievement_createDate {get;set;}
    @AuraEnabled
    public String student_notes {get;set;}

    public PHSS_ClassCompletionResponseWrapper() {
        
    }

}