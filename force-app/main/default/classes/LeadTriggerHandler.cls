/*
 * Created Date: 25 Feb 2020
 * Author   Branda
 * Description: Trigger for Lead object
 * History:
 *      - BD-04022020 - FO-193
 *      - BD-25022020 - FO-228
*/

public with sharing class LeadTriggerHandler {
    // FO-228
    public static void UpdateFirstSuccessfulOrAttemptedCall(List<Lead> newList, Map<Id,Lead> oldMap) {
        Id businessHoursId = [select Id,Name from BusinessHours where Name = 'Fluid One Business Hours'].id;
        
        for (Lead l : newList) {
            Datetime startDate = l.CreatedDate ;  
            startDate = Datetime.valueOf(startDate.format('yyyy-MM-dd HH:mm:00'));
            
            if (l.LeadSource == 'Web' && businessHoursId !=null){
                if (l.First_Successful_Call__c !=null && oldMap.get(l.Id).First_Successful_Call__c != l.First_Successful_Call__c) l.Time_to_First_Successful_Call_minutes__c  = calculateCallOfBusinessDays (businessHoursId,startDate, l.First_Successful_Call__c);
                if (l.First_Attempted_Call__c !=null && oldMap.get(l.Id).First_Attempted_Call__c != l.First_Attempted_Call__c) l.Time_to_First_Attempted_Call_minutes__c  = calculateCallOfBusinessDays (businessHoursId, startDate, l.First_Attempted_Call__c);
            } 
        }
        
    }
    
    public static Decimal calculateCallOfBusinessDays(Id businessHoursId, DateTime startDate, DateTime endTime) {
         long tempDiff = BusinessHours.diff( businessHoursId, startDate , endTime); 
         long seconds = tempDiff / 1000;
         long minute_result = seconds / 60;
        
         System.debug('minute_result >> '  +  minute_result);
         return minute_result;
    }
    // FO-193
    public static void populateFirstUTM (List<Lead> newList, Map<Id,Lead> oldMap) {

        for (Lead l : newList) {
            List<String> lstSTR = new List<String>();
            String split_char = '';

            String str_first_click_source = '';
            String str_first_click_medium = '';
            String str_first_click_campaign = '';
            String str_first_click_content = '';
            boolean isMediaHawkTags = false; 
            
            if (String.isNotBlank(l.MHCallTracking__MH_Tags__c) && oldMap == null) { 
                isMediaHawkTags = true;
            }else if(String.isNotBlank(l.MHCallTracking__MH_Tags__c) 
                     && (oldMap != null || oldMap.get(l.Id).MHCallTracking__MH_Tags__c != l.MHCallTracking__MH_Tags__c)){
                isMediaHawkTags = true;
            }
            else if(String.isBlank(l.MHCallTracking__MH_Tags__c)){
                l.First_Click_UTM_Source__c = l.gaconnector_fc_source__c <> null ? l.gaconnector_fc_source__c : null ;
                l.First_Click_UTM_Medium__c = l.gaconnector_fc_medium__c <> null ? l.gaconnector_fc_medium__c : null ;
                l.First_Click_UTM_Campaign__c = l.gaconnector_fc_campaign__c <> null ? l.gaconnector_fc_campaign__c : null;
                l.First_Click_UTM_Content__c = l.gaconnector_fc_content__c <> null ? l.gaconnector_fc_content__c : null;
            }
            
            if(isMediaHawkTags){
                lstSTR = l.MHCallTracking__MH_Tags__c.split('\\|');
                str_first_click_source  = 'utm_source';
                str_first_click_medium  = 'utm_medium';
                str_first_click_campaign = 'utm_campaign';
                str_first_click_content = 'utm_content';

            }
            if(lstSTR.isEmpty()) { return; }
            for (String str : lstSTR) {

                str = str.trim();

                if (String.isBlank(str)) continue;
                List<String> lstSplitChar = str.split('=');
                
                String str0 = lstSplitChar[0].trim();
                String val = lstSplitChar.size() == 1? '': lstSplitChar[1];
                
                if (str0.equals(str_first_click_source)) l.First_Click_UTM_Source__c = val;
                else if (str0.equals(str_first_click_medium)) l.First_Click_UTM_Medium__c = val;
                else if (str0.equals(str_first_click_campaign)) l.First_Click_UTM_Campaign__c = val;
                else if (str0.equals(str_first_click_content)) l.First_Click_UTM_Content__c = val;
            }
        }
    }
    
    
}