/**
 * Created by dgajwani on 9/28/18.
 */
/**
 * Created by dgajwani on 9/13/18.
 */
({

    /**
     * @description Shows a toast message to the user.
     * @param header
     * @param message
     * @param type
     */
    showToastMessage: function (header, message, type) {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            title: header,
            message: message,
            type: type
        });
        toastEvent.fire();
    },

    /**
     * @description Gets the form data required to make a POST request to cybersource.
     * @param component
     * @param event
     * @param helper
     */
    getFormData: function (component, event, helper) {
        component.set('v.showSpinner', true);
        var action = component.get('c.getCybersourceHostedFormData');
        var currOpportunitySfid = component.get('v.currOpportunitySfid');
        action.setParams({currOpportunitySfid: currOpportunitySfid});
        action.setCallback(this, function (response) {
            var state = response.getState();
            var returnValue = response.getReturnValue();
            if (state === 'SUCCESS' && returnValue != null) {
                if (returnValue.Error == null) {
                    console.log("getFromData successfully returned...");
                    component.set('v.cybersourceHostedFormData', returnValue);
                    helper.parseReceivedFormData(component, event, helper);
                } else {
                    this.showToastMessage('Error Loading Credit Card Form', returnValue.Error, 'Error');
                }
            } else {
                this.showToastMessage('Error Fetching Data', 'Unable to contact server.', 'Error');
            }
            component.set('v.showSpinner', false);
        });
        $A.enqueueAction(action);
    },

    /**
     * @description Parses the form data received from the server and sets the form attributes.
     * @param component
     * @param event
     * @param helper
     */
    parseReceivedFormData: function (component, event, helper) {

        var cybersourceHostedFormData = component.get('v.cybersourceHostedFormData');
        if (cybersourceHostedFormData != null) {
            component.set('v.access_key', cybersourceHostedFormData.accessKey);
            component.set('v.profile_id', cybersourceHostedFormData.profileId);
            component.set('v.transaction_uuid', cybersourceHostedFormData.transactionId);
            component.set('v.signed_field_names', cybersourceHostedFormData.signedFields);
            component.set('v.signature', cybersourceHostedFormData.signedData);
            component.set('v.unsigned_field_names', cybersourceHostedFormData.unsignedFields);
            component.set('v.reference_number', cybersourceHostedFormData.referenceNumber);
            component.set('v.transaction_type', cybersourceHostedFormData.transactionType);
            component.set('v.locale', cybersourceHostedFormData.locale);
            component.set('v.currency', cybersourceHostedFormData.currencyCode);
            component.set('v.signed_date_time', cybersourceHostedFormData.utcDate);
            component.set('v.payment_method', cybersourceHostedFormData.paymentMethod);
            component.set('v.ignore_avs', cybersourceHostedFormData.ignoreAvs);
            component.set('v.override_custom_receipt_page', cybersourceHostedFormData.returnURL);
            component.set('v.merchant_defined_data1', cybersourceHostedFormData.cartEncId);
            component.set('v.returnURL', cybersourceHostedFormData.returnURL);
            component.set('v.postURL', cybersourceHostedFormData.postURL);
            component.set('v.amount', cybersourceHostedFormData.amount);
            component.set('v.iframeURL', cybersourceHostedFormData.iframeURL);
            component.set('v.ipAddr', cybersourceHostedFormData.ipAddr);
            component.set('v.accountId', cybersourceHostedFormData.accountId);
            component.set('v.accountCreated', cybersourceHostedFormData.accountCreatedDate);
            component.set('v.accountLastModified', cybersourceHostedFormData.accountLastModifiedDate);
            component.set('v.bill_to_forename', cybersourceHostedFormData.firstName);
            component.set('v.bill_to_surname', cybersourceHostedFormData.lastName);
            component.set('v.bill_to_email', cybersourceHostedFormData.email);
            //remove all special chars
            let billToPhone = (cybersourceHostedFormData.phone ? cybersourceHostedFormData.phone.replace(/\D+/g, "") : cybersourceHostedFormData.phone);
            component.set('v.bill_to_phone', billToPhone);
            
            console.log("@@@cybersourceHostedFormData.stateCodes:", cybersourceHostedFormData.stateCodes);
            if(cybersourceHostedFormData.stateCodes){
                var stateCodes = [];
                for(let code in cybersourceHostedFormData.stateCodes){
                    stateCodes.push({label: code, value: code});
                }
                component.set("v.state_options", stateCodes);
            }
            // Creating key-value pairs to be used in lightning:select.
            var paymentTypesList = [];
            var paymentTypesMap = cybersourceHostedFormData.paymentTypes;
            console.log('@@@paymentTypesMap:', paymentTypesMap);
            for (var key in paymentTypesMap) {
                paymentTypesList.push({key: key, value: paymentTypesMap[key]});
            }
            console.log('@@@paymentTypes:', paymentTypesList);
            component.set('v.paymentTypes', paymentTypesList);
/* 
 * US1487 Commented out Billing Information per client request - SW 2/23/2018
 * 
 *          component.set('v.bill_to_address_line1', cybersourceHostedFormData.street);
            component.set('v.bill_to_address_city', cybersourceHostedFormData.city);
            component.set('v.bill_to_address_state', cybersourceHostedFormData.state);
            component.set('v.bill_to_address_postal_code', cybersourceHostedFormData.zipcode);
*/        }
        // component.set('v.bill_to_address_country', cybersourceHostedFormData.country);
        component.set('v.showForm', true);
        helper.validateFormData(component, false);
    },

    /**
     * Pass the data to the invisible iframe form for post.
     * @param component
     * @param event
     * @param helper
     */
    POSTFormData: function (component, helper) {
        console.log("@@@POSTFormData start...");
        var isFormDataValid = helper.validateFormData(component, true);
        if (!isFormDataValid) {
            console.log("NOT VALID");
            this.showToastMessage('Error', 'Unable to submit payment. Please check that all errors on the page have been resolved.', 'Error');
            return;
        }
        console.log("@@@POSTFormData isFormDataValid is true...");
        var cardTypeCode;
        var card_type = component.get("v.card_type");
        console.log("@@@POSTFormData card_type:", card_type);
        var paymentTypesList = component.get("v.paymentTypes");
        console.log("@@@POSTFormData paymentTypesList:", paymentTypesList);
        for (var pmt of paymentTypesList) {
            console.log("@@@POSTFormData pmt.value:", pmt.value);
            if(pmt.value === card_type){
                cardTypeCode = pmt.key.toString();
                break;
            }
        }
        console.log("@@@cardTypeCode:", cardTypeCode);
        if(!cardTypeCode){
            this.showToastMessage('Error', 'Unable to submit payment: Card Type invalid.', 'Error');
            return;
        }
        console.log("@@@POSTFormData cardTypeCode has value...");
        // Map to send message.
        var message = {
            access_key: component.get("v.access_key"),
            profile_id: component.get("v.profile_id"),
            transaction_uuid: component.get("v.transaction_uuid"),
            signed_field_names: component.get("v.signed_field_names"),
            signature: component.get("v.signature"),
            unsigned_field_names: component.get("v.unsigned_field_names"),
            reference_number: component.get("v.reference_number"),
            transaction_type: component.get("v.transaction_type"),
            locale: component.get("v.locale"),
            currency: component.get("v.currency"),
            signed_date_time: component.get("v.signed_date_time"),
            payment_method: component.get("v.payment_method"),
            ignore_avs: component.get("v.ignore_avs"),
            override_custom_receipt_page: component.get("v.override_custom_receipt_page"),
            merchant_defined_data1: component.get("v.merchant_defined_data1"),
            postURL: component.get("v.postURL"),
            amount: component.get("v.amount"),

            bill_to_forename: component.get("v.bill_to_forename"),
            bill_to_surname: component.get("v.bill_to_surname"),
            bill_to_email: component.get("v.bill_to_email"),
            bill_to_phone: component.get("v.bill_to_phone"),

            card_type: cardTypeCode,
            card_number: (component.get("v.card_number")).replace(/-/g, ''),
            card_expiry_date: component.get("v.card_expiry_month") + '-' + component.get("v.card_expiry_year"),
            card_cvn: component.get("v.card_cvn"),

            bill_to_address_line1: component.get("v.bill_to_address_line1"),
            bill_to_address_city: component.get("v.bill_to_address_city"),
            bill_to_address_country: component.get("v.bill_to_address_country"),
            bill_to_address_state: component.get("v.bill_to_address_state"),
            bill_to_address_postal_code: component.get("v.bill_to_address_postal_code"),

            merchant_defined_data33: component.get("v.ipAddr"),
            merchant_defined_data38: component.get("v.accountId"),
            merchant_defined_data39: component.get("v.accountCreated"),
            merchant_defined_data40: component.get("v.accountLastModified")
        };
        var iframeURL = component.get('v.iframeURL');
        console.log(iframeURL);
        var vfWindow = component.find("CC_Cybersource_pmt_iframe").getElement().contentWindow;
        vfWindow.postMessage(message, iframeURL);
    },

    /**
     * Handle the response from cybersource. Send an event with the response to the parent.
     * @param component
     * @param cyberSourceResponse
     */
    processCyberSourceCallback: function (component, cyberSourceResponse) {
        var requiresClick = component.get('v.requiresClickHack');
        
        var action = component.get('c.verifyCyberSourceResponse');
        if (action == undefined){
	       return requiresClick;
        }
        var currOpportunitySfid = component.get('v.currOpportunitySfid');
        action.setParams({
            currOpportunitySfid: currOpportunitySfid,
            cyberSourceResponseString: cyberSourceResponse
        });

        action.setCallback(this, function (response) {
            console.log('callback initiated');
            var state = response.getState();
            var returnValue = response.getReturnValue();
            if (state === 'SUCCESS' && returnValue != null) {
                if (returnValue.success == true) {
                    var updateEvent = component.getEvent('cyberSourceResponse');
                    updateEvent.setParams({'responseString': cyberSourceResponse});
                    updateEvent.fire();
                } else {
                    if (returnValue.ignoreError == true) {
                        // Do nothing.
                    } else {
                        this.showToastMessage('Error', 'There was a problem processing the payment.', 'Error');
                    }
                }
            } else {
                this.showToastMessage('Error Fetching Data', 'Unable to contact server.', 'Error');
            }
            component.set('v.showSpinner', false);
        });
        component.set('v.showSpinner', true);
        $A.enqueueAction(action);
        console.log('action enqueued');
        
        return requiresClick;
    },
    
    showPaymentProgressAlert : function (component, helper) {
        component.set('v.showPaymentProgress', true);
    },

    validateFormData : function (component, finalValidation) {
        var invalidFields = [];
        finalValidation = finalValidation == null ? false : finalValidation;
        var isValid = component.find('payment_form').reduce(
            function (validSoFar, inputCmp) {
                let inputValue = inputCmp.get("v.value");
                let alwaysValidate = $A.util.hasClass(inputCmp, "always-validate");
                if(finalValidation || alwaysValidate || (inputValue && inputValue.trim().length > 0) ){
                    try{
                        inputCmp.reportValidity();
                    }
                    catch(err){
                        console.log("reportValidity error:", err);
                    }
                    try{
                        inputCmp.checkValidity();
                    }
                    catch(err){
                        console.log("checkValidity error:", err);
                    }
                    inputCmp.showHelpMessageIfInvalid();
                }
                let inputValid = inputCmp.get("v.validity").valid;
                if(!inputValid){
                    invalidFields.push( inputCmp.get("v.label") );
                }
                return validSoFar && inputValid;
            }, 
            true //default function value
        );
        console.log("validateFormData isValid:", isValid);
        component.set("v.formInputValid", isValid);
        component.set("v.invalidFields", invalidFields);
        return isValid;
    }
})