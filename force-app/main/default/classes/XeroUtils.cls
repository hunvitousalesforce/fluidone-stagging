//Test: XeroUtilsTest
public with sharing class XeroUtils {

    public static String generateJsonBodyStringWihoutNull(Object obj) {
        return generateJsonBodyString(obj, true);
    }
    
    public static String generateJsonBodyString(Object obj, Boolean suppressApexObjectNulls) {
        String result = JSON.serialize(obj, suppressApexObjectNulls);

        for (String key_i : XeroObjects.SF_TO_XERO_KEYS.keySet()) {
            result = result.replaceAll(key_i, XeroObjects.SF_TO_XERO_KEYS.get(key_i));
        }
        return result;
    }

    public static string buildPathById(String recourceName, String id) {
        return recourceName + '/' + id;
    }

    public static string buildWhere(String recourceName, String params) {
        return recourceName + '?where=' + EncodingUtil.urlEncode(params, 'UTF-8');
    }

    public static String buildWhereParams(String paramName, String value) {
        return buildWhereParams(paramName, null, new List<String>{value});
    }
    
    public static String buildWhereParams(String paramName, String operator, List<String> values) {
        String result = '';
        List<String> paramsWithValue = new List<String>();

        for (String val_i : values) {
            paramsWithValue.add(paramName + '==' + '"' + val_i + '"'); 
        }
        result = String.join(paramsWithValue, operator != null ? operator : '');
        return result;
    }

    public static Object parseBody(HttpResponse httpResponse, System.Type apexType) {
        Object result; 
        String body = httpResponse.getBody();

        for (String key_i : XeroObjects.XERO_TO_SF_KEYS.keySet()) {
            body.replaceAll(key_i, XeroObjects.XERO_TO_SF_KEYS.get(key_i));
        }
        switch on httpResponse.getStatusCode() {
            when 200 {
                result = JSON.deserialize(body, apexType);
            } 
            when 400 {
                result = JSON.deserialize(body, apexType);
            } 
            when else {
                //TODO 403 {"Type":null,"Title":"Forbidden","Status":403,"Detail":"AuthenticationUnsuccessful","Instance":"f74ef874-afb6-45e3-80af-fff98038b8fd","Extensions":{}}
                result = JSON.deserialize(JSON.serialize(XeroObjects.mapErrorResponse(httpResponse)), apexType);
            }
        }
        return result;
    }
}