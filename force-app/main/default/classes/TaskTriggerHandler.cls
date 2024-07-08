/*
 * Created Date: 26 Dec 2019
 * Author   Mony Nou
 * Description: Trigger for Task object
 * History:
 *      - MN-26122019 - FO-153 
 *      - MN-14012020 - FO-166
 *      - MN-30012020 - FO-186
*/
public with sharing class TaskTriggerHandler {
    
    private static string STATUS_COMPLETED = 'Completed';

    public static Boolean ISRETROUPDATE = false;
    
    //FO-186
    public static void populateNextClosestActivityToOpportunity(Map<Id, Task> newMap, Map<Id, Task> oldMap) {
         
        
        String PROFILE_SYSADMIN = 'System Administrator';
        
        Set<Id> sOpportunity = new Set<Id>();
        
        for (Task t : [SELECT Status, Subject, ActivityDate, WhatId, OwnerId FROM Task WHERE What.Type = 'Opportunity'AND Id IN:newMap.keySet()]) {
            if (ISRETROUPDATE || oldMap == NULL || (t.OwnerId != oldMap.get(t.Id).OwnerId || t.ActivityDate != oldMap.get(t.Id).ActivityDate || t.WhatId != oldMap.get(t.Id).WhatId || t.Status <> oldMap.get(t.Id).Status)) {
                sOpportunity.add(t.WhatId);    
            }
        }
        
        System.debug('### sOpportunity :: ' + sOpportunity); 
        
        if (sOpportunity.isEmpty()) return;
       
        List<Opportunity> lstOpp2update = new List<Opportunity>();
        
        for (Opportunity opp : [SELECT Id, (SELECT Subject, ActivityDate  
                                            FROM Tasks 
                                            WHERE Status <>:STATUS_COMPLETED 
                                            
                                            AND Owner.Profile.Name <>:PROFILE_SYSADMIN ORDER BY ActivityDate ASC NULLS LAST) FROM Opportunity WHERE Id IN:sOpportunity]) {
                                            
            
            opp.NextStep = '';
            opp.NextActivity__c = null;

            for (Task t : opp.Tasks) {   
                System.debug('### t :: ' + t); 
                opp.NextStep = t.Subject;
                opp.NextActivity__c = t.ActivityDate;
                break;
            }

            lstOpp2update.add(opp);
                                                
        }
        
        if (!lstOpp2update.isEmpty()) update lstOpp2update;
    }
    
    //FO-153
    public static void initRecord (List<Task> newList) {

        for (Task t : newList) {
            if (String.isNotBlank(t.Subject) && t.Subject.equals('Take ownership of Lead') 
                && String.valueOf(t.WhoId).startsWith('00Q')
                && String.isBlank(t.Activity_Type__c)
                && String.isBlank(t.Activity_Sub_Type__c)) {
                    
                t.Activity_Type__c = 'Task';
                t.Activity_Sub_Type__c = 'Task';    
            }
        } 

    }
    //MN-14012020 - FO-166
    public static void populateUTM (List<Task> newList, Map<Id,Task> oldMap) {

        for (Task t : newList) {

            
            List<String> lstSTR = new List<String>();
            String split_char = '';

            String str_last_click_source = '';
            String str_last_click_medium = '';
            String str_last_click_campaign = '';
            String str_last_click_content = '';


            if (String.isNotBlank(t.MHCallTracking__MH_Tags__c) && (oldMap == null || oldMap.get(t.Id).MHCallTracking__MH_Tags__c != t.MHCallTracking__MH_Tags__c)) {
                lstSTR = t.MHCallTracking__MH_Tags__c.split('\\|');
                split_char = '=';

                str_last_click_source   = 'utm_source=';
                str_last_click_medium   = 'utm_medium=';
                str_last_click_campaign = 'utm_campaign=';
                str_last_click_content  = 'utm_content=';

            }
            else if (String.isNotBlank(t.Description) && (t.Description.contains('GA Client ID:') 
                                                            || t.Description.contains('Last Click Source:') 
                                                            || t.Description.contains('Last Click Medium:')
                                                            || t.Description.contains('Last Click Campaign:')
                                                            || t.Description.contains('Last Click Content:')) && (oldMap == null || oldMap.get(t.Id).Description != t.Description)) {
                lstSTR = t.Description.split('\n');
                split_char = ':';

                str_last_click_source   = 'Last Click Source:';
                str_last_click_medium   = 'Last Click Medium:';
                str_last_click_campaign = 'Last Click Campaign:';
                str_last_click_content  = 'Last Click Content:';

                
            }

            for (String str : lstSTR) {

                str = str.trim();

                if (String.isBlank(str)) continue;

                String val = ((str.split(split_char).size()>1)?(str.split(split_char))[1]:'').trim();

                System.debug('### str :: ' + str);
                System.debug('### val :: ' + val);

                if (str.startsWith(str_last_click_source)) t.Last_Click_UTM_Source__c = val;
                else if (str.startsWith(str_last_click_medium)) t.Last_Click_UTM_Medium__c = val;
                else if (str.startsWith(str_last_click_campaign)) t.Last_Click_UTM_Campaign__c = val;
                else if (str.startsWith(str_last_click_content)) t.Last_Click_UTM_Content__c = val; 

            }

        }
    }
}