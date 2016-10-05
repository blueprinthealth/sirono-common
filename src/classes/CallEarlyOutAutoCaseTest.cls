/*
* @author Sirono
* @version 1.0.1
* @Date: 08-31-2016
*
* 08-11-2016: Sirono - Tracker # 127398811
* Test Class for the CallEarlyOutAutoCase class
*/

@isTest
private class CallEarlyOutAutoCaseTest {


    public static String cronExp = '0 0 0 15 3 ? 2022';

    static testmethod void test() {
        Test.startTest();

        // Schedule the test job
        String jobId = System.schedule('ScheduleApexClassTest',
                cronExp,
                new CallEarlyOutAutoCase());

        // Get the information from the CronTrigger API object
        CronTrigger ct = [
                SELECT Id, CronExpression, TimesTriggered,
                        NextFireTime
                FROM CronTrigger
                WHERE id = :jobId
        ];

        // Verify the expressions are the same
        System.assertEquals(cronExp,
                ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);


    }
}