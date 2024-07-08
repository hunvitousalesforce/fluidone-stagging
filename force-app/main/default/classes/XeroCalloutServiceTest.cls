@IsTest 
public class XeroCalloutServiceTest {
    
    @IsTest 
    static void executeCalloutGETTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        XeroCalloutService.executeCallout('GET', 'TestResource');
        Test.stopTest();
    }

    @IsTest 
    static void executeCalloutPUTTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock());
        XeroCalloutService.executeCallout('POST', 'TestResource', '{"test":"Test"}');
        Test.stopTest();
    }

    @IsTest 
    static void executeCalloutGETErrorTest() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new XeroCalloutMock(false));
        XeroCalloutService.executeCallout('GET', 'TestResource');
        Test.stopTest();
    }
}