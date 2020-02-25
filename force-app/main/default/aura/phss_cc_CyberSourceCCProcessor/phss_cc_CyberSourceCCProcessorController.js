/**
 * Created by dgajwani on 9/28/18.
 */
({
    /**
     * @description Gets the form POST data from the server and attaches a listener to hear for the cybersource response.
     * @param component
     * @param event
     * @param helper
     */
    doInit: function (component, event, helper) {
        console.log("@@@oppId:", component.get("v.currOpportunitySfid"));
        helper.getFormData(component, event, helper);
        window.addEventListener("message", function(event) {
			var cyberSourceResponse = event.data;

			if (cyberSourceResponse == null) { return; }
            if (typeof cyberSourceResponse == 'object') { return; }
            if (typeof cyberSourceResponse == 'string') {
                try {
                    var json = JSON.parse(cyberSourceResponse);
                    if (!json.hasOwnProperty('decision')) {
                        return;
                    }
                } catch (error) {
                    return;
                }
            }

            var requiresClick = helper.processCyberSourceCallback(component,cyberSourceResponse);
            window.scrollBy(0,1);

            if (requiresClick) {
                if (document !== undefined) {
                    var mouseEvent = document.createEvent("MouseEvents");
                    if (typeof mouseEvent.initMouseEvent === 'function') {
                        if (window.location.pathname.startsWith('/lightning/')) {
                            try {
                                mouseEvent.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
                                document.dispatchEvent(mouseEvent);
                            } catch (e) {
                                helper.showPaymentProgressAlert(component, helper);
                            }
                        }
                        else {
                            mouseEvent.initMouseEvent("click", true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
                            document.dispatchEvent(mouseEvent);
                        }
                    }
                }
            }
        }, false);
    },
    
    dismissPaymentProgress : function (component, event, helper) {
        component.set('v.showPaymentProgress', false);
    },
    
    handleABAmount : function (component, event, helper) {
        console.log("handleABAmount ON CC");
        
        var newAmount = event.getParam('amtFrmAccBalance');
        
        console.log("newAmount ON CC*** " +newAmount);
        
        component.set("v.amount", newAmount);
    },

    /**
     * @description POST the form to Cybersource via the iframe bridge form.
     * @param component
     * @param event
     * @param helper
     */
    submitFormData : function (component, event, helper) {
        console.log("submit form data start...");
        helper.POSTFormData(component, helper);
    },

    handleFormInputChanged : function(component, event, helper){
        helper.validateFormData(component, false);
    },

    handleCardNumberChanged : function(component, event, helper){
        let cardNumber = event.getSource().get("v.value");
        let cardType;
        let cardNumberLength = 16;
        let isCurrentlyAmexPmt = component.get("v.isAmexPmt");
        isCurrentlyAmexPmt = isCurrentlyAmexPmt == null ? false : isCurrentlyAmexPmt;
        let isAmexPmt = false;
        if(cardNumber && cardNumber.length > 0){
            let firstChar = cardNumber.charAt(0);
            if(firstChar == "4"){ //visa
                cardType = "Visa";
            }
            else if(firstChar == "5" || firstChar == "2"){ //mastercard
                cardType = "Mastercard";
            }
            else if(firstChar == "3"){ //amex
                cardType = "American Express";
                cardNumberLength = 15;
                isAmexPmt = true;
            }
            else if(firstChar == "6"){ //discover
                cardType = "Discover";
            }
        }
        if(isCurrentlyAmexPmt != isAmexPmt){
            component.set("v.card_cvn", null);
        }
        let cardNumberPattern = "[0-9]{"+cardNumberLength+"}";
        component.set("v.card_type", cardType);
        component.set("v.card_number_length", cardNumberLength);
        component.set("v.card_number_pattern", cardNumberPattern);
        component.set("v.isAmexPmt", isAmexPmt);
        helper.validateFormData(component, false);
    },

    validateEntireForm : function(component, event, helper){
        console.log("handleSubmitButtonOnHover...");
        var formInputValid = component.get("v.formInputValid");
        if(formInputValid == false){
            helper.validateFormData(component, true);
        }
    },

    validateCreditCardNumberInput : function(component, event, helper){
        console.log('validateCreditCardNumberInput...');
        let card_number = component.get("v.card_number");
        card_number = card_number.replace(/\D+/g, "");
        component.set("v.card_number", card_number);
        helper.validateFormData(component, false);
    },

    validatePhoneNumberInput : function(component, event, helper){
        console.log('validatePhoneNumberInput...');
        let bill_to_phone = component.get("v.bill_to_phone");
        bill_to_phone = bill_to_phone.replace(/\D+/g, "");
        component.set("v.bill_to_phone", bill_to_phone);
        helper.validateFormData(component, false);
    },

    validateExpirationDate : function(component, event, helper){
        let expMonth = component.get("v.card_expiry_month");
        let expYear = component.get("v.card_expiry_year");
        let todayDate = new Date();
        if(expMonth && expYear && expYear.length === 4 && expMonth.length === 2){
            let expMonthInput;
            for( let inputCmp of component.find("payment_form") ){
                if($A.util.hasClass(inputCmp, "exp-month")){
                    expMonthInput = inputCmp;
                    break;
                }
            }
            if(expYear == todayDate.getFullYear() && expMonth < (todayDate.getMonth() + 1)){
                expMonthInput.setCustomValidity("Please enter a valid expiration month");
                component.set("v.formInputValid", false);
            }
            else{
                expMonthInput.setCustomValidity("");
                
            }
        }
        helper.validateFormData(component, false);
    }

})