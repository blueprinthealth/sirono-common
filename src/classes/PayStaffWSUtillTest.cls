/*
 * @author Sirono
 * @version 1.0.1
 * @Date: 05-02-2016
 * @PayStaffWSUtillTest Test Class for the Code Covrege of PayStaffWSUtill Class.
 */

@isTest
private class PayStaffWSUtillTest {

    static testMethod void myUnitTest() {
        PayStaffWSUtill.fetchGuarantorContact('');
        PayStaffWSUtill.fetchGuarantorId(null);
        PayStaffWSUtill.fetchChargeGroupIds(PayStaffWSUtill.fetchChargeGroupList(null));
        PayStaffWSUtill.getCSRFToken();
        PayStaffWSUtill.getJWTToken(PayStaffWSUtill.un, PayStaffWSUtill.pw);
        PayStaffWSUtill.buildChargeGroupsURL('1,2');
        List<SelectOption> expYearOptions = PayStaffWSUtill.expYearOptions;
        List<SelectOption> expMonthOptions = PayStaffWSUtill.expMonthOptions;

        PayStaffWSUtill.TokenAuthResponse tokenAuthResponse = new PayStaffWSUtill.TokenAuthResponse();
        tokenAuthResponse.token = 'testToken';
    }

    static testMethod void testStatementUrlMap() {
        Test.startTest();
        TestUtility.status = 'CREATED';
        TestUtility.statusCode = 200;
        //TestUtility.body = '<input type=\'hidden\' name=\'csrfmiddlewaretoken\' value=\'';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorTest());

        HttpResponse res = PayStaffWSUtill.getStatementUrls('12345');

        String contentType = res.getHeader('Content-Type');
        System.assert(contentType == 'application/json');
        System.assertEquals(200, res.getStatusCode());
        Test.stopTest();
    }

    static testMethod void testStatementUrlMap1() {
        Test.startTest();
        TestUtility.status = 'CREATED';
        TestUtility.statusCode = 200;
        TestUtility.body = 'sirono<input type=\'hidden\' name=\'csrfmiddlewaretoken\' value=\'';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorTest());

        string str = PayStaffWSUtill.getCSRFToken();
        Test.stopTest();
    }

    @isTest
    static void testConvertToDollars() {
        Decimal inputCents = 150;
        Decimal outputDollars = PayStaffWSUtill.convertToDollars(inputCents);
        System.assert('1.5'.equals(outputDollars.format()), 'Expected 1.5, but got ' + outputDollars);
    }

    @isTest
    static void testConvertToDollars1() {
        string inputCents = '100';
        string dollarAmount = PayStaffWSUtill.convertToDollars(inputCents);
        System.assertEquals('1.00', dollarAmount);
    }
    @isTest
    static void testConvertToCents() {
        String inputDollars = '100';
        String outputCents = PayStaffWSUtill.convertToCents(inputDollars);
        System.assert('10000'.equals(outputCents), 'Expected 10000, but got ' + outputCents);
    }

    @isTest
    static void main() {
        Contact con = new Contact(LastName = 'Sirono', Patient_Id__c = 123456);
        insert con;
        PayStaffWSUtill.fetchPatientId(con);
        PayStaffWSUtill.addNoteWSCallout(null, null);
    }

    @isTest
    static void testChargeGroupByAccountSubStatus() {
        Contact patientContact = TestUtility.generatePatientContact();
        insert patientContact;
        Contact guarantorContact = TestUtility.generateGuarantorContact();
        insert guarantorContact;
        Charge_Group__c chargeGroup = TestUtility.generateChargeGroup(guarantorContact.Id, patientContact.Id, 12345);
        insert chargeGroup;
        PayStaffWSUtill.fetchChargeGroupListbyaccountsubstatus(guarantorContact);
        Contact objContact = PayStaffWSUtill.fetchPatientContactWithCGConstraints(patientContact.Id);

        System.assertEquals(objContact.Id, patientContact.Id);
    }

}