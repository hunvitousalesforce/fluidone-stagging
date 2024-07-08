@IsTest
public class XeroUtilsTest {
    
    @IsTest 
    static void generateJsonBodyStringWihoutNullTest() {
        String result = XeroUtils.generateJsonBodyStringWihoutNull(new Account(Name = 'testId'));
        System.assert(result.contains('testId'));
    }

    @IsTest 
    static void buildPathByIdTest() {
        String result = XeroUtils.buildPathById('Test', 'TestId');
        System.assertEquals('Test/TestId', result);
    }

    @IsTest 
    static void buildWhereTest() {
        String result = XeroUtils.buildWhere('Test', 'TestParams');
        System.assertEquals('Test?where=TestParams', result);       
    }

    @IsTest 
    static void buildWhereParamsTest1() {
        String result = XeroUtils.buildWhereParams('Test', 'TestValue');
        System.assertEquals('Test=="TestValue"', result);       
    }
    
    @IsTest 
    static void buildWhereParamsTest2() {
        String result = XeroUtils.buildWhereParams('Test', '||', new List<String>{'TestValue1', 'TestValue2'});
        System.assertEquals('Test=="TestValue1"||Test=="TestValue2"', result);
    }

    @IsTest 
    static void parseBody200Test() {
        Account acc = new Account(Name = 'Test');
        HttpResponse response = new HttpResponse();

        response.setStatusCode(200);
        response.setBody(JSON.serialize(acc));

        Account resultAcc = (Account) XeroUtils.parseBody(response, Account.class);
        System.assertEquals('Test', resultAcc.Name);
    }

    @IsTest 
    static void parseBody400Test() {
        Account acc = new Account(Name = 'Test');
        HttpResponse response = new HttpResponse();

        response.setStatusCode(400);
        response.setBody(JSON.serialize(acc));

        Account resultAcc = (Account) XeroUtils.parseBody(response, Account.class);
        System.assertEquals('Test', resultAcc.Name);
    }

    @IsTest 
    static void parseBodyTest() {
        HttpResponse response = new HttpResponse();

        response.setStatusCode(500);
        response.setBody('Test');
        response.setStatus('Error');

        XeroObjects.ApiResponse resultResponse = (XeroObjects.ApiResponse) XeroUtils.parseBody(response, XeroObjects.ApiResponse.class);
        System.assertEquals('Error', resultResponse.Type); 
        System.assertEquals('Test', resultResponse.Message); 
        System.assertEquals(500, resultResponse.ErrorNumber); 
    }
}