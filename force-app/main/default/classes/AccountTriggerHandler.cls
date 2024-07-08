/**
* @description       : 
* @author            : matthew.rosete@pracedo.com
* @group             : 
* @last modified on  : 09-08-2023
* @last modified by  : marco.tibaldi.ext@pracedo.com
**/
public class AccountTriggerHandler extends TriggerHandler{

    @TestVisible
    private static String accountBody = '';

    // setting the maximum loop count for this trigger
    public AccountTriggerHandler() {
        this.setMaxLoopCount(5); 
        
    }
    
    // context specific methods override
    public override void afterUpdate() {
        sendAccountInformation((Map<Id,Account>)Trigger.newMap, (Map<Id,Account>)Trigger.oldMap);	
        // createXeroAccounts((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
        //Test: AccountTriggerHandlerTest
        createXeroContacts((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }
    
    // method to check for any changes in fields and send information to SAP using future class
    public void sendAccountInformation(Map<Id, Account> newMap, Map<Id, Account> oldMap){
        // for each account create a callout
        for(Account acc : newMap.values()){            
            if (acc.CreateInAccessDimensions__c && oldMap.get(acc.Id).CreateInAccessDimensions__c == false) {
                sendAccountInformationCallout(acc.Id);                                
            }
        }
    }
    
    @future(Callout=true)
    public static void sendAccountInformationCallout(Id accId){
        
        accountBody = '';
        
        // Query the account fields for creating the account model
        Account acc = [
            SELECT                  
            Account_Number__c,
            //HeadOfficeAccountCode 
            Name,
            Account_Type__c,
            comp_house__Company_Number__c,
            VAT_number__c,
            Owner.Email,
            BillingCity, 
            BillingState,
            BillingPostalCode, 
            BillingCountry,
            BillingStreet,              
            PrimaryContact__r.Name,
            Phone,
            Fax,
            Billing_Contact__r.Email
            FROM 
            Account 
            WHERE Id =: accId
        ];
        
        // Create Account object for AccountContactServiceAPI
        DimensionsAccountAPI.Account accountModel = new DimensionsAccountAPI.Account();
        accountModel.Code = acc.Account_Number__c;
        accountModel.RegisteredCompanyName = acc.Name;
        accountModel.CompanyRegistrationNumber = acc.comp_house__Company_Number__c; 
        accountModel.VATNumber = acc.VAT_number__c;
        
        DimensionsAccountAPI.AccountAddress accountAddress = new DimensionsAccountAPI.AccountAddress();
        accountAddress.City = acc.BillingCity;
        accountAddress.County = acc.BillingState;
        accountAddress.Postcode = acc.BillingPostalCode; 
        accountAddress.CountryCode = 'GB';
        
        accountAddress.StreetName = acc.BillingStreet;
        accountModel.Address = accountAddress;
        accountModel.ContactFullName = acc.PrimaryContact__r.Name; 
        accountModel.PhoneNumber = acc.Phone;
        accountModel.Fax = acc.Fax;
        accountModel.InvoiceEmail = acc.Billing_Contact__r.Email;
        accountModel.AccountManagerEmail = acc.Owner.Email; //'mandybaldwin@fluidone.com';
        accountModel.RelationshipType = acc.Account_Type__c;
        
        
        accountBody = JSON.serialize(accountModel);
        	
        
        system.debug('---accountBody---'+accountBody);
        CalloutLog__c log = new CalloutLog__c();
        log.RecordId__c = acc.Id;
        log.RequestBody__c = String.valueOf(accountBody);		
        log.EndpointURL__c = 'https://api.fluidone.com/Dimensions/api/accounts/';
        
        try { 
            HttpResponse createdAccountResponse = DimensionsAccountAPI.createAccountInDimensions(accountBody);			
            log.ResponseCode__c = String.valueOf(createdAccountResponse.getStatusCode());
            log.ResponseMessage__c = createdAccountResponse.getBody();		
            if (createdAccountResponse.getStatusCode() == 200) { 
                Map<String, Object> createdAccount = (Map<String,Object>) JSON.deserializeUntyped(createdAccountResponse.getBody());
                log.SuccessfulCall__c = true;
                TriggerHandler.bypass('AccountTriggerHandler');
                acc.AccessApprovalStatus__c = 'Pending Approval';
                acc.AccessDimensionsId__c = String.valueOf(createdAccount.get('id'));				
                update acc;			
                TriggerHandler.clearBypass('AccountTriggerHandler');			
            }			
        } catch (CalloutException e) {
            System.debug(e);
            log.CalloutException__c = String.valueOf(e);
        } catch (DmlException e) { 
            System.debug(e);
            log.DmlException__c = String.valueOf(e);
        }
        
        insert log;
    }
    
    public static void createXeroAccounts(List<Account> newList, Map<Id, Account> oldMap) {
        System.debug('AccountTriggerHandler.createXeroAccounts ... start');
        List<String> accIds = new List<String>();
        system.debug('newlist' +newlist);
        system.debug('oldMap' +oldMap);
            for (Account acc_i : newList) {
                if (acc_i.CreateInXero__c == true 
                    && acc_i.CreateInXero__c != oldMap.get(acc_i.Id).CreateInXero__c
                    && acc_i.Account_Number__c != null
                    && acc_i.Name != null) {
                        accIds.add(acc_i.Id);		
                    }
            }
        
        System.debug('accIds: size: ' + accIds.size() + ' values: ' + accIds);
        if (!accIds.isEmpty()) {
            System.enqueueJob(new CreateXeroAccountsCallout(accIds));
        }
    }
    
    public static void createXeroContacts(List<Account> newList, Map<Id, Account> oldMap) {
        System.debug('AccountTriggerHandler.createXeroContacts ... start');
        List<String> accIds = new List<String>();
        
        for (Account acc_i : newList) {
            if (acc_i.CreateInXero__c == true 
                && acc_i.CreateInXero__c != oldMap.get(acc_i.Id).CreateInXero__c
                && acc_i.Account_Number__c != null
                && acc_i.Name != null) {
                    accIds.add(acc_i.Id);		
                }
        }
        
        System.debug('accIds: size: ' + accIds.size() + ' values: ' + accIds);
        if (!accIds.isEmpty()) {
            System.enqueueJob(new CreateXeroContactsCallout(accIds));
        }
    }
    
    public class CreateXeroContactsCallout implements Queueable, Database.AllowsCallouts {
        
        private List<String> accountIds;
        
        public createXeroContactsCallout(List<String> accountIds) {
            this.accountIds = accountIds;
        }
        
        public void execute(QueueableContext context) {
            List<Account> accountsToUpdate = new List<Account>();
            List<Account> accounts = [
                SELECT 
                Id,
                Name,
                Account_Number__c,
                PrimaryContact__r.FirstName,
                PrimaryContact__r.LastName,
                PrimaryContact__r.Email, 
                BillingStreet, 
                BillingPostalCode,
                BillingCity,
                comp_house__Company_Number__c,
                VAT_number__c,
                Website				
                FROM 
                Account 
                WHERE 
                Id = :accountIds
            ];
            
            for (Account acc_i : accounts) {
                XeroAPI.ContactsResponse xeroContacts = XeroAPI.createContact(XeroObjects.mapContact(acc_i));
                System.debug('xeroContacts: ' + xeroContacts);
                
                if (xeroContacts.isSuccess) {
                    XeroObjects.XeroContact xeroCont = xeroContacts.Contacts.get(0);
                    
                    accountsToUpdate.add(
                        new Account(
                            Id = acc_i.Id,
                            XeroContactId__c = xeroCont.ContactID
                        )						
                    );
                }
            }
            
            System.debug('accountsToUpdate: size: ' + accountsToUpdate.size() + ' values: ' + accountsToUpdate);
            if (!accountsToUpdate.isEmpty()) { 
                update accountsToUpdate;
                System.debug('AccountTriggerHandler.createXeroContacts ... executed');
            }
        }
    }
    
    public class CreateXeroAccountsCallout implements Queueable, Database.AllowsCallouts {
        
        private List<String> accountIds;
        
        public CreateXeroAccountsCallout(List<String> accountIds) {
            this.accountIds = accountIds;
        }
        
        public void execute(QueueableContext context) {
            List<Account> accountsToUpdate = new List<Account>();
            List<Account> accounts = [SELECT Id
                                      , Name
                                      , Account_Number__c 
                                      FROM Account 
                                      WHERE Id = :accountIds];
            
            for (Account acc_i : accounts) {
                XeroAPI.AccountsResponse xeroAccs = XeroAPI.createAccount(XeroObjects.mapAccount(acc_i, XeroObjects.ACCOUNT_TYPE_SALES));
                System.debug('xeroAccs: ' + xeroAccs);
                
                if (xeroAccs.isSuccess) {
                    XeroObjects.XeroAccount xeroAcc = xeroAccs.accounts.get(0);
                    
                    accountsToUpdate.add(
                        new Account(
                            Id = acc_i.Id,
                            XeroAccountId__c = xeroAcc.AccountID
                        )
                    );
                }
            }
            
            System.debug('accountsToUpdate: size: ' + accountsToUpdate.size() + ' values: ' + accountsToUpdate);
            if (!accountsToUpdate.isEmpty()) { 
                update accountsToUpdate;
                System.debug('AccountTriggerHandler.createXeroAccounts ... executed');
            }
        }
    }
}