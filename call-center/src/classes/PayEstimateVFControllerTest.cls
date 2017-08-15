/*
 * Copyright (c) 2017-present Sirono LLC, All rights reserved
 */

/**
 * Test class for the PayEstimateVFController Class
 **/
@IsTest
public class PayEstimateVFControllerTest {

    /**
     * This method test the whole scenario of Pay Estimate Process.
     **/
    @IsTest
    public static void checkPayEstimateProcess() {
        // Create Guarantor Contact record.
        Contact guarantorContact = TestUtility.generateGuarantorContact();
        insert guarantorContact;

        // Create Encounter record.
        Encounter__c encounter = TestUtility.generateEncounter(guarantorContact.Id, 500, System.today());
        insert encounter;

        Test.startTest();

        // Create PayEstimateVFController class object with guarantorContact.
        PayEstimateVFController objPayEstimate = new PayEstimateVFController(new ApexPages.StandardController(guarantorContact));

        // Based on Encounter List, Select Encounter record.
        for (EncounterWrapper enw : objPayEstimate.encounters) {
            enw.isSelected = true;
        }

        // Call doNext Method.
        objPayEstimate.doNext();

        // Set page level variables based on criteria.
        objPayEstimate.expirationYear = String.valueOf(System.today().year() + 1);
        objPayEstimate.expirationMonth = '07';
        objPayEstimate.creditCardNumber = '1234567891113';
        objPayEstimate.cardHolderName = 'Test Name';
        objPayEstimate.zip = '07895';
        objPayEstimate.amount = '100';
        objPayEstimate.cvv = '1234';
        objPayEstimate.state = 'Test State';
        objPayEstimate.address = 'Test Address';
        objPayEstimate.city = 'Test City';

        // Call below parameters for Code Coverage.
        //noinspection ApexUnusedDeclaration
        List<SelectOption> expYearOptions = objPayEstimate.expYearOptions;
        //noinspection ApexUnusedDeclaration
        List<SelectOption> expMonthOptions = objPayEstimate.expMonthOptions;

        // Call submit method. that take/create payment for Encounter Record.
        objPayEstimate.submit();

        Test.stopTest();

        // Get List of Payment based on Encounter.
        List<Payment__c> payments = [
            SELECT Id, Amount__c, Guarantor__c, Encounter__c
            FROM Payment__c
            WHERE Encounter__c = :encounter.Id
        ];
        // Check system assert, Encounter Look up set in Payment Record or not.
        System.assertEquals(payments[0].Encounter__c, encounter.Id);
        // Check system assert, Guarantor is same for Payment and Encounter.
        System.assertEquals(payments[0].Guarantor__c, guarantorContact.Id);
        // Check system assert, We insert/set amount in object/record is assign into Payment.
        System.assertEquals(payments[0].Amount__c, Decimal.valueOf(objPayEstimate.amount));

        // Get List of Encounter based on Id.
        List<Encounter__c> encounters = [
            SELECT Id, Balance__c
            FROM Encounter__c
            WHERE Id = :encounter.Id
        ];
        // Set variable 500(Existing Balance in Encounter) minus Amount of Payment.
        Decimal encounterAmount = 500 - payments[0].Amount__c;
        // Check system assert, Enconter balance is decreases by the Amount of Payment.
        System.assertEquals(encounters[0].Balance__c, encounterAmount);
    }

    /**
     * This method test the FillNameAndAddress method functionality.
     * Based on Contact populate address, city, pincode, etc...
     **/
    @IsTest
    static void checkFillNameAndAddress() {
        // Create Guarantor Contact record.
        Contact guarantorContact = TestUtility.generateGuarantorContact();
        insert guarantorContact;

        Test.startTest();

        // Create PayEstimateVFController class object with guarantorContact.
        PayEstimateVFController objPayEstimate = new PayEstimateVFController(new ApexPages.StandardController(guarantorContact));
        objPayEstimate.guarantorRecordId = guarantorContact.Id;
        objPayEstimate.init(guarantorContact.Id);
        Encounter__c[] encounterList = EncounterService.getEncounterRecordsByGuarantorId(guarantorContact.Id);
        objPayEstimate.encounters = EncounterWrapper.buildList(encounterList);

        // Check system asserts, all fields are null of objPayEstimate.
        System.assertEquals(objPayEstimate.cardHolderName, null);
        System.assertEquals(objPayEstimate.address, null);
        System.assertEquals(objPayEstimate.city, null);
        System.assertEquals(objPayEstimate.state, null);
        System.assertEquals(objPayEstimate.zip, null);

        // Update contact to set city, postal code.
        guarantorContact.MailingCity = 'Test City';
        guarantorContact.MailingPostalCode = '12345';
        update guarantorContact;

        // Create PayEstimateVFController class object with updated guarantorContact.
        objPayEstimate = new PayEstimateVFController(new ApexPages.StandardController(guarantorContact));
        // Call fillNameAndAddress method that set/assign address, city, zip, etc in Page Level variables.
        objPayEstimate.fillNameAndAddress();

        Test.stopTest();

        // Get Contact record.
        List<Contact> contacts = [
            SELECT Id, Name, MailingCity, MailingPostalCode
            FROM Contact
            WHERE Id = :guarantorContact.Id
        ];

        // Check system asserts that set/assign Page Level Variables based on Contact fields value.
        System.assertEquals(objPayEstimate.cardHolderName, contacts[0].Name);
        System.assertEquals(objPayEstimate.city, contacts[0].MailingCity);
        System.assertEquals(objPayEstimate.zip, contacts[0].MailingPostalCode);
    }
    
    /**
     * This method test/cover the else part of Submit method.
     **/
    @IsTest
    static void submitElsePart() {
        // Create Guarantor Contact record.
        Contact guarantorContact = TestUtility.generateGuarantorContact();
        insert guarantorContact;

        // Create Encounter record.
        Encounter__c encounter = TestUtility.generateEncounter(guarantorContact.Id, 500, System.today());
        insert encounter;

        Test.startTest();
        // Create PayEstimateVFController class object with guarantorContact.
        PayEstimateVFController objPayEstimate = new PayEstimateVFController(new ApexPages.StandardController(guarantorContact));
        objPayEstimate.guarantorRecordId = guarantorContact.Id;
        objPayEstimate.init(guarantorContact.Id);
        Encounter__c[] encounterList = EncounterService.getEncounterRecordsByGuarantorId(guarantorContact.Id);
        objPayEstimate.encounters = EncounterWrapper.buildList(encounterList);

        // Based on Encounter List, Select Encounter record.
        for (EncounterWrapper enw : objPayEstimate.encounters) {
            enw.isSelected = true;
        }

        // Call doNext Method.
        objPayEstimate.doNext();

        // Set variables to generate errors.
        objPayEstimate.amount = '';
        objPayEstimate.cvv = '';
        objPayEstimate.creditCardNumber = '1234';
        objPayEstimate.expirationYear = String.valueOf(System.today().year());
        objPayEstimate.expirationMonth = String.valueOf(System.today().month() - 1);

        // Call submit method.
        objPayEstimate.submit();

        Test.stopTest();

        // Get List of Payment based on Encounter.
        List<Payment__c> payments = [
            SELECT Id, Amount__c, Guarantor__c, Encounter__c
            FROM Payment__c
            WHERE Encounter__c = :encounter.Id
        ];
        // Check system assert, Payment is not create for encounter.
        System.assertEquals(payments.size(), 0);
    }

    /**
     * This method tests the logic of errorMessages is empty or not.
     **/
    @IsTest
    static void errorMessagesTest() {
        // Create Guarantor Contact record.
        Contact guarantorContact = TestUtility.generateGuarantorContact();
        insert guarantorContact;

        // Create Encounter record.
        Encounter__c encounter = TestUtility.generateEncounter(guarantorContact.Id, 500, System.today());
        insert encounter;

        Test.startTest();
        // Create PayEstimateVFController class object with guarantorContact.
        PayEstimateVFController objPayEstimate = new PayEstimateVFController(new ApexPages.StandardController(guarantorContact));
        objPayEstimate.guarantorRecordId = guarantorContact.Id;
        objPayEstimate.init(guarantorContact.Id);
        Encounter__c[] encounterList = EncounterService.getEncounterRecordsByGuarantorId(guarantorContact.Id);
        objPayEstimate.encounters = EncounterWrapper.buildList(encounterList);

        // Based on Encounter List, Select Encounter record.
        for (EncounterWrapper enw : objPayEstimate.encounters) {
            enw.isSelected = true;
        }

        // Call doNext Method.
        objPayEstimate.doNext();

        // Set variables to generate errors.
        objPayEstimate.amount = '';
        objPayEstimate.cvv = '';
        objPayEstimate.creditCardNumber = '1234';
        objPayEstimate.expirationYear = String.valueOf(System.today().year());
        objPayEstimate.expirationMonth = String.valueOf(System.today().month() - 1);

        System.assertEquals(objPayEstimate.errorMessages.size(), 0, 'Default size of errorMessages is zero.');

        // Call submit method.
        objPayEstimate.submit();

        Test.stopTest();

        // Check system assert.
        List<String> msgList = objPayEstimate.errorMessages;
        System.assert(msgList.size() > 0, 'Expected errorMessages size should greater than zero.');

        Boolean isError = false;
        for (String msg : msgList) {
            if (msg.equals(Constants.PAGE_MESSAGE_AMOUNT_GREATER_THAN_ZERO)) {
                isError = true;
            }
        }
        // Check Amount validation related error.
        System.assert(isError, 'Expected ' + Constants.PAGE_MESSAGE_AMOUNT_GREATER_THAN_ZERO + ' error message.');

        isError = false;
        for (String msg : msgList) {
            if (msg.equals(Constants.PAGE_MESSAGE_CC_NUMBER_12_19_DIGITS)) {
                isError = true;
            }
        }
        // Check Credit Card validation related error.
        System.assert(isError, 'Expected ' + Constants.PAGE_MESSAGE_CC_NUMBER_12_19_DIGITS + ' error message.');
    }
}