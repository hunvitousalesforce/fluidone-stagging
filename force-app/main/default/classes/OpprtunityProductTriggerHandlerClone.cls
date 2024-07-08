public without sharing class OpprtunityProductTriggerHandlerClone {
    
    public static final String SALES_AGP = 'Sales AGP';
    public static final String COMMISSION_AS_AGP = 'Commission as AGP';
    public static OpportunityLineItem oppLIParent;
    //public static List<OpportunityLineItem> lstoppLIParent; // we are handle when we add multi productline item
    public static Boolean runOnce = true; 
	public static Boolean runOnceopliupdate = true; 
    public static Boolean runShareOnce = true;
    public static void deleteChildLI(Map<Id,OpportunityLineItem> mapNewOpp,Map<Id,OpportunityLineItem> mapOldOpp){
        System.debug(' mapOldOpp '+mapOldOpp);                
        List<OpportunityLineItem> lstOPLI = [select id,OpportunityId,Opportunity.recordtype.name 
                                             From OpportunityLineItem
                                             Where Id In :mapOldOpp.keyset()];
        for(OpportunityLineItem objOpp: lstOPLI){ 
            OpportunityLineItem objOPLI = mapOldOpp.get(objOpp.Id);
            System.debug(' objOpp '+objOpp);
            if(objOpp.Opportunity.recordtype.name == 'Child Opportunity')
                objOPLI.AddError('Cannot Delete this record');
        }
    }
    
    public static void deleteParentLI(Map<Id,OpportunityLineItem> oldMap){
        OpportunityLineItem parentOppLI;
        runOnceopliupdate=false;
        if(oldMap.size()>0){
            for(Id key : oldMap.keySet()){
                parentOppLI =  oldMap.get(key);
            }
            if(parentOppLI!=null){
                try{
                    Set<Id> childOpp = new Set<Id>{parentOppLI.Related_Child_Opportunity__c};
                        Set<Id> Product2Ids = new Set<Id>{parentOppLI.Product2Id};
                            
                            OpportunityLineItem childLIupate = [SELECT Id,  Quantity,Recurring_Cost__c,UnitPrice,Sales_Price_Non_Recurring__c,Non_Recurring_Cost__c,Recurring_Dealer_Commission__c,
                                                                Contract_Term__c,OpportunityId,Product2Id FROM OpportunityLineItem WHERE OpportunityId IN: childOpp AND Product2Id IN: Product2Ids];
                    
                    //if(parentOppLI.Overlay_Type__c.equals(SALES_AGP) && childLIupate!=null){
                        childLIupate.Quantity = 1;
                        childLIupate.UnitPrice = 0;
                        childLIupate.Recurring_Cost__c = 0;
                        childLIupate.Non_Recurring_Dealer_Commission__c =0 ;
                        childLIupate.Sales_Price_Non_Recurring__c= 0; 
                        childLIupate.Non_Recurring_Cost__c =0;
                        childLIupate.Recurring_Dealer_Commission__c = 0;
                        childLIupate.Contract_Term__c = '1';    
                        childLIupate.Recurring_Dealer_Commission__c = 0;
                   /* }else if(parentOppLI.Overlay_Type__c.equals(COMMISSION_AS_AGP) && childLIupate!=null){
                        childLIupate.Quantity = parentOppLI.Quantity;
                        childLIupate.UnitPrice = parentOppLI.UnitPrice;
                        childLIupate.Contract_Term__c = parentOppLI.Contract_Term__c;
                        childLIupate.Sales_Price_Non_Recurring__c = parentOppLI.Non_Recurring_Dealer_Commission__c;
                    }*/
                    
                    System.debug('Child Update :'+ childLIupate);
                    if(childLIupate!=null) update childLIupate;                   
                    
                }catch(Exception e){
                    System.debug('@@ Error update child line item :'+e.getMessage()+' Error Line :'+ e.getStackTraceString());
                }
            }            
        }
    }
    
    public static void OpportunityProductOverlyUserUpdate(Map<Id,OpportunityLineItem> newMap,Map<Id,OpportunityLineItem> oldMap){
        System.debug(' newMapc '+newMap);
        System.debug(' oldMap '+oldMap);
        try{
            List<Opportunity> lstOpp = new List<Opportunity>();
            for(Id objoppParent : newMap.keySet()){ 
                System.debug(' OPLI '+newMap.get(objoppParent).Overlay_User__c);
                System.debug(' OPLI '+oldMap.get(objoppParent).Overlay_User__c);
                if(newMap.get(objoppParent).Overlay_User__c!=oldMap.get(objoppParent).Overlay_User__c 
                   && newMap.get(objoppParent).Related_Child_Opportunity__c!=NULL){
                       Opportunity objOpp = new Opportunity();
                       objOpp.Id = newMap.get(objoppParent).Related_Child_Opportunity__c;
                       objOpp.OwnerId = newMap.get(objoppParent).Overlay_User__c;
                       lstOpp.add(objOpp);
                   }
            }
            System.debug(' lstOpp '+lstOpp);
            if(lstOpp.size()>0){
                update lstOpp;
            }
        }catch(Exception ex){
            System.debug('@@ Exception '+ex.getLineNumber()+' - '+ex.getMessage());
        }
    }
    
    public static void OpportunityProductCreation(Map<Id,OpportunityLineItem> newMap,Map<Id,OpportunityLineItem> oldMap){
        try{
            if(runOnce){
                
                runOnce = false; // prevent trigger after updated
                System.debug(' @@ newMap '+newMap.size()+' \n'+newMap);
                Set<Id> parentIds = new Set<Id>();
                List<OpportunityLineItem> lstoppLIParent = new List<OpportunityLineItem> ();
                if(newMap.size()>0){                
                    lstoppLIParent = [SELECT Id, OpportunityId, SortOrder, PricebookEntryId, Product2Id,Product2.Name,  Name, 
                                      Quantity, TotalPrice, UnitPrice, ServiceDate, Description, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, 
                                      SystemModstamp, IsDeleted, LastViewedDate, LastReferencedDate, Competitor__c, Annualised_Gross_Profit__c, Contract_Term__c,
                                      Expected_Annualised_Gross_Profit__c, Non_Recurring_Margin__c, Non_Recurring_Profit2__c, Recurring_Margin__c, 
                                      Recurring_Profit2__c, Sales_Price_Non_Recurring__c, Total_Profit__c, Total_Value__c, Low_Annualised_Gross_Profit__c, 
                                      Q_AGP__c, Recurring_Cost__c, Non_Recurring_Cost__c, Recurring_Dealer_Commission__c, Non_Recurring_Dealer_Commission__c, 
                                      Annual_Dealer_Commission__c, Gross_Upgrade_Margin__c, Recurring_Profit__c, Non_Recurring_Profit__c, Overlay_Type__c,
                                      Overlay_User__c, Overlay_Split_Percentage__c, Create_Overlay_Opportunity__c, Sell_Type__c, 
                                      Related_Child_Opportunity__c 
                                      FROM OpportunityLineItem 
                                      WHERE 
                                      Id IN: newMap.keySet()];
                                     /* AND Create_Overlay_Opportunity__c = true
                                    AND Opportunity.recordtype.name!='Child Opportunity'
                                    AND Related_Child_Opportunity__c =null*/
                } 
                System.debug(' @@ lstoppLIParent '+lstoppLIParent.size()+'\n '+lstoppLIParent);
                List<Opportunity> lstChilOpportunity = new List<Opportunity> ();
                Map<String,OpportunityLineItem> mapupdtLI = new Map<String,OpportunityLineItem> ();
                Set<Id> parentOppIds = new Set<Id>();
                if(lstoppLIParent.size()>0){
                    // expect that we can update or create new with multi productline 
                    for(OpportunityLineItem objoppParent : lstoppLIParent){ // iterate over list and the function will automatically sync create child opp one by one 
                        System.debug(' @@ objoppParent '+objoppParent.Create_Overlay_Opportunity__c+' - '+objoppParent.Related_Child_Opportunity__c);
                        if(objoppParent.Create_Overlay_Opportunity__c == true && objoppParent.Related_Child_Opportunity__c ==null){ //create new child line item base on chil opp
                            Opportunity childOpportunity = createchildOpportunity(objoppParent);
                            mapupdtLI.put(childOpportunity.Name,objoppParent);
                            lstChilOpportunity.add(childOpportunity);
                            parentOppIds.add(objoppParent.Id);
                        }else if(objoppParent.Create_Overlay_Opportunity__c == true && objoppParent.Related_Child_Opportunity__c !=null){ // update  child line item base on child opp(related_opp_c)
                            overlayOpportunityProductupdate(newMap,oldMap);
                        }
                        
                    }
                }
                
                if(lstChilOpportunity.size()>0){
                    insert lstChilOpportunity;
                }
                List<OpportunityLineItem> lstuptoppLIParent = new List<OpportunityLineItem> ();
                for(Opportunity objOpportunity:lstChilOpportunity){
                    OpportunityLineItem opli = mapupdtLI.get(objOpportunity.Name);
                    opli.Related_Child_Opportunity__c = objOpportunity.Id;
                    lstuptoppLIParent.add(opli);
                }
                if(lstuptoppLIParent.size()>0){
                    update lstuptoppLIParent;
                }
                List<OpportunityLineItem> lstoppLIChild = new List<OpportunityLineItem> ();
                for(Opportunity objOpportunity:lstChilOpportunity){
                    OpportunityLineItem opli = mapupdtLI.get(objOpportunity.Name);
                    opli.Related_Child_Opportunity__c = objOpportunity.Id;
                    lstuptoppLIParent.add(opli);
                    lstoppLIChild.add( createchildOpportunityLineItem(mapupdtLI.get(objOpportunity.Name), objOpportunity ));
                    
                }
                if(lstoppLIChild.size()>0){
                    insert lstoppLIChild;
                }
            }  
        }
        catch(Exception ex){
            System.debug('@@ Exception '+Ex.getLineNumber()+' - '+Ex.getMessage());
        }
    }
    public static Opportunity createchildOpportunity(OpportunityLineItem parentOppLI){
        
        RecordType  rt = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive, 
                          CreatedDate, CreatedById, LastModifiedById, LastModifiedDate, SystemModstamp FROM RecordType WHERE DeveloperName='Child_Opportunity' LIMIT 1];
        
        Opportunity masterOpp = [SELECT Id, IsDeleted, AccountId, Account.Name , RecordTypeId, IsPrivate, Name, Description, StageName, Amount,
                                 Probability, ExpectedRevenue, TotalOpportunityQuantity, CloseDate, Type, NextStep, LeadSource, IsClosed, IsWon, 
                                 ForecastCategory, ForecastCategoryName, CampaignId, HasOpportunityLineItem, Pricebook2Id, OwnerId, CreatedDate,
                                 CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, FiscalQuarter, FiscalYear, 
                                 Fiscal, ContactId, LastViewedDate, LastReferencedDate, ContractId, HasOpenActivity, HasOverdueTask, 
                                 LastAmountChangedHistoryId, LastCloseDateChangedHistoryId, Contract_Term__c, DB_Competitor__c, PushCount__c, 
                                 Authority_Comment_Justification__c, Authority_Question__c, Authority_Score__c, Authority__c, Budget__c, 
                                 Comment_Competition__c, Competition_Question__c, Competition_Score__c, Is_BANT_Completed__c, Is_Create_Via_NBA__c, 
                                 Money_Comment_Justification__c, Money_Question__c, Money_Score__c, Need_Comment_Justification__c, Need_Question__c,
                                 Need_Score__c, Need__c, Opportunity_Comment_Justification__c, Opportunity_Question__c, Opportunity_Score__c, 
                                 SCOTSMAN_Indicator__c, SCOTSMAN_Score__c, Size_Comment_Justification__c, Size_Question__c, Size_Score__c,
                                 Solution_Comment__c, Solution_Question__c, Solution_Score__c, Timeline__c, Timescale_Comment_Justification__c,
                                 Timescale_Question__c, Timescale_Score__c, Total_Score_RO__c, LostReasonDetail__c, LostReason__c, 
                                 Signed_Order_Form_attached__c, Forecast_Status__c, Expected_Annualised_Gross_Profit__c, Annualised_Gross_Profit__c,
                                 Total_Contract_Profit__c, Total_Contract_Value__c, Last_Click_UTM_Source__c, Last_Click_UTM_Medium__c,
                                 Last_Click_UTM_Campaign__c, Last_Click_UTM_Content__c, SCT_ID__c, SCT_Created_Date__c, NextActivity__c,
                                 Bid_Clinic_Approval_Required__c, Q_AGP__c, BANT_Completion__c, SCOTSMAN_Completion__c, AA_Number__c,
                                 PSU_Company_ID__c, PSU_Record_ID__c, Count_of_Oppty_LI__c, Count_of_Child_Opportunities__c, 
                                 Parent_Opportunity__c FROM Opportunity WHERE Id =:parentOppLI.OpportunityId];
        
        Opportunity childOpp = new Opportunity();
        childOpp.CloseDate=masterOpp.CloseDate;
        childOpp.StageName=masterOpp.StageName;
        childOpp.RecordTypeId = rt.Id;
        childOpp.Probability = masterOpp.Probability;
        childOpp.ForecastCategoryName = masterOpp.ForecastCategoryName;
        childOpp.Contract_Term__c = masterOpp.Contract_Term__c;
        childOpp.Type = masterOpp.Type;
        childOpp.AccountId = masterOpp.AccountId;
        childOpp.OwnerId = parentOppLI.Overlay_User__c;// overlay user
        childOpp.Parent_Opportunity__c = parentOppLI.OpportunityId;
        childOpp.Name = masterOpp.Name+'-'+parentOppLI.Product2.Name+'-'+parentOppLI.Overlay_Type__c;
        
        childOpp.LostReasonDetail__c = masterOpp.LostReasonDetail__c;
        childOpp.Budget__c = masterOpp.Budget__c;
        childOpp.Need__c = masterOpp.Need__c;
        childOpp.Authority__c = masterOpp.Authority__c;
        childOpp.Timeline__c = masterOpp.Timeline__c;
        return childOpp;
    }
    
    public static OpportunityLineItem createchildOpportunityLineItem(OpportunityLineItem objopli, Opportunity objOpp ){        
        
        OpportunityLineItem objNewopli = new OpportunityLineItem();
        
        if(objopli.Overlay_Type__c.equals(SALES_AGP)){
            objNewopli.PricebookEntryId = objopli.PricebookEntryId; //priceBookList[0].Id;
            objNewopli.Product2Id = objopli.Product2Id;
            objNewopli.Quantity = objopli.Quantity;
            objNewopli.Contract_Term__c = objopli.Contract_Term__c; 
            objNewopli.Sell_Type__c = objopli.Sell_Type__c;
            objNewopli.UnitPrice = objopli.UnitPrice==Null ? Null : (objopli.UnitPrice * objopli.Overlay_Split_Percentage__c)/100;
            objNewopli.Recurring_Cost__c = objopli.Recurring_Cost__c==Null ? Null :(objopli.Recurring_Cost__c * objopli.Overlay_Split_Percentage__c)/100;
            objNewopli.Recurring_Dealer_Commission__c = objopli.Recurring_Dealer_Commission__c==Null ? Null  :(objopli.Recurring_Dealer_Commission__c * objopli.Overlay_Split_Percentage__c)/100;
            objNewopli.Sales_Price_Non_Recurring__c= objopli.Sales_Price_Non_Recurring__c==Null ? Null :(objopli.Sales_Price_Non_Recurring__c * objopli.Overlay_Split_Percentage__c)/100; 
            objNewopli.Non_Recurring_Cost__c = objopli.Non_Recurring_Cost__c==Null ? Null :(objopli.Non_Recurring_Cost__c * objopli.Overlay_Split_Percentage__c)/100;
            objNewopli.Non_Recurring_Dealer_Commission__c = objopli.Non_Recurring_Dealer_Commission__c==Null ? Null :(objopli.Non_Recurring_Dealer_Commission__c * objopli.Overlay_Split_Percentage__c)/100;
            
        }else if(objopli.Overlay_Type__c.equals(COMMISSION_AS_AGP)){
            objNewopli.PricebookEntryId = objopli.PricebookEntryId; 
            objNewopli.Product2Id = objopli.Product2Id;
            objNewopli.Quantity = objopli.Quantity; // 1;//
            objNewopli.Contract_Term__c = objopli.Contract_Term__c; 
            objNewopli.Sell_Type__c = objopli.Sell_Type__c;
            objNewopli.UnitPrice =objopli.Recurring_Dealer_Commission__c; 
            objNewopli.Sales_Price_Non_Recurring__c= objopli.Non_Recurring_Dealer_Commission__c * objopli.Quantity;//objopli.Non_Recurring_Dealer_Commission__c
            //objNewopli.Recurring_Dealer_Commission__c =objopli.Recurring_Dealer_Commission__c; 
            //objNewopli.Non_Recurring_Dealer_Commission__c= objopli.Non_Recurring_Dealer_Commission__c;
            objNewopli.Child_Opportunity_Commission_as_AGP__c = true;        
        }
        
        //objNewopli= objopli.clone(false, false, false, false);
        //objNewopli.Overlay_Split_Percentage__c = objopli.Overlay_Split_Percentage__c; 
        //objNewopli.Overlay_Type__c = objopli.Overlay_Type__c;
        //objNewopli.Overlay_User__c = objopli.Overlay_User__c;
        objNewopli.OpportunityId = objOpp.Id;
        objNewopli.Create_Overlay_Opportunity__c = false;
        objNewopli.Related_Child_Opportunity__c = Null;
        objNewopli.Parent_Annual_Dealer_Commission__c = objopli.Annual_Dealer_Commission__c;
        return objNewopli;
    }
    
    
    public static void overlayOpportunityProductupdate(Map<Id,OpportunityLineItem> newMap,Map<Id,OpportunityLineItem> oldMap){
        if(runOnceopliupdate){
            
            runOnceopliupdate = false; 
            System.debug(' @@ newMap '+newMap.size()+' \n'+newMap);
            Set<Id> parentIds = new Set<Id>();
            List<OpportunityLineItem> lstoppLIParent = new List<OpportunityLineItem> ();
            if(newMap.size()>0){                
                lstoppLIParent = [SELECT Id, OpportunityId, SortOrder, PricebookEntryId, Product2Id,Product2.Name,  Name, 
                                  Quantity, TotalPrice, UnitPrice, ServiceDate, Description, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, 
                                  SystemModstamp, IsDeleted, LastViewedDate, LastReferencedDate, Competitor__c, Annualised_Gross_Profit__c, Contract_Term__c,
                                  Expected_Annualised_Gross_Profit__c, Non_Recurring_Margin__c, Non_Recurring_Profit2__c, Recurring_Margin__c, 
                                  Recurring_Profit2__c, Sales_Price_Non_Recurring__c, Total_Profit__c, Total_Value__c, Low_Annualised_Gross_Profit__c, 
                                  Q_AGP__c, Recurring_Cost__c, Non_Recurring_Cost__c, Recurring_Dealer_Commission__c, Non_Recurring_Dealer_Commission__c, 
                                  Annual_Dealer_Commission__c, Gross_Upgrade_Margin__c, Recurring_Profit__c, Non_Recurring_Profit__c, Overlay_Type__c,
                                  Overlay_User__c, Overlay_Split_Percentage__c, Create_Overlay_Opportunity__c, Sell_Type__c, 
                                  Related_Child_Opportunity__c,Parent_Annual_Dealer_Commission__c 
                                  FROM OpportunityLineItem 
                                  WHERE 
                                  Id IN: newMap.keySet()
                                  AND Create_Overlay_Opportunity__c = true
                                  AND Opportunity.recordtype.name!='Child Opportunity'
                                  AND Related_Child_Opportunity__c !=null];
            } 
            System.debug(' @@ lstoppLIParent '+lstoppLIParent.size()+'\n '+lstoppLIParent);
            
            Set<Id> parentOppIds = new Set<Id>();
            Set<Id> productIds = new Set<Id>();
            Set<Id> relatedOppIds = new Set<Id>();
            Map<Id,OpportunityLineItem> mapOppLI = new Map<Id,OpportunityLineItem> ();

            if(lstoppLIParent.size()>0){
                // expect that we can update or create new with multi productline 
                for(OpportunityLineItem objoppParent : lstoppLIParent){ // iterate over list and the function will automatically sync create child opp one by one 
                    parentOppIds.add(objoppParent.OpportunityId);
                    productIds.add(objoppParent.Product2Id);
                    mapOppLI.put(objoppParent.Product2Id, objoppParent);
                    relatedOppIds.add(objoppParent.Related_Child_Opportunity__c);
                }
            }
            System.debug(' parentOppIds '+parentOppIds.size()+' '+parentOppIds);
            System.debug(' productIds '+productIds.size()+' '+productIds);
            System.debug(' mapOppLI '+mapOppLI.size()+' '+mapOppLI);
            System.debug(' relatedOppsIds'+relatedOppIds.size()+' '+relatedOppIds);

            List<OpportunityLineItem> lstoppupdtLI = [SELECT Id, OpportunityId, SortOrder, PricebookEntryId, Product2Id,Product2.Name,  Name, 
                                                      Quantity, TotalPrice, UnitPrice, ServiceDate, Description, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, 
                                                      SystemModstamp, IsDeleted, LastViewedDate, LastReferencedDate, Competitor__c, Annualised_Gross_Profit__c, Contract_Term__c,
                                                      Expected_Annualised_Gross_Profit__c, Non_Recurring_Margin__c, Non_Recurring_Profit2__c, Recurring_Margin__c, 
                                                      Recurring_Profit2__c, Sales_Price_Non_Recurring__c, Total_Profit__c, Total_Value__c, Low_Annualised_Gross_Profit__c, 
                                                      Q_AGP__c, Recurring_Cost__c, Non_Recurring_Cost__c, Recurring_Dealer_Commission__c, Non_Recurring_Dealer_Commission__c, 
                                                      Annual_Dealer_Commission__c, Gross_Upgrade_Margin__c, Recurring_Profit__c, Non_Recurring_Profit__c, Overlay_Type__c,
                                                      Overlay_User__c, Overlay_Split_Percentage__c, Create_Overlay_Opportunity__c, Sell_Type__c, 
                                                      Related_Child_Opportunity__c 
                                                      FROM OpportunityLineItem 
                                                      WHERE 
                                                      OpportunityId IN: relatedOppIds AND
                                                      Product2Id IN: productIds AND
                                                      Opportunity.Parent_Opportunity__c IN:parentOppIds
                                                      AND Opportunity.recordtype.name='Child Opportunity'];
                                                      
                                                      
            System.debug(' lstoppupdtLI '+lstoppupdtLI.size()+' '+lstoppupdtLI);
            for(OpportunityLineItem childLIupate: lstoppupdtLI){

                if(lstoppLIParent[0].Overlay_Type__c.equals(SALES_AGP)){
                    childLIupate.Quantity = mapOppLI.get(childLIupate.Product2Id).Quantity;
                    childLIupate.Contract_Term__c = mapOppLI.get(childLIupate.Product2Id).Contract_Term__c; 
                    childLIupate.Sell_Type__c = mapOppLI.get(childLIupate.Product2Id).Sell_Type__c;
                    childLIupate.UnitPrice = mapOppLI.get(childLIupate.Product2Id).UnitPrice==Null ? Null : (mapOppLI.get(childLIupate.Product2Id).UnitPrice * mapOppLI.get(childLIupate.Product2Id).Overlay_Split_Percentage__c)/100;
                    childLIupate.Recurring_Cost__c = mapOppLI.get(childLIupate.Product2Id).Recurring_Cost__c==Null ? Null : (mapOppLI.get(childLIupate.Product2Id).Recurring_Cost__c * mapOppLI.get(childLIupate.Product2Id).Overlay_Split_Percentage__c)/100;
                    childLIupate.Recurring_Dealer_Commission__c = mapOppLI.get(childLIupate.Product2Id).Recurring_Dealer_Commission__c==Null ? Null : (mapOppLI.get(childLIupate.Product2Id).Recurring_Dealer_Commission__c * mapOppLI.get(childLIupate.Product2Id).Overlay_Split_Percentage__c)/100;
                    childLIupate.Sales_Price_Non_Recurring__c= mapOppLI.get(childLIupate.Product2Id).Sales_Price_Non_Recurring__c==Null ? Null : (mapOppLI.get(childLIupate.Product2Id).Sales_Price_Non_Recurring__c * mapOppLI.get(childLIupate.Product2Id).Overlay_Split_Percentage__c)/100;
                    childLIupate.Non_Recurring_Cost__c = mapOppLI.get(childLIupate.Product2Id).Non_Recurring_Cost__c==Null ? Null : (mapOppLI.get(childLIupate.Product2Id).Non_Recurring_Cost__c * mapOppLI.get(childLIupate.Product2Id).Overlay_Split_Percentage__c)/100;
                    childLIupate.Non_Recurring_Dealer_Commission__c = mapOppLI.get(childLIupate.Product2Id).Non_Recurring_Dealer_Commission__c==Null ? Null : (mapOppLI.get(childLIupate.Product2Id).Non_Recurring_Dealer_Commission__c * mapOppLI.get(childLIupate.Product2Id).Overlay_Split_Percentage__c)/100;
                    //childLIupate.Overlay_Split_Percentage__c = mapOppLI.get(childLIupate.Product2Id).Overlay_Split_Percentage__c;
                    //childLIupate.Overlay_Type__c = mapOppLI.get(childLIupate.Product2Id).Overlay_Type__c; 
                    childLIupate.Parent_Annual_Dealer_Commission__c = mapOppLI.get(childLIupate.Product2Id).Annual_Dealer_Commission__c;                   
                    childLIupate.Child_Opportunity_Commission_as_AGP__c = false;
                }else if(lstoppLIParent[0].Overlay_Type__c.equals(COMMISSION_AS_AGP)){
                    System.debug('<<<<<<<<<Quantity>>>>>>>>>>>');
                    childLIupate.Quantity = mapOppLI.get(childLIupate.Product2Id).Quantity; // 1;//
                    childLIupate.Contract_Term__c = mapOppLI.get(childLIupate.Product2Id).Contract_Term__c; 
                    childLIupate.Sell_Type__c = mapOppLI.get(childLIupate.Product2Id).Sell_Type__c;
                    childLIupate.UnitPrice =mapOppLI.get(childLIupate.Product2Id).Recurring_Dealer_Commission__c ==Null ? 0 :mapOppLI.get(childLIupate.Product2Id).Recurring_Dealer_Commission__c;
                    childLIupate.Sales_Price_Non_Recurring__c= mapOppLI.get(childLIupate.Product2Id).Non_Recurring_Dealer_Commission__c * mapOppLI.get(childLIupate.Product2Id).Quantity; //mapOppLI.get(childLIupate.Product2Id).Non_Recurring_Dealer_Commission__c;  
                    //childLIupate.Overlay_Type__c = mapOppLI.get(childLIupate.Product2Id).Overlay_Type__c;
                    //childLIupate.Recurring_Dealer_Commission__c =mapOppLI.get(childLIupate.Product2Id).Recurring_Dealer_Commission__c; 
                    //childLIupate.Non_Recurring_Dealer_Commission__c= mapOppLI.get(childLIupate.Product2Id).Non_Recurring_Dealer_Commission__c;
                    childLIupate.Parent_Annual_Dealer_Commission__c = mapOppLI.get(childLIupate.Product2Id).Annual_Dealer_Commission__c;                   
                    childLIupate.Child_Opportunity_Commission_as_AGP__c = true;
                }
            }
            System.debug(' lstoppupdtLI '+lstoppupdtLI.size()+' '+lstoppupdtLI);
            update lstoppupdtLI;
        }
    }
    public static void shareParentLI(Map<Id,OpportunityLineItem> newMap,Map<Id,OpportunityLineItem> oldMap){
        if(runShareOnce){
            try{
                runShareOnce=false;
            Organization org = [Select Id, DefaultAccountAccess, DefaultContactAccess, DefaultLeadAccess, DefaultOpportunityAccess from Organization];
            System.debug(org);
            if(org.DefaultOpportunityAccess=='None' || test.isRunningTest()){ 
                List<SObject> oppShrs  = new List<SObject>();
                System.debug(' newMap '+newMap);
                System.debug(' oldMap '+oldMap);
                if(newMap.size()>0){
                    for(Id key : newMap.keySet()){
                        if(newMap.size()>0 && oldMap!=null){
                            if(newMap.get(key).Overlay_User__c!=null && newMap.get(key).Overlay_User__c!=oldMap.get(key).Overlay_User__c){
                                oppShrs.add(createsharerecord(newMap.get(key).OpportunityId,newMap.get(key).Overlay_User__c));
                            }
                        }
                        else{
                            if(newMap.get(key).Overlay_User__c!=null){
                                oppShrs.add(createsharerecord(newMap.get(key).OpportunityId,newMap.get(key).Overlay_User__c));
                            }
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
    
}// end class