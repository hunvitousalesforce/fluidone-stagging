@isTest
public class MidasOrderApiServiceMock {
    public class MidasOrderApiServiceOrderMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String body = '';
            if(req.getEndpoint().contains('token/login')){
                body = getRefreshToken();
                res.setBody('{"bearerToken":{},"loginInfo":{},"userId":0}');
                res.setStatusCode(200);
                res.setStatus('OK');
            }else if(req.getEndpoint().contains('token/refresh')){
                body = getRefreshToken();
                res.setBody('{}');
                res.setStatusCode(200);
                res.setStatus('OK');
            }else if(req.getEndpoint().contains('orders?Filters=modifiedOn>=')){
                body = getBody();
                res.setBody(body);
                res.setStatusCode(200);
                res.setStatus('OK');                            
            }else if(req.getEndpoint().contains('orders')){
                body = getOrderData();
                res.setBody(body);
                res.setStatusCode(200);
            }else if(req.getEndpoint().contains('opportunities') && 
                     req.getEndPoint().endsWith('reset')) {
                res.setBody('');
                res.setStatusCode(200);
            	res.setStatus('OK');            
            }else if(req.getEndpoint().contains('opportunities')){
                body = getBody();
                res.setBody(body);
                res.setStatusCode(200);
            	res.setStatus('OK');
            }
            
            res.setHeader('Content-Type', 'application/json');
            
            return res;
        }
    }
    public class MidasOrderApiServiceOrderFailedMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String body = '';
            if(req.getEndpoint().contains('token/login')){
                body = getRefreshToken();
                res.setBody(body);
                res.setStatusCode(401);
            	res.setStatus('Unauthorized');
            }else if(req.getEndpoint().contains('token/refresh')){
                body = getRefreshToken();
                res.setBody(body);
                res.setStatusCode(400);
            	res.setStatus('INVALID');
            }else if(req.getEndpoint().contains('orders?Filters=modifiedOn>=')){
                body = getBody();
                res.setBody(body);
                res.setStatusCode(201);
            	res.setStatus('ERROR');
            }else if(req.getEndpoint().contains('orders')){
                body = getOrderData();
                res.setBody(body);
                res.setStatusCode(201);
            	res.setStatus('ERROR');            
            }else if(req.getEndpoint().contains('opportunities') &&
                    req.getEndpoint().endsWith('reset')) {                
                res.setBody('');
                res.setStatusCode(201);
            	res.setStatus('ERROR');            
            }else if(req.getEndpoint().contains('opportunities')){
                body = getBody();
                res.setBody(body);
                res.setStatusCode(201);
            	res.setStatus('ERROR');
            }
            res.setHeader('Content-Type', 'application/json');
            
            return res;
        }
    }
    
    public class MidasOrderApiServiceOrderPartialFailedMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String body = '';
            if(req.getEndpoint().contains('token/login')){
                body = getRefreshToken();
                res.setBody('{"bearerToken":{},"loginInfo":{},"userId":0}');
                res.setStatusCode(200);
                res.setStatus('OK');
            }else if(req.getEndpoint().contains('token/refresh')){
                body = getRefreshToken();
                res.setBody('{}');
                res.setStatusCode(200);
                res.setStatus('OK');
            }else if(req.getEndpoint().contains('orders?Filters=modifiedOn>=')){
                body = getBody();
                res.setBody(body);
                res.setStatusCode(200);
                res.setStatus('OK');
            }else if(req.getEndpoint().contains('orders')){
                body = getOrderData();
                res.setBody(body);
                res.setStatusCode(200);
                res.setStatus('OK');
            }else if(req.getEndpoint().contains('opportunities') &&
                    req.getEndpoint().endsWith('reset')){                
                res.setBody('');
                res.setStatusCode(401);
            	res.setStatus('Unauthorized');            
            }else if(req.getEndpoint().contains('opportunities')){
                body = getBody();
                res.setBody(body);
                res.setStatusCode(401);
            	res.setStatus('Unauthorized');
            }
            res.setHeader('Content-Type', 'application/json');
            
            return res;
        }
    }
    
    
    public class MidasOrderApiServiceReSendMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            String body = '';
            
            if(req.getEndpoint().contains('opportunities') && 
                     req.getEndPoint().endsWith('reset')) {
                res.setBody('');
                res.setStatusCode(200);
            	res.setStatus('OK');            
            }else if(req.getEndpoint().contains('opportunities')){
                body = getBody();
                res.setBody(body);
                res.setStatusCode(200);
            	res.setStatus('OK');
            }
            
            res.setHeader('Content-Type', 'application/json');
            
            return res;
        }
    }
    
    public class MidasOrderApiServiceResetFailedMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String body = '';

        	if(req.getEndpoint().contains('opportunities') &&
                    req.getEndpoint().endsWith('reset')) {                
                res.setBody('');
                res.setStatusCode(201);
            	res.setStatus('ERROR');                        
            }
            
            res.setHeader('Content-Type', 'application/json');
            
            return res;
        }
    }
    
    public class MidasOrderApiServiceReSendFailedMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String body = '';
                        
            if(req.getEndpoint().contains('opportunities') && 
                     req.getEndPoint().endsWith('reset')) {
                res.setBody('');
                res.setStatusCode(200);
            	res.setStatus('OK');            
            }else if(req.getEndpoint().contains('opportunities')){
                body = getBody();
                res.setBody('');
                res.setStatusCode(201);
            	res.setStatus('ERROR');
            }
            
            res.setHeader('Content-Type', 'application/json');
            
            return res;
        }
    }
    
    
    
    
    
    
    public static String getRefreshToken(){
        String body = '{access_token}';
        return body;
    }
    
    public static String getOrderData(){
        String body = '{'+
                '  \"total\": 14,'+
                '  \"data\": ['+
                '    {'+
                '      \"id\": \"54850cd6-09e1-47ce-a116-df96307c4de4\",'+
                '      \"sourceOrderId\": \"FO10872\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51292\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"LEE010\",'+
                '      \"projectName\": \"S614ED_LEE010_230804_12_BT\",'+
                '      \"billingReference\": \"Project5909\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:06:04.44Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:06:04.457Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"24daad24-e774-40bf-8e14-fa75a0c0e1fc\",'+
                '      \"sourceOrderId\": \"FO10820\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51290\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"IGC010\",'+
                '      \"projectName\": \"BL18PB_IGC010_230622_36_BT_2\",'+
                '      \"billingReference\": \"IGC-P422684\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:06:03.05Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:06:04.3Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"6ea6c096-4415-4718-bf02-51a42bd32ca5\",'+
                '      \"sourceOrderId\": \"FO10867\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51291\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"KTY010\",'+
                '      \"projectName\": \"WD171HZ_KTY010_230802_36_BT\",'+
                '      \"billingReference\": \"-\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:06:03.847Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:06:03.86Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"3edd5edb-8ed0-44da-ad9a-751d828c8767\",'+
                '      \"sourceOrderId\": \"FO10746\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51289\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"KTY010\",'+
                '      \"projectName\": \"CV324LY_KTY010_230717_36_VM\",'+
                '      \"billingReference\": \"-\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:06:02.457Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:06:02.487Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"9a84ada4-2a4c-4c53-9668-45348d1e310e\",'+
                '      \"sourceOrderId\": \"FO10745\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51288\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"KTY010\",'+
                '      \"projectName\": \"CV312GB_KTY010_230717_36_VM\",'+
                '      \"billingReference\": \"-\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:06:01.97Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:06:01.987Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"5c1da660-dbd7-49da-bb3d-d12553979541\",'+
                '      \"sourceOrderId\": \"FO10652\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51286\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"RME010\",'+
                '      \"projectName\": \"RH176EQ_RME010_230626_3_36_SNS\",'+
                '      \"billingReference\": \"Brantridge73106\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:06:00.22Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:06:01.517Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"6e282e99-689e-4454-97f8-55d9539dcfc7\",'+
                '      \"sourceOrderId\": \"FO10711\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51287\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"KTY010\",'+
                '      \"projectName\": \"DN91JZ_KTY010_230703_36_SNS\",'+
                '      \"billingReference\": \"-\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:06:01.143Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:06:01.173Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"582bf55b-8488-42a7-a50b-95a57128ff5c\",'+
                '      \"sourceOrderId\": \"FO10578\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51283\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"RME010\",'+
                '      \"projectName\": \"ML106DP_RME010_230605_12_SNS\",'+
                '      \"billingReference\": \"Strathaven\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:05:57.58Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:06:00.503Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"482ea264-cbbb-43a3-86bf-ef62513dbf56\",'+
                '      \"sourceOrderId\": \"FO10581\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51284\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"SRP011\",'+
                '      \"projectName\": \"CF313RT_FLU010_230605_36_SNS_2\",'+
                '      \"billingReference\": \"202108111027007\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:05:58.503Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:06:00.503Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"4d293714-d716-420d-9fdb-a22b0438f331\",'+
                '      \"sourceOrderId\": \"FO10649\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51285\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"LTA010\",'+
                '      \"projectName\": \"NE14DP_FLU010_230616_36_EX_3\",'+
                '      \"billingReference\": \"n/a\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:05:59.673Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:05:59.707Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"20af6c52-9ff2-4e76-8330-dbd61e1486d3\",'+
                '      \"sourceOrderId\": \"FO10505\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51280\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"RME010\",'+
                '      \"projectName\": \"ST28BS_RME010_230516_36_SNS\",'+
                '      \"billingReference\": \"AbbeyHultonPri10103\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:05:54.08Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:05:59.423Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"39f91185-0743-4a5c-a030-1418cdbb3ba7\",'+
                '      \"sourceOrderId\": \"FO10524\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51281\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"LDW011\",'+
                '      \"projectName\": \"W1G8AB_LDW011_230522_36_VM\",'+
                '      \"billingReference\": \"LRDL2708\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:05:55.877Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:05:59.423Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"ce895c68-742c-471e-8c82-d787e68188c5\",'+
                '      \"sourceOrderId\": \"FO10577\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51282\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"RME010\",'+
                '      \"projectName\": \"ML126AG_RME010_230605_12_SNS\",'+
                '      \"billingReference\": \" Biggar HS\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:05:56.767Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:05:59.423Z\"'+
                '    },'+
                '    {'+
                '      \"id\": \"c08dc0ba-01fe-4264-81da-095811e53261\",'+
                '      \"sourceOrderId\": \"FO10445\",'+
                '      \"salesForceOpportunityId\": null,'+
                '      \"opId\": \"OP51279\",'+
                '      \"status\": \"Pending\",'+
                '      \"customerCode\": \"ATC011\",'+
                '      \"projectName\": \"BT401SX_FLU010_230425_2_36_SNS\",'+
                '      \"billingReference\": \"PO10312\",'+
                '      \"type\": null,'+
                '      \"completedOn\": null,'+
                '      \"createdOn\": \"2023-08-07T16:05:52.157Z\",'+
                '      \"modifiedOn\": \"2023-08-07T16:05:52.517Z\"'+
                '    }'+
                '  ]'+
                '}';
        return body;
    }
    
    public static String getBody(){
        String body = '{'+
		'  \"total\": 16,'+
		'  \"data\": ['+
		'    {'+
		'      \"id\": \"1b506873-f9fc-445b-8451-b8a9cb29accb\",'+
		'      \"sourceOrderId\": \"00000482\",'+
		'      \"salesForceOpportunityId\": \"0062500000YBXK1AAP\",'+
		'      \"opId\": \"OP51270\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"PRE001\",'+
		'      \"projectName\": \"Test Opportunity Midas\",'+
		'      \"billingReference\": \"PO123\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"Henrys\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"W1D 3BU\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-07-24T08:36:25.257Z\",'+
		'      \"modifiedOn\": \"2023-08-08T10:35:19.853Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"ed228049-72c9-4060-826c-1b185dc651e9\",'+
		'      \"sourceOrderId\": \"00000486\",'+
		'      \"salesForceOpportunityId\": \"0062500000YBXSrAAP\",'+
		'      \"opId\": \"OP51293\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"PRE001\",'+
		'      \"projectName\": \"Test Opportunity Midas Advance with extra hardware\",'+
		'      \"billingReference\": \"PO000000\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"Henrys\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"W1D 3BU\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-08T10:22:43.17Z\",'+
		'      \"modifiedOn\": \"2023-08-08T10:22:55.03Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"54850cd6-09e1-47ce-a116-df96307c4de4\",'+
		'      \"sourceOrderId\": \"FO10872\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51292\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"LEE010\",'+
		'      \"projectName\": \"S614ED_LEE010_230804_12_BT\",'+
		'      \"billingReference\": \"Project5909\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"New RotherCare DR\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"S614ED\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:06:04.44Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:06:04.457Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"24daad24-e774-40bf-8e14-fa75a0c0e1fc\",'+
		'      \"sourceOrderId\": \"FO10820\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51290\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"IGC010\",'+
		'      \"projectName\": \"BL18PB_IGC010_230622_36_BT_2\",'+
		'      \"billingReference\": \"IGC-P422684\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"SCHOFIELDS\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"BL18PB\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:06:03.05Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:06:04.3Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"6ea6c096-4415-4718-bf02-51a42bd32ca5\",'+
		'      \"sourceOrderId\": \"FO10867\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51291\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"KTY010\",'+
		'      \"projectName\": \"WD171HZ_KTY010_230802_36_BT\",'+
		'      \"billingReference\": \"-\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"Mindray-WD171HZ\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"WD171HZ\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:06:03.847Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:06:03.86Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"3edd5edb-8ed0-44da-ad9a-751d828c8767\",'+
		'      \"sourceOrderId\": \"FO10746\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51289\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"KTY010\",'+
		'      \"projectName\": \"CV324LY_KTY010_230717_36_VM\",'+
		'      \"billingReference\": \"-\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"Warwick-CV324LY\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"CV324LY\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:06:02.457Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:06:02.487Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"9a84ada4-2a4c-4c53-9668-45348d1e310e\",'+
		'      \"sourceOrderId\": \"FO10745\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51288\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"KTY010\",'+
		'      \"projectName\": \"CV312GB_KTY010_230717_36_VM\",'+
		'      \"billingReference\": \"-\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"Warwick-CV312GB\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"CV312GB\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:06:01.97Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:06:01.987Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"5c1da660-dbd7-49da-bb3d-d12553979541\",'+
		'      \"sourceOrderId\": \"FO10652\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51286\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"RME010\",'+
		'      \"projectName\": \"RH176EQ_RME010_230626_3_36_SNS\",'+
		'      \"billingReference\": \"Brantridge73106\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"Brantridge(73106)\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"RH176EQ\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:06:00.22Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:06:01.517Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"6e282e99-689e-4454-97f8-55d9539dcfc7\",'+
		'      \"sourceOrderId\": \"FO10711\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51287\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"KTY010\",'+
		'      \"projectName\": \"DN91JZ_KTY010_230703_36_SNS\",'+
		'      \"billingReference\": \"-\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"SenseDN91JZ\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"DN91JZ\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:06:01.143Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:06:01.173Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"582bf55b-8488-42a7-a50b-95a57128ff5c\",'+
		'      \"sourceOrderId\": \"FO10578\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51283\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"RME010\",'+
		'      \"projectName\": \"ML106DP_RME010_230605_12_SNS\",'+
		'      \"billingReference\": \"Strathaven\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"Strathaven Academy\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"ML106DP\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:05:57.58Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:06:00.503Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"482ea264-cbbb-43a3-86bf-ef62513dbf56\",'+
		'      \"sourceOrderId\": \"FO10581\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51284\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"SRP011\",'+
		'      \"projectName\": \"CF313RT_FLU010_230605_36_SNS_2\",'+
		'      \"billingReference\": \"202108111027007\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"Mobile Mini Bridgend\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"CF313RT\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:05:58.503Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:06:00.503Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"4d293714-d716-420d-9fdb-a22b0438f331\",'+
		'      \"sourceOrderId\": \"FO10649\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51285\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"LTA010\",'+
		'      \"projectName\": \"NE14DP_FLU010_230616_36_EX_3\",'+
		'      \"billingReference\": \"n/a\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"Samuel Knight \"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"NE14DP\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:05:59.673Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:05:59.707Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"39f91185-0743-4a5c-a030-1418cdbb3ba7\",'+
		'      \"sourceOrderId\": \"FO10524\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51281\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"LDW011\",'+
		'      \"projectName\": \"W1G8AB_LDW011_230522_36_VM\",'+
		'      \"billingReference\": \"LRDL2708\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"RDL Head Office\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"W1G8AB\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:05:55.877Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:05:59.423Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"ce895c68-742c-471e-8c82-d787e68188c5\",'+
		'      \"sourceOrderId\": \"FO10577\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51282\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"RME010\",'+
		'      \"projectName\": \"ML126AG_RME010_230605_12_SNS\",'+
		'      \"billingReference\": \" Biggar HS\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \" Biggar High School\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"ML126AG\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:05:56.767Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:05:59.423Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"20af6c52-9ff2-4e76-8330-dbd61e1486d3\",'+
		'      \"sourceOrderId\": \"FO10505\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51280\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"RME010\",'+
		'      \"projectName\": \"ST28BS_RME010_230516_36_SNS\",'+
		'      \"billingReference\": \"AbbeyHultonPri10103\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"AbbeyHultonPri10103\"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"ST28BS\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:05:54.08Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:05:59.423Z\"'+
		'    },'+
		'    {'+
		'      \"id\": \"c08dc0ba-01fe-4264-81da-095811e53261\",'+
		'      \"sourceOrderId\": \"FO10445\",'+
		'      \"salesForceOpportunityId\": null,'+
		'      \"opId\": \"OP51279\",'+
		'      \"status\": \"Pending\",'+
		'      \"customerCode\": \"ATC011\",'+
		'      \"projectName\": \"BT401SX_FLU010_230425_2_36_SNS\",'+
		'      \"billingReference\": \"PO10312\",'+
		'      \"type\": null,'+
		'      \"siteNames\": ['+
		'        \"Oakland Larne \"'+
		'      ],'+
		'      \"postcodes\": ['+
		'        \"BT401SX\"'+
		'      ],'+
		'      \"completedOn\": null,'+
		'      \"createdOn\": \"2023-08-07T16:05:52.157Z\",'+
		'      \"modifiedOn\": \"2023-08-07T16:05:52.517Z\"'+
		'    }'+
		'  ]'+
		'}';
        return body;
    }
}