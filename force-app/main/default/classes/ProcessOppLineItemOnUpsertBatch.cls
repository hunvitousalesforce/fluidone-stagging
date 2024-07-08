/**
* @description : This batch class is a replacement of the trigger handler OpportunityProductHandler, which
*                was causing Apex CPU Limit due to the long running field calculations.
* @process covered: Set Overlay Fields
*                   Create Child Opportunity
*                   Create Child Opportunity Line Item
*                   Update Closed Opportunity
*                   Update Opportunity Line Item
* @created date  : 18-04-2023
**/
public with sharing class ProcessOppLineItemOnUpsertBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    public RecordType  rt = [SELECT Id, Name, DeveloperName, NamespacePrefix, Description, BusinessProcessId, SobjectType, IsActive, CreatedDate, CreatedById, LastModifiedById, LastModifiedDate, SystemModstamp FROM RecordType WHERE DeveloperName='Child_Opportunity' LIMIT 1];
    public final String SALES_AGP = 'Sales as AGP';
    public final String COMMISSION_AS_AGP = 'Commission as AGP';
    public final String UPSERTED_BY_TRIGGER = 'Trigger';
    public final String UPSERTED_BY_BATCH = 'Batch';
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT AGP_CPQ_QL__c,AGP_CPQ__c,Annualised_Gross_Profit_Total__c,Annualised_Gross_Profit__c,Annual_Dealer_Commission__c,'+
                                        'Category__c,Child_Opportunity_AGP_Text__c,Child_Opportunity_AGP__c,Child_Opportunity_Commission_as_AGP__c,Competitor__c,'+
                                        'Contract_Term__c,CPQ_Line_Item__c,CreatedById,CreatedDate,Create_Overlay_Opportunity__c,Description,Opportunity.StageName,'+
                                        'Expected_Annualised_Gross_Profit__c,Gross_Upgrade_Margin__c,Id,IsDeleted,Is_Inserted_By__c,Is_Updated_By__c,'+
                                        'LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Low_Annualised_Gross_Profit__c,Name,'+
                                        'Non_Recurring_Cost__c,Non_Recurring_Dealer_Commission__c,Non_Recurring_Margin__c,Non_Recurring_Profit2__c,'+
                                        'Non_Recurring_Profit__c,OpportunityId,Overlay_Sales_AGP_QAGP__c,Overlay_Split_Percentage__c,Overlay_Type__c,'+
                                        'Overlay_User__c,Parent_Annual_Dealer_Commission__c,Parent_Bundle__c,Parent_Opportunity_Id__c,Parent_Opportunity_Product__c,'+
                                        'Pillar__c,PricebookEntryId,Product2Id,Product_Family__c,Quantity,Q_AGP_CPQ_Formula__c,Q_AGP_CPQ__c,Q_AGP__c,'+
                                        'Recalculate_Sharing__c,Record_Type__c,Recurring_Cost__c,Recurring_Dealer_Commission__c,Recurring_Margin__c,'+
                                        'Recurring_Profit2__c,Recurring_Profit__c,Recurring__c,Related_Child_Opportunity_Product__c,Related_Child_Opportunity__c,'+
                                        'Sales_AGP_QAGP_Text__c,Sales_Price_Non_Recurring__c,sbaa__ApprovalStatus__c,SBQQ__ParentID__c,SBQQ__QuoteLine__c,'+
                                        'SBQQ__SubscriptionType__c,Sell_Type__c,ServiceDate,SortOrder,SubCategory__c,Subscription_Term__c,SystemModstamp,TotalPrice,'+
                                        'Total_Cost_Formula__c,Total_Cost__c,Total_Profit__c,Total_Value__c,UnitPrice,Unit_Sell__c FROM OpportunityLineItem '+
                                        'WHERE Is_Updated_By__c =: UPSERTED_BY_TRIGGER OR '+
                                              'Is_Inserted_By__c =: UPSERTED_BY_TRIGGER');
    }    

    public void execute(Database.BatchableContext bc, List<OpportunityLineItem> opportunityLineItems){
        system.debug('****opportunityLineItems***'+opportunityLineItems);

        //Collect the Opportunity Line Item records based on the field values
        List<OpportunityLineItem> insertedOpportunityLineItems = new List<OpportunityLineItem>();
        List<OpportunityLineItem> updatedOpportunityLineItems = new List<OpportunityLineItem>();
        List<OpportunityLineItem> parentOpportunityLineItemsWithoutChild = new List<OpportunityLineItem>();
        List<OpportunityLineItem> overLayUserUpdatedOpportunityLineItems = new List<OpportunityLineItem>();

        List<SObject> parentOppLineItemShareList = new List<SObject>();

        Map<Id,OpportunityLineItem> parentOppLineItemToOppLineItemMap = new Map<Id,OpportunityLineItem>();
        for(OpportunityLineItem childOpportunityLineItem : [SELECT Id, Parent_Opportunity_Product__c FROM OpportunityLineItem WHERE Opportunity.Parent_Opportunity__c != null AND Parent_Opportunity_Product__c IN :new Map<Id,OpportunityLineItem>(opportunityLineItems).keySet()]){
            parentOppLineItemToOppLineItemMap.put(childOpportunityLineItem.Parent_Opportunity_Product__c, childOpportunityLineItem);
        }
        System.debug('***parentOppLineItemToOppLineItemMap***'+parentOppLineItemToOppLineItemMap);
        OpportunitiesAndOpportunityLineItems oppAndOpportunityLineItemsUpsertListsFromInsertLogic = new OpportunitiesAndOpportunityLineItems();
        OpportunitiesAndOpportunityLineItems oppAndOpportunityLineItemsUpsertListsFromUpdateLogic = new OpportunitiesAndOpportunityLineItems();
        OpportunitiesAndOpportunityLineItems oppAndOpportunityLineItemsUpdateListsFromUpdateLogic = new OpportunitiesAndOpportunityLineItems();
        for(OpportunityLineItem opportunityLineItem : opportunityLineItems){
            if(opportunityLineItem.Is_Updated_By__c == UPSERTED_BY_TRIGGER){
                updatedOpportunityLineItems.add(opportunityLineItem);
                System.debug('***opportunityLineItem.Id***'+opportunityLineItem.Id);
                if(!parentOppLineItemToOppLineItemMap.containsKey(opportunityLineItem.Id)){
                    System.debug('***parentOppLineItemToOppLineItemMap NOT Contains***');
                    parentOpportunityLineItemsWithoutChild.add(opportunityLineItem);
                }
            }
            else if(opportunityLineItem.Is_Inserted_By__c == UPSERTED_BY_TRIGGER){
                insertedOpportunityLineItems.add(opportunityLineItem);
            }
            
            if(opportunityLineItem.Is_Updated_By__c == UPSERTED_BY_TRIGGER && opportunityLineItem.Recalculate_Sharing__c){
                overLayUserUpdatedOpportunityLineItems.add(opportunityLineItem);
            }
        }

        //Call on AfterUpdate logic - Create/Update Opportunity/Opportunity Line Item
        if(!parentOpportunityLineItemsWithoutChild.isEmpty()){
            oppAndOpportunityLineItemsUpsertListsFromUpdateLogic = createOppAndOLIForMatchingProductFamily(parentOpportunityLineItemsWithoutChild);
        } 
        if(!updatedOpportunityLineItems.isEmpty()){
            oppAndOpportunityLineItemsUpdateListsFromUpdateLogic = updateChildOpportunityLineItem(updatedOpportunityLineItems);
        } 
        //Call on AfterInsert logic - Create/Update Opportunity/Opportunity Line Item & Share records
        if(!insertedOpportunityLineItems.isEmpty()){
            oppAndOpportunityLineItemsUpsertListsFromInsertLogic = createOppAndOLIForMatchingProductFamily(insertedOpportunityLineItems);
            parentOppLineItemShareList.addAll(prepareParentOppLineItemShareRecords(insertedOpportunityLineItems));
        }
        //Call on AfterInsert & Overlay User change logic - Share records
        if(!overLayUserUpdatedOpportunityLineItems.isEmpty()){
            parentOppLineItemShareList.addAll(prepareParentOppLineItemShareRecords(overLayUserUpdatedOpportunityLineItems));
        } 

        Map<Id, OpportunityLineItem>  oppLineItemToUpdateMap = new Map<Id, OpportunityLineItem>();
        oppLineItemToUpdateMap.putAll(oppAndOpportunityLineItemsUpsertListsFromUpdateLogic.opportunityLineItemsToUpdate);
        oppLineItemToUpdateMap.putAll(oppAndOpportunityLineItemsUpdateListsFromUpdateLogic.opportunityLineItemsToUpdate);
        oppLineItemToUpdateMap.putAll(oppAndOpportunityLineItemsUpsertListsFromInsertLogic.opportunityLineItemsToUpdate);
        //Call either on Insert/Update - Set Overlay Fields
        Map<Id, OpportunityLineItem> opportunityLineItemToUpdateMap = setOverlayFieldOnProduct(opportunityLineItems, oppLineItemToUpdateMap);

        Map<Id, Opportunity>  opportunityToUpdateMap = new Map<Id, Opportunity>();
        opportunityToUpdateMap.putAll(oppAndOpportunityLineItemsUpsertListsFromUpdateLogic.opportunitiesToUpdate);
        opportunityToUpdateMap.putAll(oppAndOpportunityLineItemsUpdateListsFromUpdateLogic.opportunitiesToUpdate);
        opportunityToUpdateMap.putAll(oppAndOpportunityLineItemsUpsertListsFromInsertLogic.opportunitiesToUpdate);

        List<OpportunityLineItem> oppLineItemToInsertList = new List<OpportunityLineItem>();
        oppLineItemToInsertList.addAll(oppAndOpportunityLineItemsUpsertListsFromUpdateLogic.opportunityLineItemsToInsert);
        oppLineItemToInsertList.addAll(oppAndOpportunityLineItemsUpsertListsFromInsertLogic.opportunityLineItemsToInsert);


        system.debug('****opportunityLineItemToUpdateMap***'+opportunityLineItemToUpdateMap);
        system.debug('****opportunityToUpdateMap***'+opportunityToUpdateMap);
        system.debug('****oppLineItemToInsertList***'+oppLineItemToInsertList);
        system.debug('****parentOppLineItemShareList***'+parentOppLineItemShareList);
        
        if(!opportunityToUpdateMap.isEmpty()){
            update opportunityToUpdateMap.values();
        }
        if(!opportunityLineItemToUpdateMap.isEmpty()){
            update opportunityLineItemToUpdateMap.values();
        }
        if(!oppLineItemToInsertList.isEmpty()){
            insert oppLineItemToInsertList;
        }
        if(parentOppLineItemShareList.isEmpty()){
            insert parentOppLineItemShareList;
        }
    }

    public void finish(Database.BatchableContext bc){
    }

    //Set Overlay Fields On Opportunity Line Item
    public Map<Id, OpportunityLineItem> setOverlayFieldOnProduct(List<OpportunityLineItem> opportunityLineItems,  Map<Id, OpportunityLineItem> processedOpportunityLineItemMap){
        Map<Id,Opportunity> opportunityMap = getParentOpportunityForGivenOLIMap(opportunityLineItems);
        Map<Id, OpportunityLineItem> updateOpportunityLineItemMap = new Map<Id, OpportunityLineItem>();
        
        for(OpportunityLineItem opportunityLineItem:opportunityLineItems){
            OpportunityLineItem processOpli = processedOpportunityLineItemMap.remove(opportunityLineItem.Id);
            if(processOpli!=null){
                system.debug('***processedOpportunityLineItemMap Contains***'+processOpli.Id);
                processOpli.Is_Inserted_By__c = UPSERTED_BY_BATCH;
                processOpli.Is_Updated_By__c = UPSERTED_BY_BATCH;
                processOpli.Recalculate_Sharing__c = false;
                updateOpportunityLineItemMap.put(processOpli.Id, processOpli);
            }
            else{
                system.debug('***processedOpportunityLineItemMap NOT Contains***'+opportunityLineItem.Id);
                Opportunity parentOpportunity = !opportunityMap.isEmpty() ? opportunityMap.get(opportunityLineItem.OpportunityId) : NULL;
                String overlayUserFieldName = opportunityLineItem.Product_Family__c.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_User__c';
                String overlayTypeFieldName = opportunityLineItem.Product_Family__c.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_Type__c';
                String splitPercentageFieldName = opportunityLineItem.Product_Family__c.replaceAll(' ','_').replaceAll('_&','') + '_Split_Percentage__c';
                
                String overlayUserVal = OpportunityProductHandler.getValueAsString(parentOpportunity, overlayUserFieldName);
                String overlayTypeVal = OpportunityProductHandler.getValueAsString(parentOpportunity, overlayTypeFieldName);
                Object splitPercentageVal = OpportunityProductHandler.getFieldValue(parentOpportunity, splitPercentageFieldName);

                opportunityLineItem.Overlay_Type__c = parentOpportunity != NULL ? overlayTypeVal : opportunityLineItem.Overlay_Type__c;
                opportunityLineItem.Overlay_User__c = parentOpportunity != NULL ? overlayUserVal : opportunityLineItem.Overlay_User__c;
                opportunityLineItem.Overlay_Split_Percentage__c = parentOpportunity != NULL ? (Decimal)splitPercentageVal : opportunityLineItem.Overlay_Split_Percentage__c;

                Decimal salesQAGPText = 0;
                
                if(overlayTypeVal != NULL && overlayTypeVal == SALES_AGP){

                    Decimal recurringProfit;
                    Decimal nonRecurringProfit = (opportunityLineItem.Non_Recurring_Profit__c  * opportunityLineItem.Quantity * 1);
                    Decimal splitPercentage = opportunityLineItem.Overlay_Split_Percentage__c;
                    
                    switch on opportunityLineItem.Contract_Term__c {
                        when '' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 0);                      
                        }
                        when '1' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 1);
                        }
                        when '3' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 3);
                        }
                        when '6' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 6);
                        }
                        when '12' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 12);
                        }
                        when '24' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 12);
                        }
                        when '36' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 12);
                        }
                        when '48' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 12);
                        }
                        when '60' {
                            recurringProfit = (opportunityLineItem.Recurring_Profit__c  * opportunityLineItem.Quantity  * 1 * 12);
                        }
                    }
                    System.debug('recurringProfit>>>>' + recurringProfit);
                    System.debug('nonRecurringProfit>>>>' + nonRecurringProfit);
                    System.debug('splitPercentage>>>>' + splitPercentage);

                    if(recurringProfit == null){
                        recurringProfit = 0;
                    }

                    salesQAGPText = (recurringProfit + nonRecurringProfit) - ((recurringProfit + nonRecurringProfit) * (splitPercentage/100));   
                }
                opportunityLineItem.Sales_AGP_QAGP_Text__c = salesQAGPText;
                opportunityLineItem.Child_Opportunity_AGP_Text__c = salesQAGPText;
                opportunityLineItem.Is_Inserted_By__c = UPSERTED_BY_BATCH;
                opportunityLineItem.Is_Updated_By__c = UPSERTED_BY_BATCH;
                opportunityLineItem.Recalculate_Sharing__c = false;
                updateOpportunityLineItemMap.put(opportunityLineItem.Id, opportunityLineItem);
            }
        }
        //we need to update all process opportunity line items
        if(!processedOpportunityLineItemMap.isEmpty()){
            for(Id opliId:processedOpportunityLineItemMap.keySet()){
                OpportunityLineItem processOpli = processedOpportunityLineItemMap.get(opliId);
                processOpli.Is_Inserted_By__c = UPSERTED_BY_BATCH;
                processOpli.Is_Updated_By__c = UPSERTED_BY_BATCH;
                processOpli.Recalculate_Sharing__c = false;
                updateOpportunityLineItemMap.put(processOpli.Id, processOpli);
            }
        }
        return updateOpportunityLineItemMap;
    }
   
    //[AFTER INSERT] Prepare Opportunity and Opportunity Line Item Insert List based on Product Family
    public OpportunitiesAndOpportunityLineItems createOppAndOLIForMatchingProductFamily(List<OpportunityLineItem> opportunityLineItems){
        system.debug('****createOppAndOLIForMatchingProductFamily***'+opportunityLineItems);
        List<OpportunityLineItem> parentOpportunityLineItems = new List<OpportunityLineItem>();
        OpportunitiesAndOpportunityLineItems oppsAndOppLineItemsToInsert = new OpportunitiesAndOpportunityLineItems();
        Map<Id,Opportunity> opportunityMap = getParentOpportunityForGivenOLIMap(opportunityLineItems);
        system.debug('****opportunityMap***'+opportunityMap);
        Map<Id,OpportunityProductFamiliesAndLineItems> opportunityIdToExistingProducts = getOpportunityIdToExistingProductFamilies(opportunityMap.keySet());      
        system.debug('****opportunityIdToExistingProducts***'+opportunityIdToExistingProducts);
        //Collect Parent Opportunity Line Items
        for(OpportunityLineItem opportunityLineItem : opportunityLineItems){
            if(opportunityLineItem.Parent_Opportunity_Id__c == NULL){   
                parentOpportunityLineItems.add(opportunityLineItem);
            }
        }
        system.debug('****parentOpportunityLineItems***'+parentOpportunityLineItems);
        if(!opportunityMap.isEmpty()){
            List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
            List<OpportunityLineItem> opportunityLineItemsToInsert = new List<OpportunityLineItem>();
            List<Opportunity> opportunityToUpdate = new List<Opportunity>();
            List<OpportunityLineItem> opportunityLineItemsToUpdate = new List<OpportunityLineItem>();
            for(OpportunityLineItem opportunityLineItem : parentOpportunityLineItems){
                system.debug('****parentOpportunityLineItem For Opp Creation Loop***'+opportunityLineItem);
                system.debug('****opportunityLineItem.OpportunityId***'+opportunityLineItem.OpportunityId);
                OpportunityProductFamiliesAndLineItems opItemExisting = opportunityIdToExistingProducts.get(opportunityLineItem.OpportunityId);
                if(opItemExisting!=null){
                    system.debug('****opportunityIdToExistingProducts Contains opportunityLineItem.OpportunityId***');
                    system.debug('****opportunityIdToExistingProducts.get(opportunityLineItem.OpportunityId).productFamiliesToChildOpportunities.keySet()***'+opportunityIdToExistingProducts.get(opportunityLineItem.OpportunityId).productFamiliesToChildOpportunities.keySet());
                    system.debug('****opportunityLineItem.Product_Family__c***'+opportunityLineItem.Product_Family__c);
                    if(!opItemExisting.productFamiliesToChildOpportunities.containsKey(opportunityLineItem.Product_Family__c)){
                        system.debug('****opportunityIdToExistingProducts Not Contains opportunityLineItem.Product_Family__c***');
                        Opportunity opportunity = opportunityMap.get(opportunityLineItem.OpportunityId);
                        system.debug('****opportunity***'+opportunity);
                        Opportunity childOpportunity = createChildOpportunity(opportunity, opportunityLineItem.Product_Family__c);                       
                        system.debug('****childOpportunity***'+childOpportunity);
                        //OpportunityLineItem childOpportunityLineItem = createChildOpportunityLineItem(opportunityLineItem, childOpportunity);
                        if(childOpportunity != null){
                            system.debug('****opportunityLineItem.Product_Family__c Added to opportunityIdToExistingProducts***'+opportunityLineItem.Product_Family__c);
                            opItemExisting.productFamiliesToChildOpportunities.put(opportunityLineItem.Product_Family__c, childOpportunity);
                            //childOpportunity.StageName = childOpportunity.StageName == 'Closed Lost' ? 'Identified Opportunity' : childOpportunity.StageName;
                            opportunitiesToInsert.add(childOpportunity);
                        }
                        /*if(childOpportunityLineItem != null){
                            opportunityLineItemsToInsert.add(childOpportunityLineItem);
                        } */
                    }
                }
            }
            system.debug('****opportunitiesToInsert***'+opportunitiesToInsert);
            //Insertion of Oppurtunity is required here to reference the Id for the Child Opportunity Line Item creation below
            if(!opportunitiesToInsert.isEmpty()){
                insert opportunitiesToInsert;
            }

            for(OpportunityLineItem opportunityLineItem : parentOpportunityLineItems){
                system.debug('****parentOpportunityLineItem For OLI Creation Loop***'+opportunityLineItem);
                system.debug('****opportunityLineItem.OpportunityId***'+opportunityLineItem.OpportunityId);
                OpportunityProductFamiliesAndLineItems opportunityProductFamiliesAndLineItems = opportunityIdToExistingProducts.get(opportunityLineItem.OpportunityId);
                if(opportunityProductFamiliesAndLineItems!=null){
                    system.debug('****opportunityIdToExistingProducts Contains opportunityLineItem.OpportunityId***');
                    system.debug('****opportunityProductFamiliesAndLineItems***'+opportunityProductFamiliesAndLineItems);
                    system.debug('****opportunityLineItem.Product_Family__c***'+opportunityLineItem.Product_Family__c);
                    if(opportunityProductFamiliesAndLineItems.productFamiliesToChildOpportunities.containsKey(opportunityLineItem.Product_Family__c)){
                        system.debug('****opportunityProductFamiliesAndLineItems Contains opportunityLineItem.Product_Family__c***');
                        Opportunity childOpportunity = opportunityProductFamiliesAndLineItems.productFamiliesToChildOpportunities.get(opportunityLineItem.Product_Family__c);
                        system.debug('****childOpportunity***'+childOpportunity);
                        OpportunityLineItem childOpportunityLineItem = createChildOpportunityLineItem(opportunityLineItem, childOpportunity);
                        system.debug('****childOpportunityLineItem***'+childOpportunityLineItem);
                        if(childOpportunityLineItem != null){
                            childOpportunityLineItem.Is_Inserted_By__c = UPSERTED_BY_BATCH;
                            oppsAndOppLineItemsToInsert.opportunityLineItemsToInsert.add(childOpportunityLineItem);
                            if(opportunityLineItem.Opportunity.StageName != 'Closed Lost' && childOpportunity.StageName=='Closed Lost'){
                                //if the child is closed lost and the parent is not, if a product is added in the product family of the child opp, then it should be reopened to Identified opportunity
                                childOpportunity.StageName = 'Identified Opportunity';
                            }
                            oppsAndOppLineItemsToInsert.opportunitiesToUpdate.put(childOpportunity.Id, childOpportunity);
                            system.debug('****oppsAndOppLineItemsToInsert.opportunitiesToUpdate***'+oppsAndOppLineItemsToInsert.opportunitiesToUpdate);
                            if(opportunityLineItem.Id == childOpportunityLineItem.Parent_Opportunity_Product__c){
                                Decimal agp = opportunityLineItem.Annualised_Gross_Profit__c == null ? 0 : opportunityLineItem.Annualised_Gross_Profit__c;
                                Decimal sp = opportunityLineItem.Overlay_Split_Percentage__c == null ? 0 : opportunityLineItem.Overlay_Split_Percentage__c;
                                opportunityLineItem.Child_Opportunity_AGP_Text__c =+ ((agp * sp)/100);
                                oppsAndOppLineItemsToInsert.opportunityLineItemsToUpdate.put(opportunityLineItem.Id, opportunityLineItem);
                                system.debug('****opportunityLineItem.Id Matches to Child OLI Parent***'+oppsAndOppLineItemsToInsert.opportunityLineItemsToUpdate);
                            }
                        } 
                    }
                }
            } 
            system.debug('****oppsAndOppLineItemsToInsert.opportunityLineItemsToInsert***'+oppsAndOppLineItemsToInsert.opportunityLineItemsToInsert);      
        }
        return oppsAndOppLineItemsToInsert;
    }

    //[AFTER UPDATE]Prepare Opportunity and Opportunity Line Item Update List based on Product
    public OpportunitiesAndOpportunityLineItems updateChildOpportunityLineItem(List<OpportunityLineItem> opportunityLineItems){
        system.debug('****updateChildOpportunityLineItem***'+opportunityLineItems);
        Map<Id,Opportunity> opportunityMap = getParentOpportunityForGivenOLIMap(opportunityLineItems);
        List<OpportunityLineItem> childOpportunityLineItemsToUpdate = new List<OpportunityLineItem>();
        List<Opportunity> childOpportunitiesCL = new List<Opportunity>();
        OpportunitiesAndOpportunityLineItems oppsAndOppLineItemsToUpdate = new OpportunitiesAndOpportunityLineItems();
        Map<Id, OpportunityLineItem> parentOppIdToChildOppLineItemMap = new Map<Id, OpportunityLineItem>();
        for(OpportunityLineItem childOpportunityLineItem : getChildOpportunityLineItems(opportunityMap.keySet())){
            parentOppIdToChildOppLineItemMap.put(childOpportunityLineItem.Parent_Opportunity_Product__c , childOpportunityLineItem);
        }

        system.debug('****parentOppIdToChildOppLineItemMap.KeySet***'+parentOppIdToChildOppLineItemMap.keySet());
        for(OpportunityLineItem parentLineItem : opportunityLineItems){
            OpportunityLineItem childOpli = parentOppIdToChildOppLineItemMap.get(parentLineItem.Id);
            if(childOpli!=null && childOpli.Product2Id == parentLineItem.Product2Id){
                system.debug('****parentOppIdToChildOppLineItemMap CONTAINS Opp Id***'+childOpli.Id);
                OpportunityLineItem childOpportunityLineItemToUpdate = createChildOpportunityLineItem(parentLineItem, new Opportunity(Id = childOpli.OpportunityId));
                if(childOpportunityLineItemToUpdate != null){
                    system.debug('****childOpportunityLineItemToUpdate NOT NULL***'+ childOpportunityLineItemToUpdate);
                    childOpportunityLineItemToUpdate.Id = childOpli.Id;
                    //oppsAndOppLineItemsToUpdate.opportunityLineItemsToUpdate.put(parentLineItem.Id, childOpportunityLineItemToUpdate);
                    oppsAndOppLineItemsToUpdate.opportunityLineItemsToUpdate.put(childOpportunityLineItemToUpdate.Id, childOpportunityLineItemToUpdate);
                    if(parentLineItem.Opportunity.StageName != 'Closed Lost' && childOpli.Opportunity.StageName=='Closed Lost'){
                        //if the child is closed lost and the parent is not, if a product is added in the product family of the child opp, then it should be reopened to Identified opportunity
                        oppsAndOppLineItemsToUpdate.opportunitiesToUpdate.put(childOpli.OpportunityId, new Opportunity(Id = childOpli.OpportunityId, StageName = 'Identified Opportunity' ));
                    }
                    
                }
            }
        }
        return oppsAndOppLineItemsToUpdate;
    }

    //Modifed version
    public Map<Id,OpportunityProductFamiliesAndLineItems> getOpportunityIdToExistingProductFamilies(Set<Id> opportunityIds){
        Map<Id,OpportunityProductFamiliesAndLineItems> opportunityIdToExistingProducts = new Map<Id,OpportunityProductFamiliesAndLineItems>();
        for(Opportunity opportunity : [SELECT Id, StageName, (SELECT Id, Name, Product_Family__c, Opportunity.StageName FROM ChildOpportunities__r) FROM Opportunity WHERE Id IN :opportunityIds]){
            
            OpportunityProductFamiliesAndLineItems prodFamilies = new OpportunityProductFamiliesAndLineItems();
            opportunityIdToExistingProducts.put(opportunity.Id, prodFamilies);
            
            for(Opportunity childOpportunity : opportunity.ChildOpportunities__r){
                prodFamilies.productFamiliesToChildOpportunities.put(childOpportunity.Product_Family__c, childOpportunity);
            }
        }
        return opportunityIdToExistingProducts;
    }
    
    public Opportunity createChildOpportunity(Opportunity parentOpportunity, String productFamily){
        Opportunity childOpp = new Opportunity();
        childOpp.CloseDate=parentOpportunity.CloseDate;
        childOpp.StageName=parentOpportunity.StageName;
        childOpp.RecordTypeId = rt.Id;
        childOpp.Probability = parentOpportunity.Probability;
        childOpp.ForecastCategoryName = parentOpportunity.ForecastCategoryName;
        childOpp.Contract_Term__c = parentOpportunity.Contract_Term__c;
        childOpp.Type = parentOpportunity.Type;
        childOpp.AccountId = parentOpportunity.AccountId;
        childOpp.Parent_Opportunity__c = parentOpportunity.Id;
        childOpp.Name = parentOpportunity.Name+' - '+productFamily;
        childOpp.Product_Family__c = productFamily;
        childOpp.LostReasonDetail__c = parentOpportunity.LostReasonDetail__c;
        childOpp.Budget__c = parentOpportunity.Budget__c;
        childOpp.Need__c = parentOpportunity.Need__c;
        childOpp.Authority__c = parentOpportunity.Authority__c;
        childOpp.Timeline__c = parentOpportunity.Timeline__c;
        String overlayUserFieldName = productFamily.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_User__c';
        String overlayTypeFieldName = productFamily.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_Type__c';
        String splitPercentageFieldName = productFamily.replaceAll(' ','_').replaceAll('_&','') + '_Split_Percentage__c';
        String overlayUserVal = OpportunityProductHandler.getValueAsString(parentOpportunity, overlayUserFieldName);
        String overlayTypeVal = OpportunityProductHandler.getValueAsString(parentOpportunity, overlayTypeFieldName);
        Object splitPercentageVal = OpportunityProductHandler.getFieldValue(parentOpportunity, splitPercentageFieldName);
        if(splitPercentageVal!=null && overlayTypeVal!=null && overlayUserVal!=null){
            childOpp.put(overlayUserFieldName, overlayUserVal);
            childOpp.OwnerId = overlayUserVal;
            childOpp.put(overlayTypeFieldName, overlayTypeVal);
            childOpp.put(splitPercentageFieldName, splitPercentageVal);
            return childOpp;
        }
        else{
            return null;
        }      
    }
    public OpportunityLineItem createChildOpportunityLineItem(OpportunityLineItem parentOpportunityLineItem, Opportunity childOpportunity ){
        OpportunityLineItem objNewopli = new OpportunityLineItem();
        //String overlayTypeFieldName = parentOpportunityLineItem.Product_Family__c.replaceAll(' ','_').replaceAll('_&','') + '_Overlay_Type__c';
        String overlayType =  parentOpportunityLineItem.Overlay_Type__c;
        objNewopli.Overlay_Type__c =  parentOpportunityLineItem.Overlay_Type__c;
        objNewopli.Overlay_User__c =  parentOpportunityLineItem.Overlay_User__c;
        Decimal splitPercentage = parentOpportunityLineItem.Overlay_Split_Percentage__c;
        if(overlayType == null){
            return null;
        }
        if(overlayType.equals(SALES_AGP)){
            objNewopli.PricebookEntryId = parentOpportunityLineItem.PricebookEntryId; //priceBookList[0].Id;
            objNewopli.Product2Id = parentOpportunityLineItem.Product2Id;
            objNewopli.Quantity = parentOpportunityLineItem.Quantity;
            objNewopli.Contract_Term__c = parentOpportunityLineItem.Contract_Term__c; 
            objNewopli.Sell_Type__c = parentOpportunityLineItem.Sell_Type__c;
            objNewopli.UnitPrice = parentOpportunityLineItem.UnitPrice==Null ? Null : (parentOpportunityLineItem.UnitPrice * splitPercentage)/100;
            objNewopli.Recurring_Cost__c = parentOpportunityLineItem.Recurring_Cost__c==Null ? Null :(parentOpportunityLineItem.Recurring_Cost__c * splitPercentage)/100;
            objNewopli.Recurring_Dealer_Commission__c = parentOpportunityLineItem.Recurring_Dealer_Commission__c==Null ? Null  :(parentOpportunityLineItem.Recurring_Dealer_Commission__c * splitPercentage)/100;
            objNewopli.Sales_Price_Non_Recurring__c= parentOpportunityLineItem.Sales_Price_Non_Recurring__c==Null ? Null :(parentOpportunityLineItem.Sales_Price_Non_Recurring__c * splitPercentage)/100; 
            objNewopli.Non_Recurring_Cost__c = parentOpportunityLineItem.Non_Recurring_Cost__c==Null ? Null :(parentOpportunityLineItem.Non_Recurring_Cost__c * splitPercentage)/100;
            objNewopli.Non_Recurring_Dealer_Commission__c = parentOpportunityLineItem.Non_Recurring_Dealer_Commission__c==Null ? Null :(parentOpportunityLineItem.Non_Recurring_Dealer_Commission__c * splitPercentage)/100;
            objNewopli.AGP_CPQ__c = parentOpportunityLineItem.AGP_CPQ__c == NULL ? NULL : (parentOpportunityLineItem.AGP_CPQ__c * splitPercentage) /100;
            objNewopli.Unit_Sell__c = parentOpportunityLineItem.Unit_Sell__c == NULL ? NULL : (parentOpportunityLineItem.Unit_Sell__c * splitPercentage) / 100;
        }else if(overlayType.equals(COMMISSION_AS_AGP)){
            objNewopli.PricebookEntryId = parentOpportunityLineItem.PricebookEntryId; 
            objNewopli.Product2Id = parentOpportunityLineItem.Product2Id;
            objNewopli.Quantity = parentOpportunityLineItem.Quantity; // 1;//
            objNewopli.Contract_Term__c = parentOpportunityLineItem.Contract_Term__c; 
            objNewopli.Sell_Type__c = parentOpportunityLineItem.Sell_Type__c;
            objNewopli.UnitPrice =parentOpportunityLineItem.Recurring_Dealer_Commission__c; 
            //when Non_Recurring_Dealer_Commission__c is null then we assume that Sales_Price_Non_Recurring__c is zero
            objNewopli.Sales_Price_Non_Recurring__c= parentOpportunityLineItem.Non_Recurring_Dealer_Commission__c==Null ?0:parentOpportunityLineItem.Non_Recurring_Dealer_Commission__c * parentOpportunityLineItem.Quantity;//parentOpportunityLineItem.Non_Recurring_Dealer_Commission__c
            objNewopli.Child_Opportunity_Commission_as_AGP__c = true;  
            objNewopli.AGP_CPQ__c = parentOpportunityLineItem.AGP_CPQ__c;
            objNewopli.Unit_Sell__c = parentOpportunityLineItem.Unit_Sell__c;
        }
        objNewopli.Recurring__c =  parentOpportunityLineItem.Recurring__c;
        objNewopli.Description = parentOpportunityLineItem.Description;
        objNewopli.OpportunityId = childOpportunity.Id;
        objNewopli.Create_Overlay_Opportunity__c = false;
        objNewopli.Related_Child_Opportunity__c = Null;
        objNewopli.Parent_Opportunity_Product__c = parentOpportunityLineItem.Id;
        objNewopli.Parent_Annual_Dealer_Commission__c = parentOpportunityLineItem.Annual_Dealer_Commission__c;
        objNewopli.CPQ_Line_Item__c = parentOpportunityLineItem.CPQ_Line_Item__c;
        return objNewopli;
    }

    //Apex sharing for Opportunity Line Items
    public List<SObject> prepareParentOppLineItemShareRecords(List<OpportunityLineItem> opportunityLineItems){
        List<SObject> oppShrs  = new List<SObject>();
        Organization org = [Select Id, DefaultAccountAccess, DefaultContactAccess, DefaultLeadAccess, DefaultOpportunityAccess from Organization];
        if(org.DefaultOpportunityAccess == 'None' || test.isRunningTest()){ 
            for(OpportunityLineItem opportunityLineItem : opportunityLineItems){
                if(opportunityLineItem.Overlay_User__c!=null){
                    Map<String, Schema.SObjectType> tokens = Schema.getGlobalDescribe();
                    SObject share = tokens.get('OpportunityShare').newSObject();
                    share.put('OpportunityId', opportunityLineItem.OpportunityId);
                    share.put('UserOrGroupId', opportunityLineItem.Overlay_User__c);
                    share.put('RowCause', '');
                    share.put('OpportunityAccessLevel', 'Read');
                    oppShrs.add(share);
                }
            }
        }
        return oppShrs;
    }

    //Query Parent Opportunity for the given Opportunity Line Items
    public Map<Id,Opportunity> getParentOpportunityForGivenOLIMap(List<OpportunityLineItem> opportunityLineItems){
        Set<Id> opportunityIds = new Set<Id>();
        for(OpportunityLineItem opportunityLineItem:opportunityLineItems){
            opportunityIds.add(opportunityLineItem.OpportunityId);
        }
        return new Map<Id,Opportunity>([SELECT Id, IsDeleted, AccountId, Account.Name , RecordTypeId, IsPrivate, Name, Description, StageName, Amount,
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
                                        Data_Split_Percentage__c, Flex_Space_Split_Percentage__c, IT_Services_Split_Percentage__c, LAN_Wifi_Split_Percentage__c, Mobile_Split_Percentage__c,
                                        Network_Monitoring_Split_Percentage__c, Physical_Install_Split_Percentage__c, Rental_Split_Percentage__c, Security_Split_Percentage__c, UC_Split_Percentage__c,
                                        Voice_Split_Percentage__c, Data_Overlay_Type__c, Data_Overlay_User__c, Flex_Space_Overlay_Type__c, Flex_Space_Overlay_User__c, IT_Services_Overlay_Type__c, 
                                        IT_Services_Overlay_User__c, LAN_Wifi_Overlay_Type__c, LAN_Wifi_Overlay_User__c, Mobile_Overlay_Type__c, Mobile_Overlay_User__c, Network_Monitoring_Overlay_Type__c,
                                        Network_Monitoring_Overlay_User__c, Physical_Install_Overlay_Type__c, Physical_Install_Overlay_User__c, Rental_Overlay_Type__c, Rental_Overlay_User__c, Security_Overlay_Type__c,
                                        Security_Overlay_User__c, UC_Overlay_Type__c, UC_Overlay_User__c, Voice_Overlay_Type__c, Voice_Overlay_User__c,
                                        Parent_Opportunity__c FROM Opportunity WHERE Id IN :opportunityIds AND Parent_Opportunity__c = null]);
    }
    //Query Child Opportunities for the given Parent Opportunity
    public Map<Id,Opportunity> getChildOpportunities(Set<Id> opportunityIds){
        return new Map<Id,Opportunity>([SELECT Id, Parent_Opportunity__c, Product_Family__c, StageName FROM Opportunity WHERE Parent_Opportunity__c IN: opportunityIds]);
    }
    //Query Child Opportunity Line Item for the given Parent Opportunity
    public List<OpportunityLineItem> getChildOpportunityLineItems(Set<Id> opportunityIds){
        return [SELECT Id, Product_Family__c, Product2Id,Parent_Opportunity_Product__c, OpportunityId, Opportunity.Parent_Opportunity__c, Opportunity.StageName FROM OpportunityLineItem WHERE Opportunity.Parent_Opportunity__c IN :opportunityIds];
    }

    //Wrapper class for the Opportunity - Product Family - Child Opportunity Line Item
    public class OpportunityProductFamiliesAndLineItems{
        Map<String,Opportunity> productFamiliesToChildOpportunities;
        List<OpportunityLineItem> opportunityLineItems;

        public OpportunityProductFamiliesAndLineItems(){
            this.productFamiliesToChildOpportunities = new Map<String,Opportunity>();
            this.opportunityLineItems = new List<OpportunityLineItem>();
        }
    }
    //Wrapper class the Opportunities/Opportunity Line Items
    public class OpportunitiesAndOpportunityLineItems{
        List<Opportunity> opportunitiesToInsert;
        List<OpportunityLineItem> opportunityLineItemsToInsert;
        Map<Id, Opportunity> opportunitiesToUpdate;
        Map<Id, OpportunityLineItem> opportunityLineItemsToUpdate;
        public OpportunitiesAndOpportunityLineItems(){
            this.opportunitiesToInsert = new List<Opportunity>();
            this.opportunityLineItemsToInsert = new List<OpportunityLineItem>();
            this.opportunitiesToUpdate = new Map<Id, Opportunity>();
            this.opportunityLineItemsToUpdate = new  Map<Id, OpportunityLineItem>();
        }
    }
    
    
 
}