/*
 * Copyright (c) 2017-present Sirono LLC, All rights reserved
 */

@IsTest
private class WorkWithStatementsControllerTest {

    @IsTest
    static void getStatementsTest() {
        User gtUser = PortalTestUtility.getGuarantorCommunityUser();
        User adminUser = PortalTestUtility.getPortalAdminUser();


        System.runAs(adminUser) {
            Contact guarantorContact = GuarantorService.getPortalGuarantor(gtUser.Id);

            List<Statement__c> statements = new List<Statement__c>();
            for (String stmtDate : RestClientConstants.STATEMENT_DATES) {
                Statement__c statement = PortalTestUtility.generateStatement(guarantorContact.Id);
                statement.Statement_Date__c = Date.parse(stmtDate);
                statements.add(statement);
            }

            insert statements;
        }

        System.runAs(gtUser) {
            Test.setMock(HttpCalloutMock.class, new GuarantorServiceTest.GuarantorRestClientMock());
            Test.startTest();

            List<WorkWithStatementsController.StatementWrapper> statements = WorkWithStatementsController.getStatements();
            Test.stopTest();

            System.assertEquals(5, statements.size(), 'Expected 5 statements');
        }
    }
}