public class PHSS_ForgotUsernameController {
    @AuraEnabled
    public static User fetchUser(String emailAddress) {
        List < User > listUsers = [ SELECT Id, Username, IsActive FROM User WHERE Email =: emailAddress ];
        if ( listUsers.size() > 0 ) {
            User usr = listUsers[0];
            return usr;
        }
        else
            return null;
    }
    
}