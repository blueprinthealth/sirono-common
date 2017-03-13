/*
* @author Sirono
* @version 1.0.1
* @Date: 04-19-2016
* @ProcessPayment Class for the payment process.
*
* Mohan Kumar 08-12-2016: Convert the amount in cents before sending it to Sirono
* 
* 08-19-2016: Sirono - Tracker # 127324171
* Method for check the validation.
* Date: 21/09/2016 Sirono - tracker # 130677929 ChargeGroupList based on Account sub status 
*
* 10-17-2016: Viraj Rana - Tracker # 129073825: Take Payment in SF
*/

public with sharing class ProcessPaymentLightning {
    public String username { get; set; }
    public String password { get; set; }
    public string creditCardNumber { get; set; }
    public string cardHolderName { get; set; }
    public string expirationYear { get; set; }
    public string expirationMonth { get; set; }
    public string cvv { get; set; }
    public string amount { get; set; }
    public string address { get; set; }
    public string city { get; set; }
    public string state { get; set; }
    public string zip { get; set; }
    public String guarantorRecordId { get; set; }
    public Boolean chargeGroupsSelected { get; set; }
    public String guarantorId { get; set; }
    public String guarantorName { get; set; }
    public String chargeGroupId { get; set; }
    public List<ChargeGroupWrapper> chargeGroupList { get; set; }
	public Contact gc { get; set; }
	public String errorMessages{get;set;}
	public List<Transaction__c> listOfCreatedTransactions{get;set;}
    private Payment__c objPayment = new Payment__c();
    private List<Transaction__c> lsttransaction = new List<Transaction__c>();
    private List<Charge_Group__c> lstChargeGroup = new List<Charge_Group__c>();
    private List<Payment_Plan__c> lstPaymentPlan = new List<Payment_Plan__c>();

    public List<SelectOption> expYearOptions {
        get {
            if (expYearOptions == null) {
                expYearOptions = PayStaffWSUtillLightning.expYearOptions;
            }
            return expYearOptions;
        }
        protected set;
    }

    public List<SelectOption> expMonthOptions {
        get {
            if (expMonthOptions == null) {
                expMonthOptions = PayStaffWSUtillLightning.expMonthOptions;
            }
            return expMonthOptions;
        }
        protected set;
    }

    public ProcessPaymentLightning(ApexPages.StandardController sc, List<String> selectedIds) {
        username = PayStaffWSUtillLightning.un;
        password = PayStaffWSUtillLightning.pw;
		System.debug('pass:'+password);
        chargeGroupsSelected = false;
        guarantorName = '';
		errorMessages = '';
        /*
        guarantorId = '571';
        chargeGroupId = '1113837';
        creditCardNumber = '4012888888881881';
        expirationMonth = '12';
        expirationYear = '2018';
        cvv = '456';
        amount = '200';
        cardHolderName = 'Joe Schmoe';
        state = 'WI';
        address = '8131 W 48th';
        zip = '78737';
        city = 'Austin';*/

        chargeGroupList = new List<ChargeGroupWrapper>();
        guarantorRecordId = sc.getId();

        if (guarantorRecordId != null) {
            gc = PayStaffWSUtillLightning.fetchGuarantorContact(guarantorRecordId);
            guarantorName = PayStaffWSUtillLightning.fetchGuarantorName(gc);
            guarantorId = PayStaffWSUtillLightning.fetchGuarantorId(gc);
			Boolean once = false;
            //chargeGroupList = PayStaffWSUtillLightning.fetchChargeGroupList(gc);
            //Collection of ChargeGroups that are active, balance not zero and who's account sub status is Preinvoiced, Due, Overdue, Delinquent, Bad Debt, or Payment Plan.
            for (ChargeGroupWrapper cgw : PayStaffWSUtillLightning.fetchChargeGroupListByAccountSubStatus(gc)) {
                for(String item: selectedIds){
					if (item == cgw.cg.Invoice__c && cgw.cg.Active__c && cgw.cg.Balance__c != 0) {
						cgw.isSelected = true;
						chargeGroupList.add(cgw);
					}
				}
            }
            chargeGroupId = '';
        }
    }

    public Pagereference doNext() {
        chargeGroupsSelected = false;
		system.debug('chargeGroupList'+chargeGroupList);
        chargeGroupId = PayStaffWSUtillLightning.fetchChargeGroupIds(chargeGroupList);
        if (!isEmpty(chargeGroupId)) {
            chargeGroupsSelected = true;
        }/*else{
            chargeGroupsSelected = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR,
                'Please select atleast one Charge Group'));
        }*/
        return null;
    }

    private Boolean isEmpty(String str) {
        return (str == null || str.trim().equals(''));
    }

    // Method used for call processPayment method
    public String submit() {
        System.debug('submit:'+username+';'+password);
		try {

            /*
             * 08-19-2016: Sirono - Tracker # 127324171
             * Method for check the validation.
             */

            boolean blnIsError = false;
            blnIsError = checkCardValidation();
			system.debug(blnIsError);
            boolean blnIsAmountError = checkAmountValidation();
			system.debug(blnIsAmountError);
            if (blnIsError == false && !blnIsAmountError) {
                String jwtToken = PayStaffWSUtillLightning.getJWTToken(username, password);
                String csrfToken = PayStaffWSUtillLightning.getCSRFToken();
                if (csrfToken != null && jwtToken != null) {
                    processPayment(csrfToken, jwtToken);
                }
            } else {
                if (Test.IsRunningTest()) {
                    TestUtility.generateException();
                }
            }

        } catch (Exception e) {
            // Debug error response
			errorMessages += 'ERROR: ' + e.getMessage() + ';' + e.getStackTraceString(); 
        }
		System.debug('end submit');
		System.debug(errorMessages);
		String transactionInfo = '';
		if(errorMessages == ''){
			Transaction__c tr = new Transaction__c();
			tr = [SELECT id, Sirono_Id__c, Amount__c, Payment__r.Amount__c, Payment__r.Payment_Id__c FROM Transaction__c WHERE Charge_Group__r.Guarantor__c = :gc.id ORDER BY CreatedDate DESC LIMIT 1];
			System.debug(tr);
			transactionInfo = 'Success;' + String.valueOf(tr.Payment__r.Payment_Id__c) + ';$' + String.valueOf(tr.Payment__r.Amount__c);
		}
		System.debug(transactionInfo);
		return errorMessages != '' ? errorMessages : transactionInfo;
    }   

    /*
     * 08-19-2016: Sirono - Tracker # 127324171
     * Method for check the validation.
     */
    Public boolean checkAmountValidation() {
        boolean blnIsError = false;
        if (isEmpty(amount) || (amount.isNumeric() && decimal.valueof(amount) == 0)) {
            errorMessages += 'Amount must be greater than zero.';
			blnIsError = true;
        } else {
            decimal dctotalAmount = 0;
            for (ChargeGroupWrapper cgw : chargeGroupList) {
              //  if (cgw.cg.Balance__c != null && cgw.IsSelected == true) {
                if (cgw.cg.Balance__c != null && cgw.IsSelected == true) {
                    dctotalAmount += cgw.cg.Balance__c;
                }
            }
            if (decimal.valueof(amount) < 0) {
                errorMessages += 'Amount must be greater than zero.';
				blnIsError = true;
            }
			System.debug(amount + ';' + dctotalAmount);
            if (decimal.valueof(amount) > dctotalAmount) {
				errorMessages += 'Amount cannot exceed balance.';
                blnIsError = true;
            }
        }
        return blnIsError;
    }

    /*
     * 08-19-2016: Sirono - Tracker #127324171
     * Method for check the validation.
     * 09-13-2016: Viraj Rana - Tracker #130117819:   Credit Card Error Messaging Method to check the Card validation. 
     */
    Public boolean checkCardValidation() {
        boolean blnIsError = false;
        if (creditCardNumber.length() < 12 || creditCardNumber.Length() > 19) {
            errorMessages += 'Credit card number must be 12-19 digits.';
			blnIsError = true;
        }
        if (isEmpty(creditCardNumber)) {
			errorMessages += 'Card Number is a required field.';
            blnIsError = true;
        }
		System.debug(expirationYear);System.debug(expirationMonth);
		expirationYear = '20' + expirationYear;
		if (Integer.valueof(expirationYear) < system.today().year() ||
                (Integer.valueof(expirationYear) == system.today().year() &&
                        Integer.valueof(expirationMonth) < system.today().Month())) {
            errorMessages += 'Expiration date must be in the future.';
			blnIsError = true;
        }
        if (!isEmpty(zip) && zip.length() != 5) {
			errorMessages +=  'Zip code must be 5 digits.';
            blnIsError = true;
        }
        if (!isEmpty(zip) && !zip.isNumeric()) {
            errorMessages +=   'Zip code can only contain numeric values.';
			blnIsError = true;
        }
        if (isEmpty(cardHolderName)) {
			errorMessages +=   'Name is a required field.';
            blnIsError = true;
        }

        if (!isEmpty(cvv) && (cvv.length() < 3 || cvv.length() > 4)) {
            errorMessages +=  'CVV must be 4 digits for American Express and 3 digits for other card types.';
			blnIsError = true;
        }

        if (isEmpty(cvv)) {
            errorMessages +=  'CVV is a required field.';
			blnIsError = true;
        }

        if (isEmpty(address)) {
            errorMessages +=   'Billing Address is a required field.';
			blnIsError = true;
        }

        if (isEmpty(zip)) {
            errorMessages +=  'Zip Code is a required field.';
			blnIsError = true;
        }

        if (isEmpty(chargeGroupId)) {
            errorMessages +=  'Charge Group is a required field.';
			blnIsError = true;
        }

        return blnIsError;
    }
    
    /*
    #130125231 : Enable "Fill Name and Address on File" functionality.
    fill the address,city,state,zip variable with the guarantor information.
    */

    public void fillNameAndAddress() {
        cardHolderName = gc.name;
        address = gc.MailingStreet;
        city = gc.MailingCity;
        state = gc.MailingState;
        zip = gc.MailingPostalCode;
    }

    // Method used for payment process
    private void processPayment(String csrfToken, String jwtToken) {
		System.debug('chargeGroupId:'+chargeGroupId);
		String requestData = '{"csrfmiddlewaretoken":"' + csrfToken + '",' +
                '"guarantor":"' + SironoSettingsUtil.getServerEndpoint() + '/paystaff/api/guarantors/'
                + guarantorId + '/",' +
                '"number":"' + creditCardNumber + '",' +
                '"chargegroups": ' + PayStaffWSUtillLightning.buildChargeGroupsURL(chargeGroupId) + ',' +
                '"expiration_year":"' + expirationYear + '",' +
                '"cvv":"' + cvv + '",' +
                '"amount":' + PayStaffWSUtillLightning.convertToCents(amount) + ',' +
                '"expiration_month":"' + expirationMonth + '",' +
                '"cardholder_name":"' + cardHolderName + '",' +
                '"state":"' + state + '",' +
                '"address_1":"' + address + '",' +
                '"zipcode":"' + zip + '",' +
                '"city":"' + city + '",' +
                '"total-amount":' + PayStaffWSUtillLightning.convertToCents(amount) + ',' +
                '"method":"credit"}';

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();

        Http http = new Http();
        String responseBody;

        req.setMethod('POST');
        req.setHeader('Authorization', 'JWT ' + jwtToken);
        req.setHeader('Content-type', 'application/json');
        req.setEndpoint(SironoSettingsUtil.getServerEndpoint() + '/paystaff/api/paychargegroups/');

        req.setBody(requestData);
        system.debug('requestData : ' + requestData);

        try {
            res = http.send(req);
            responseBody = res.getBody();
            system.debug('responseBody : ' + responseBody);
            if (test.isRunningTest()) {
                TestUtility.generateException();
            }
        } catch (Exception e) {
            // Debug error response
			errorMessages += 'PROCESS PAYMENT EXCEPTION RESPONSE : ' + res.toString() + '  RESPONSE BODY::' + responseBody + ' EXCEPTION:: ' + e.getMessage();
        }

        if (res.getStatus() != null && res.getStatus().trim().equalsIgnoreCase('CREATED')
                && res.getStatusCode() != null && res.getStatusCode() == 201) {
            System.debug('RESPONSE : ' + res.toString() + '  RESPONSE BODY::' + responseBody);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.INFO, 'Created Successfully!'));

            //Call Payment, Transaction, ChargeGroups, Payment Plan Request.
            listOfCreatedTransactions = PayStaffWSUtillLightning.parsePaymentReponse(csrfToken, jwtToken, responseBody, true);
        } else {
            if (test.isRunningTest()) {
                responseBody = TestUtility.errorBody;
            }
            if (responseBody.Contains('non_field_errors') && responseBody.Contains('Validation exception')) {
                JSONParser parser = JSON.createParser(responseBody);
                WrapperErrorArray wrpPaymentPlanobj = (WrapperErrorArray) parser.readValueAs(WrapperErrorArray .class);
                if (wrpPaymentPlanobj != null && wrpPaymentPlanobj.errors.size() > 0) {
                    List<WrapperErrorArray.Errors> lstError = wrpPaymentPlanobj.errors;
                    for (WrapperErrorArray.Errors obj : lstError) {
						errorMessages += String.valueof(obj.non_field_errors);
                    }
                }
            } else if (responseBody.Contains('non_field_errors') && responseBody.Contains('Payments Exception')) {
                JSONParser parser = JSON.createParser(responseBody);
                WrapperError wrpPaymentPlanobj = (WrapperError) parser.readValueAs(WrapperError.class);
                if (wrpPaymentPlanobj != null && wrpPaymentPlanobj.errors.non_field_errors.size() > 0) {
                    for (String strMessage : wrpPaymentPlanobj.errors.non_field_errors) {
						errorMessages += String.valueof(strMessage);
                    }
                }
            } else if (responseBody.Contains('kind') && !responseBody.Contains('chargegroups')) {
                JSONParser parser = JSON.createParser(responseBody);
                WrapperListError wrpobj = (WrapperListError) parser.readValueAs(WrapperListError.class);
                if (wrpobj != null && wrpobj.errors.size() > 0) {
                    for (String strMessage : wrpobj.errors) {
						errorMessages += String.valueof(strMessage);
                    }
                }
            } else if (responseBody.Contains('kind') && responseBody.Contains('chargegroups')) {
                errorMessages += 'RESPONSE : ' + res.toString() + '  RESPONSE BODY::' + responseBody;
				
            } else if(responseBody.Contains('non_field_errors')){
                JSONParser parser = JSON.createParser(responseBody);
                WrapperNonFieldErrorArray wrpPaymentPlanobj  = (WrapperNonFieldErrorArray)parser.readValueAs(WrapperNonFieldErrorArray.class);
                if(wrpPaymentPlanobj  != null && wrpPaymentPlanobj.non_field_errors.size() > 0){
                    for(String strMessage : wrpPaymentPlanobj.non_field_errors){
						errorMessages += String.valueof(strMessage);
					}
                }
            } else {
				errorMessages += 'RESPONSE : ' + res.toString() + '  RESPONSE BODY::' + responseBody;
                
            }
        }
    }
}