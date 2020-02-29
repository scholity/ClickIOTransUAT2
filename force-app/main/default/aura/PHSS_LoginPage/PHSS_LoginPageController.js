/**
 * Created by bjarmolinski on 2019-06-07.
 */
({
    doInit: function (component, event, helper) {

        var version = component.get("v.version");
        if (version === "password") {
            component.set("v.header", "Password");
            component.set("v.subheader", "Please enter the password you use for your American Red Cross account.");
        } else if (version === "forgotpassword") {
            component.set("v.header", "Forgot Password");
            component.set("v.subheader", "Please enter the email address associated with your account to receive a reset password link.");
        } else if (version === "forgotpasswdEmail") {
            component.set("v.header", "Email Sent");
            component.set("v.subheader", "A reset password link has been sent to the email address you entered. Access your email to reset your password.");
        } else {
            component.set("v.header", "Login");
            component.set("v.subheader", "To log in, please enter the email address you use for your American Red Cross Training Services account.");
            component.set("v.disclaimer", "You may need to login to your account before checkout");
			component.set("v.disclaimertag", "Why do I have to do this?"); 
            component.set("v.disclaimerhelp", "The email you have entered matches an existing account on the site, to continue you will need to login.  If you don't know your password, please reset the password by clicking \"Forgot password\" link.");
        }
    }
})