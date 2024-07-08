/*
 * Created Date: 29 March 2021
 * Author   Ranin
 * Description: Trigger for Opportunity object
 * History:
 * FO-483 
*/
public without sharing class OpportunityTriggerHandler {
    public static Boolean runShareOnce = true;
    public static Boolean runOnce = true;
    public static Boolean runOnceCount = true; 
    public static Set<Id> parentIds = new Set<Id>();
    public static Opportunity parentOpp; 
    public static List<Opportunity> lstChildOpp; 


    public static void shareParentLI(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap){
        if(runShareOnce){
            try{
                runShareOnce=false;
                Organization org = [Select Id, DefaultAccountAccess, DefaultContactAccess, DefaultLeadAccess, DefaultOpportunityAccess from Organization];
                System.debug(org);
                if(org.DefaultOpportunityAccess=='None' || test.isRunningTest()){                    
                    System.debug('@@ runShareOnce '+runShareOnce);
                    RecordType  rt = [SELECT Id, Name, DeveloperName  FROM RecordType WHERE DeveloperName='Child_Opportunity' LIMIT 1];
                    
                    List<SObject> oppShrs  = new List<SObject>();
                    System.debug(' newMap '+newMap);
                    System.debug(' oldMap '+oldMap);
                    
                    if(newMap.size()>0){
                        List<Opportunity> lstOpp = [Select Id,Name,Recordtypeid,Parent_Opportunity__c,Parent_Opportunity__r.name,
                                                    Parent_Opportunity__r.ownerID,Parent_Opportunity__r.Owner.Name 
                                                    FROM Opportunity 
                                                    WHERE 
                                                    Id In :newMap.keyset()];
                        for(Opportunity objOpp : lstOpp){                    
                            if(objOpp.recordtypeid==rt.Id && objOpp.Parent_Opportunity__r!=NULL){
                                oppShrs.add(createsharerecord(objOpp.Id,objOpp.Parent_Opportunity__r.ownerID));                        
                            }
                        }
                    }            
                    if(oppShrs.size()>0){
                        Insert oppShrs; 
                    }
                }
            }
            catch(exception ex){
                System.debug('@@ Error '+ex.getLineNumber()+' - '+ex.getMessage());
            }
        }
    }
    
    public static SObject createsharerecord(String OpportunityId,String UserOrGroupId){
        System.debug(' Share Record Creation ');
        
        Map<String, Schema.SObjectType> tokens = Schema.getGlobalDescribe();
        SObject share = tokens.get('OpportunityShare').newSObject();
        share.put('OpportunityId', OpportunityId);
        share.put('UserOrGroupId', UserOrGroupId);
        share.put('RowCause', '');
        share.put('OpportunityAccessLevel', 'Read');
        
        /*OpportunityShare oppShr = new OpportunityShare();            
        oppShr.OpportunityId = OpportunityId;            
        oppShr.UserOrGroupId = UserOrGroupId;            
        oppShr.OpportunityAccessLevel = 'Read'; 
        oppShr.RowCause = '';*/
        System.debug(' Record Creation '+share);
        return share;
    }
    
    public static void restrictChildOpportunity(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap){
        try{
        //'AR' run from BATCH
        User u = [Select Alias From User WHERE Id = :UserInfo.getUserId()];
        if(runOnce && (Test.isRunningTest() ||u.Alias != 'AR')){
        RecordType  rt = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive, 
                                CreatedDate, CreatedById, LastModifiedById, LastModifiedDate, SystemModstamp FROM RecordType WHERE DeveloperName='Child_Opportunity' LIMIT 1];
            
        for(Id key : newMap.keySet()){
            if(newMap.get(key).recordtypeID == rt.Id){
                if(newMap.get(key).Name!=oldMap.get(key).Name){
                    newMap.get(key).AddError('This Recorde is Restricted ');
                }
                else if(newMap.get(key).StageName!=oldMap.get(key).StageName){
                    //updated to allow Closed Lost (CPQ Changes)
                    if(newMap.get(key).StageName <> 'Closed Lost' && !(oldMap.get(key).StageName == 'Closed Lost' && newMap.get(key).StageName == 'Identified Opportunity')){
                        newMap.get(key).AddError('This Recorde is Restricted ');
                    }
                }
                else if(newMap.get(key).CloseDate!=oldMap.get(key).CloseDate){
                    newMap.get(key).AddError('This Recorde is Restricted ');
                }
            }
        }
        }
        }catch(Exception ex){
            System.debug('@@ Exception '+ex.getLineNumber()+' - '+ex.getMessage());
        }
    }
    
    public static void updateOpportunity(Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap){

        if(runOnce){

            runOnce = false; // prevent trigger after updated

            if(newMap.size()>0){

                for(Id key : newMap.keySet()){
                    parentIds.add(key); 
                    parentOpp = newMap.get(key);
                }   

                lstChildOpp = [SELECT Id,StageName,Parent_Opportunity__c, Name FROM Opportunity WHERE Parent_Opportunity__c=:parentIds];

                if(lstChildOpp.size()>0){ 
                    try{
                        for(Opportunity opp :lstChildOpp){
                            ChildOpportunity objChild = new ChildOpportunity(parentOpp,opp,true);
                            System.debug('<<<<<<HERE>>>>>>');
                            objChild.up();
                        }
                    }catch(Exception e){
                        System.debug('@@ Error :'+ e.getMessage() +' >>Line :'+e.getStackTraceString());
    
                    }
                }
            }
        }
    }
    public static void deleteOpportunity(Map<Id,Opportunity> oldMap){
        if(oldMap.size()>0){

            for(Id key : oldMap.keySet()){
                parentIds.add(key); 
                parentOpp = oldMap.get(key);
            }
            lstChildOpp = [SELECT Id,StageName,Parent_Opportunity__c, Name FROM Opportunity WHERE Parent_Opportunity__c=:parentIds];
            try{
                ChildOpportunity objChild = new ChildOpportunity(parentOpp,lstChildOpp);
                objChild.del();
            }catch(Exception e){
                System.debug('@@ Error :'+ e.getMessage() +' >>Line :'+e.getStackTraceString());
            }
        }
    }

    public static void restrictdeleteOpportunity(List<Opportunity> lstNewOpp,List<Opportunity> lstOldOpp){
        System.debug(' Opportunity '+lstNewOpp+'\n lstOldOpp '+lstOldOpp);
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        system.debug('ProfileName'+profileName);

        for(Opportunity objOpp: lstOldOpp){        
            
            if(!Test.isRunningTest() && profileName!='System Administrator' && profileName!='Development Admin'  )
            objOpp.AddError('The parent opportunity cannot be deleted until the child opportunities are deleted.');
            
       
        }
    }
    
    public static void updateparentCount(Map<Id,Opportunity> newMap){
        if(runOnceCount){            
            runOnceCount = false;
            System.debug(' updateparentCount - \n'+newMap);
            Set<Id> parentOppIds = new Set<Id>();
            for(Id key : newMap.keySet()){
                parentOppIds.add(newMap.get(key).Parent_Opportunity__c); 
            }
            Map<Id,Integer> mapOpp = New Map<Id,Integer> ();
            List<Opportunity> lstOpp = [select id,name,Count_of_Child_Opportunities__c,recordtype.name,Parent_Opportunity__c from Opportunity where Parent_Opportunity__c =: parentOppIds and recordtype.name='Child Opportunity'];
            System.debug(' lstOpp '+lstOpp);
            for(Opportunity objOpp:lstOpp){
                if(mapOpp.containskey(objOpp.Parent_Opportunity__c)){
                    Integer updatedcount =  mapOpp.get(objOpp.Parent_Opportunity__c) + 1 ; 
                    mapOpp.put(objOpp.Parent_Opportunity__c,updatedcount);
                }else{
                    Integer updatedcount =  objOpp.Count_of_Child_Opportunities__c==NULL ? 1 : Integer.valueOf(objOpp.Count_of_Child_Opportunities__c) + 1 ;
                    mapOpp.put(objOpp.Parent_Opportunity__c,updatedcount);
                }                
                
            }
            System.debug(' mapOpp '+mapOpp);
            List<Opportunity> lstUpdOpp = new List<Opportunity> ();
            if(mapOpp.size()>0){
                for(Id opportunityId:mapOpp.keySet()){
                    lstUpdOpp.add(new opportunity(id=opportunityId,Count_of_Child_Opportunities__c = mapOpp.get(opportunityId)));
                }
            }
            if(lstUpdOpp.size()>0){
                System.debug(' lstUpdOpp '+lstUpdOpp);
                update lstUpdOpp;
            }
        }
    }
    
    public class ChildOpportunity{

        public List<Opportunity> lstChild;
        public Opportunity parentOpp;
        public Opportunity  childOpps;
        public Boolean isDone = false;
        public ChildOpportunity(){
        }
        public ChildOpportunity(Opportunity parentOpp,Opportunity childOpps, Boolean isDone){
            this.parentOpp = parentOpp;
            this.childOpps = childOpps;
            this.isDone = isDone;
        }
        public ChildOpportunity(Opportunity parentOpp,List<Opportunity> lstChild){
            this.parentOpp = parentOpp;
            this.lstChild = lstChild;
        }
        public void del(){
            if(lstChild.size()>0){
                parentOpp.addError('This record has child Opportunity, Please delete child first!');
            }else{
                if(parentOpp!=null) delete parentOpp;
            }

        }
        public void up(){
            if(isDone){
                isDone = false; // prevent update again 
                
               /* OpportunityLineItem oLineItem = null;//[SELECT Id, Overlay_User__c,Overlay_Type__c,Related_Child_Opportunity__c FROM OpportunityLineItem WHERE Related_Child_Opportunity__c =:childOpps.Id];
            
                Opportunity parent  = [SELECT Id,OwnerId,LostReasonDetail__c,LostReason__c,CloseDate,Forecast_Status__c,Probability,StageName,Parent_Opportunity__c, Name ,Contract_Term__c, Budget__c,Need__c,Authority__c,Timeline__c,
                                    (SELECT Id,Overlay_User__c,Overlay_Type__c,Related_Child_Opportunity__c,Product2.Name FROM OpportunityLineItems) 
                                    FROM Opportunity WHERE Id=:parentOpp.Id];     
                
                if(parent.OpportunityLineItems!=null){
                    for(OpportunityLineItem o: parent.OpportunityLineItems){

                        if(o.Related_Child_Opportunity__c!=null && o.Related_Child_Opportunity__c == childOpps.Id){
                            oLineItem = o;
                        }
                    }
                }//&& oLineItem!=null*/
                if(parentOpp!=null && childOpps!=null){
                    String[] parts =  childOpps.Name.split('-');
                    String productFamily = parts[parts.size()-1].trim();//last index is product family
                    String prefix = productFamily.replaceAll(' ','_').replaceAll('_&','') ;
                    String overlayUserFieldName = prefix + '_Overlay_User__c';
                    String splitPercentageFieldName = prefix+'_Split_Percentage__c';
                    // if(oLineItem!=null){
                    // childOpps.Name = parentOpp.Name+'-'+oLineItem.Overlay_Type__c+'-'+oLineItem.Product2.Name;
                    // System.debug('childOppsName'+childOpps.Name);                    
                    // childOpps.OwnerId = oLineItem.Overlay_User__c;
                    // }
                    childOpps.StageName = parentOpp.StageName;
                    childOpps.Probability = parentOpp.Probability;
                    childOpps.Forecast_Status__c = parentOpp.Forecast_Status__c;
                    childOpps.CloseDate = parentOpp.CloseDate;
                    childOpps.LostReason__c = parentOpp.LostReason__c;
                    childOpps.LostReasonDetail__c = parentOpp.LostReasonDetail__c;
                    childOpps.Type = parentOpp.Type; 
                    childOpps.Contract_Term__c = parentOpp.Contract_Term__c;
                    childOpps.Budget__c = parentOpp.Budget__c;
                    childOpps.Need__c = parentOpp.Need__c;
                    childOpps.Authority__c = parentOpp.Authority__c;
                    childOpps.Timeline__c = parentOpp.Timeline__c;
                    childOpps.Signed_Order_Form_attached__c = parentOpp.Signed_Order_Form_attached__c;
                    try{
                        childOpps.OwnerId  = (Id)parentOpp.get(overlayUserFieldName);
                        //we should update the overlay user on child too
                        childOpps.put(overlayUserFieldName, childOpps.OwnerId);
                        childOpps.put(splitPercentageFieldName, parentOpp.get(splitPercentageFieldName));
                    }catch(Exception e){
                        //nothing todo because the opportunity not created by batch
                    }
                    
                    update childOpps;
                   
                }
            }

        }


    }

}