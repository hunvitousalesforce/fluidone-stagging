@isTest
public class MSAVersionHandlerTest {
    
    @testSetup
    static void setup(){
        Account account = new Account(Name = 'Test', Signed_MSA_attached__c=true);
        insert account;

        ContentVersion contentVersion = new ContentVersion(PathOnClient='HLG010 - FluidOne MSA v1.2.pdf',Title='HLG010 - FluidOne MSA v1.2',VersionData=Blob.valueOf('Test'));
        insert contentVersion;
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(LinkedEntityId=account.Id, ContentDocumentId=contentVersion.ContentDocumentId);
        insert contentDocumentLink;
        
    }
    
    @isTest
    static void insertCDL(){
        Account account = [SELECT Id FROM Account LIMIT 1];
        ContentVersion contentVersion = new ContentVersion(PathOnClient='HLG010 - FluidOne MSA v4.6.pdf',Title='HLG010 - FluidOne MSA v4.6',VersionData=Blob.valueOf('Test 2'));
        insert contentVersion;
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(LinkedEntityId=account.Id, ContentDocumentId=contentVersion.ContentDocumentId);
        insert contentDocumentLink;

        Account updatedAccount = [SELECT Id, MSA_Version_Number__c FROM Account LIMIT 1];
        System.assertEquals(updatedAccount.MSA_Version_Number__c, 4.6);
    }

    @isTest
    static void insertCloseCDL(){
        Account account = [SELECT Id FROM Account LIMIT 1];
        ContentVersion contentVersion = new ContentVersion(PathOnClient='HLG010 - FluidOne MSA v1.26.pdf',Title='HLG010 - FluidOne MSA v1.26',VersionData=Blob.valueOf('Test 2'));
        insert contentVersion;
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(LinkedEntityId=account.Id, ContentDocumentId=contentVersion.ContentDocumentId);
        insert contentDocumentLink;

        Account updatedAccount = [SELECT Id, MSA_Version_Number__c FROM Account LIMIT 1];
        System.assertEquals(updatedAccount.MSA_Version_Number__c, 1.26);
    }



    @isTest
    static void insertDoubleCDL(){
        Account account = [SELECT Id FROM Account LIMIT 1];
        ContentVersion contentVersion = new ContentVersion(PathOnClient='HLG010 - FluidOne MSA v1.26.pdf',Title='HLG010 - FluidOne MSA v1.26',VersionData=Blob.valueOf('Test 2'));
        insert contentVersion;
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(LinkedEntityId=account.Id, ContentDocumentId=contentVersion.ContentDocumentId);
        insert contentDocumentLink;

        Account updatedAccount = [SELECT Id, MSA_Version_Number__c FROM Account LIMIT 1];
        System.assertEquals(updatedAccount.MSA_Version_Number__c, 1.26);
    }

    @isTest
    static void insertIncorrectCDL(){
        Account account = [SELECT Id FROM Account LIMIT 1];
        ContentVersion contentVersion = new ContentVersion(PathOnClient='HLG010 - FluidOne MSAgreement v4.6.pdf',Title='HLG010 - FluidOne MSAgreement v4.6',VersionData=Blob.valueOf('Test 2'));
        insert contentVersion;
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(LinkedEntityId=account.Id, ContentDocumentId=contentVersion.ContentDocumentId);
        
        Test.startTest();
            Database.SaveResult incorrectFileResult = Database.insert(contentDocumentLink, false);
        Test.stopTest();

        System.assert(incorrectFileResult.isSuccess() == true, 'Result should be successful');
        Account updatedAccount = [SELECT Id, MSA_Version_Number__c FROM Account LIMIT 1];
        System.assertEquals(updatedAccount.MSA_Version_Number__c, 1.2);

    }


    @isTest
    static void insertFirstCDL(){
        Account account = [SELECT Id FROM Account LIMIT 1];
        account.MSA_Version_Number__c = null;
        update account;
        ContentVersion contentVersion = new ContentVersion(PathOnClient='HLG010 - FluidOne Mast Service Agreement_encrypted v4.6.pdf',Title='HLG010 - FluidOne Mast Service Agreement_encrypted v4.6',VersionData=Blob.valueOf('Test 2'));
        insert contentVersion;
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(LinkedEntityId=account.Id, ContentDocumentId=contentVersion.ContentDocumentId);
        
        Test.startTest();
            insert contentDocumentLink;
        Test.stopTest();

        Account updatedAccount = [SELECT Id, MSA_Version_Number__c FROM Account LIMIT 1];
        System.assertEquals(updatedAccount.MSA_Version_Number__c, 4.6);
    }

    
    @isTest
    static void runBatch(){
        Account account = [SELECT Id FROM Account LIMIT 1];
        account.MSA_Version_Number__c = null;
        update account;
        // ContentVersion contentVersion = new ContentVersion(PathOnClient='HLG010 - FluidOne master service agreement v4.6.pdf',Title='HLG010 - FluidOne master service agreement v1.2',VersionData=Blob.valueOf('Test 2'));
        // insert contentVersion;
        // contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
        // ContentDocumentLink contentDocumentLink = new ContentDocumentLink(LinkedEntityId=account.Id, ContentDocumentId=contentVersion.ContentDocumentId);
        // insert contentDocumentLink;
		Test.startTest();
        	Id batchJobId = Database.executeBatch(new MSAVersionHandlerBatchable(), 200);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, MSA_Version_Number__c FROM Account LIMIT 1];
        System.assertEquals(1.2, updatedAccount.MSA_Version_Number__c);
    }

}