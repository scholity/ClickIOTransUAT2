@isTest
private class PHSS_ForgotUsernameControllerTest {
    @isTest static  void testGetCallout() {
        
        User runAsUser = [Select Id,FirstName,LastName,Alias,Email,Username,ProfileId,UserRoleId,TimeZoneSidKey,
                          EmailEncodingKey,LanguageLocaleKey,LocaleSidKey from User Where IsActive = True And
                          Name != 'Salesforce Automation Account' And UserRoleId != NULL
                          And Profile.Name = 'System Administrator' Limit 1];
        
        System.RunAs(runAsUser) {
            test.startTest();
            PHSS_ForgotUsernameController.fetchUser(runAsUser.Email);
            test.stopTest();
        }
    }
}