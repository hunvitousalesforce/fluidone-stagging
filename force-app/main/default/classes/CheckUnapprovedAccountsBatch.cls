/**
 * @description       : 
 * @author            : matthew.rosete@pracedo.com
 * @group             : 
 * @last modified on  : 04-01-2023
 * @last modified by  : matthew.rosete@pracedo.com
**/
global class CheckUnapprovedAccountsBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    
    global Database.QueryLocator start(Database.BatchableContext BC){ 
        return Database.getQueryLocator([
            SELECT 
				Id, 
            	AccessDimensionsId__c,
                AccessApprovalStatus__c,
                OnStop__c                
            FROM 
            	Account  
            WHERE             	
                CreateInAccessDimensions__c = true AND 
                AccessDimensionsId__c <> null AND
            	AccessApprovalStatus__c != 'Approved'
            	
        ]);
    }
     
    global void execute(Database.BatchableContext BC, List<Account> scope){
        List<CalloutLog__c> logsToCreate  = new List<CalloutLog__c>();                               
        for (Account acc : scope) {                         
            CalloutLog__c log = new CalloutLog__c();
            log.RecordId__c = acc.Id;            
            log.EndpointURL__c = 'https://api.fluidone.com/Dimensions/api/accounts/' + acc.AccessDimensionsId__c;         
            try {                                
                HttpResponse accResponse = DimensionsAccountAPI.getAccountInDimensionsById(acc.AccessDimensionsId__c);
                if (accResponse.getStatusCode() == 200) {
                    Map<String,Object> createdAccount = (Map<String,Object>) JSON.deserializeUntyped(accResponse.getBody());                                                            
                    log.ResponseMessage__c = accResponse.getBody();        
                    if ((Boolean) createdAccount.get('approved') && acc.AccessApprovalStatus__c != 'Approved') { 
                        acc.AccessApprovalStatus__c = 'Approved';
                        acc.Account_Number__c = (String) createdAccount.get('code');
                    } else if ((Boolean) createdAccount.get('onStop') <> acc.OnStop__c) {
                        acc.OnStop__c = (Boolean) createdAccount.get('onStop');
                    }
                }                                            
            } catch (CalloutException e) {                                
                System.debug(e);
                log.CalloutException__c = String.valueOf(e);
                
            } catch (DmlException e) { 
                System.debug(e);
                log.DmlException__c = String.valueOf(e);
            }
            logsToCreate.add(log);            
        }        
        update scope;
        insert logsToCreate;

    }
  
    global void finish(Database.BatchableContext BC){
    }
}