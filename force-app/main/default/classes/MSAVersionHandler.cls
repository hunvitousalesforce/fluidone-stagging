public without sharing class MSAVersionHandler {

    public static final String FILE_NAME_CONSTANT_V1 = 'FluidOne MSA v';
    public static final String FILE_NAME_CONSTANT_V2 = 'FluidOne master service agreement v';
    public static final String FILE_NAME_CONSTANT_V3 = 'FluidOne Mast Service Agreement_encrypted v';
    public static final String FILE_NAME_CONSTANT_V4 = 'FluidOne Mast Service Agreement v';


    public static void updateAccountMSAVersionNumber(List<ContentDocumentLink> newList){
        Map<Id,ContentDocumentLink> newMap = new Map<Id,ContentDocumentLink>([SELECT Id, ContentDocument.Title FROM ContentDocumentLink WHERE Id IN :new Map<Id,ContentDocumentLink>(newList).keySet()]);
        Map<Id,Id> accountIdToContentDocumentLinkId = new Map<Id,Id>();
        List<Account> accountsToUpdate = new List<Account>();
        for(ContentDocumentLink contentDocumentLink:newList){
            System.debug('ContentDocument:>>> ' + contentDocumentLink);
            System.debug('contentDocumentLink: '+contentDocumentLink.ContentDocument.FileType);

            Schema.sObjectType entityType = contentDocumentLink.LinkedEntityId.getSObjectType();
            if(entityType == Account.sObjectType){
                accountIdToContentDocumentLinkId.put(contentDocumentLink.LinkedEntityId, contentDocumentLink.Id);
            }
        }
        System.debug('accountIdToContentDocumentLinkId: '+accountIdToContentDocumentLinkId);

        List<Account> accounts = [SELECT Id, Signed_MSA_attached__c, MSA_Version_Number__c FROM Account WHERE Id IN :accountIdToContentDocumentLinkId.keySet()];
        System.debug('accounts: '+accounts);

        for(Account account:accounts){
            
            if(account.Signed_MSA_attached__c){
                try{
                    Decimal versionNumber = getVersionNumberFromContentDocumentLink(newMap.get(accountIdToContentDocumentLinkId.get(account.Id)));
                    System.debug('versionNumber:>>'+ versionNumber);
                    if(versionNumber != null){
                    String versionNumberString = String.valueOf(versionNumber);
                    versionNumberString = versionNumberString.endsWith('0') ? versionNumberString.removeEnd('0') : versionNumberString;
                    System.debug('versionNumberString: '+versionNumberString);
                    versionNumber = Decimal.valueOf(versionNumberString);
                                        System.debug('versionNumber: '+versionNumber);
                    if(account.MSA_Version_Number__c <> null){
                        account.MSA_Version_Number__c = getMaxOfDecimals(versionNumber,account.MSA_Version_Number__c);
                    } else {
                        account.MSA_Version_Number__c = versionNumber;   
                    }
                    accountsToUpdate.add(account);
                }
                }
                catch(Exception e){
                    throw new IncorrectMSAFileNameException('Please ensure the MSA file follows the naming convention: [Account Number] FluidOne MSA v[Version Number]' +e.getMessage() + e.getLineNumber());
                }
            }

            
        }
        System.debug('accountsToUpdate: '+accountsToUpdate);

        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate;
        }
    }

    static Decimal getVersionNumberFromContentDocumentLink(ContentDocumentLink contentDocumentLink){
        String versionNumberString;
        if(contentDocumentLink.ContentDocument.Title.contains(FILE_NAME_CONSTANT_V1)){
            versionNumberString = contentDocumentLink.ContentDocument.Title.split(FILE_NAME_CONSTANT_V1)[1];
        }
        else if(contentDocumentLink.ContentDocument.Title.contains(FILE_NAME_CONSTANT_V2)){
            versionNumberString = contentDocumentLink.ContentDocument.Title.split(FILE_NAME_CONSTANT_V2)[1];
        }
        else if(contentDocumentLink.ContentDocument.Title.contains(FILE_NAME_CONSTANT_V3)){
            versionNumberString = contentDocumentLink.ContentDocument.Title.split(FILE_NAME_CONSTANT_V3)[1];
        }
        else if(contentDocumentLink.ContentDocument.Title.contains(FILE_NAME_CONSTANT_V4)){
            versionNumberString = contentDocumentLink.ContentDocument.Title.split(FILE_NAME_CONSTANT_V4)[1];
        }
        Decimal versionNumber;
        try {
            versionNumber = versionNumberString != null ? Decimal.valueOf(versionNumberString) : null;
        } catch (Exception e) {
            System.debug('Error>>>>' + e.getMessage());
            try {
                String versionNumberStringFinal = versionNumberString.substringBefore(' ');
                versionNumber = Decimal.valueOf(versionNumberStringFinal);

            } catch (Exception e2) {
                System.debug('Error>>>>' + e2.getMessage());
            }

        }
        return versionNumber;
    }
    
    public static Decimal getMaxOfDecimals(Decimal oldValue, Decimal newValue){
        if(newValue.round(System.RoundingMode.FLOOR) == oldValue.round(System.RoundingMode.FLOOR)){
            String oldDecimalPlaces = String.valueOf(oldValue).split('\\.')[1];
            String newDecimalPlaces = String.valueOf(newValue).split('\\.')[1];
            Integer oldNumDecimals = Integer.valueOf(oldDecimalPlaces);
            Integer newNumDecimals = Integer.valueOf(newDecimalPlaces);
            if(oldNumDecimals > newNumDecimals){
                return oldValue;
            }
            else{
                return newValue;
            }


        }
        if(oldValue > newValue ){
            return oldValue;
        }
        return newValue;
        
    }

    public static Decimal getMaximumMSAFileVersionNumber(List<ContentDocumentLink> msaFiles){
        Decimal max = 0;
        for(ContentDocumentLink contentDocumentLink:msaFiles){
            Decimal versionNumber = getVersionNumberFromContentDocumentLink(contentDocumentLink);
            if(versionNumber > max){
                max = versionNumber;
            }
        }
        return max != 0 ? max : null;
    }

    public class IncorrectMSAFileNameException extends Exception {}
}