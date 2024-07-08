/*
 * Created Date : 25 Feb 2020
 * Author       : Branda
 * Description  : Test class for LeadTriggerHandler.cls
*/
@isTest
public class LeadTriggerTest {

    @isTest static void test_updateFirstSuccessfulCall() {
        Id businessHoursId = [select Id,Name from BusinessHours where Name = 'Fluid One Business Hours'].id;
        Lead l = new Lead();
        l.FirstName = 'Test Lead001';
        l.LastName  = 'Test Update First Successful Call';
        l.LeadSource = 'Web';
        l.Company = 'ABC' ;
        //l.First_Successful_Call__c = datetime.newInstance(2014, 9, 15, 9, 10, 10);
        insert l;
        Datetime tesdate = datetime.newInstance(2014, 9, 15, 9, 10, 10);
        Test.setCreatedDate(l.Id, tesdate);
        Test.startTest();
            l.First_Successful_Call__c = datetime.newInstance(2014, 9, 15, 9, 20, 10);
            update l; 
            l = [Select Time_to_First_Successful_Call_minutes__c from Lead where FirstName = 'Test Lead001'];
            System.assertEquals(l.Time_to_First_Successful_Call_minutes__c , 10) ;
        Test.stopTest();
                
    }
    @isTest static void test_updateFirstAttemptedCall() {
        
        Id businessHoursId = [select Id,Name from BusinessHours where Name = 'Fluid One Business Hours'].id;
        Lead l = new Lead();
        l.FirstName = 'Test Lead002';
        l.LastName  = 'Test Update First Successful Call';
        l.LeadSource = 'Web';
        l.Company = 'ABC' ;
        l.First_Attempted_Call__c = datetime.newInstance(2014, 9, 10, 10, 10, 00);
        insert l;
        Datetime tesdate = datetime.newInstance(2014, 9, 10, 10, 10, 10);
        Test.setCreatedDate(l.Id, tesdate);
        Test.startTest();
            l.First_Attempted_Call__c = datetime.newInstance(2014, 9, 10, 11, 00, 00);
            update l; 
            l = [Select Time_to_First_Attempted_Call_minutes__c  from Lead where FirstName = 'Test Lead002'];
            System.assertEquals(l.Time_to_First_Attempted_Call_minutes__c, 50) ;
        Test.stopTest();
                
    }
    // FO-193 --> 04 Feb 2020
    @isTest static void test_populateFirstUTM_MHTag() {
        
        Test.startTest();

            Lead l = new Lead(
                LastName = 'Test',
                Company = 'Test',
                Status = 'New Enquiry',
                Industry = 'Construction',
                MHCallTracking__MH_Tags__c = 'utm_campaign=connectivity_business-broadband______non-brand_bmm__~ bonded  dsl _bonded-dsl | utm_content=test | utm_medium=cpc | utm_source=google' 
            );

            insert l;
        
            l.MHCallTracking__MH_Tags__c = 'utm_campaign=TestCom | utm_content=test | utm_medium=cpc | utm_source=google' ;
            update l;
        
            for (Lead t : [SELECT First_Click_UTM_Source__c,First_Click_UTM_Medium__c,First_Click_UTM_Campaign__c,First_Click_UTM_Content__c FROM Lead WHERE Id =:l.Id]) {
                System.assertEquals(t.First_Click_UTM_Source__c, 'google');
                System.assertEquals(t.First_Click_UTM_Medium__c, 'cpc');
                System.assertEquals(t.First_Click_UTM_Campaign__c, 'TestCom');
                System.assertEquals(t.First_Click_UTM_Content__c, 'test');
            }

        Test.stopTest();

    }
}