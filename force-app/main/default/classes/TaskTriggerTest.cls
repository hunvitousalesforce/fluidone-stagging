/*
 * Author   Mony Nou
 * Description: Test class for TaskTriggerHandler.cls
*/
@isTest
private class TaskTriggerTest {
    
    @isTest static void test_initRecord() {
        
        Test.startTest();

            Lead lead = new Lead(
                FirstName = 'TEST LEAD',
                LastName = 'TEST 001',
                Company = 'TEST COMPANY'
            );

            insert lead;

            for (Task t : [SELECT Subject, Activity_Type__c, Activity_Sub_Type__c FROM Task WHERE WhoId =:lead.Id]) {
                System.assertEquals(t.Subject, 'Take ownership of Lead');
                System.assertEquals(t.Activity_Type__c, 'Task');
                System.assertEquals(t.Activity_Sub_Type__c, 'Task');
            }   

        Test.stopTest();

    }
    
    @isTest static void test_populateUTM_MHTag() {
        
        Test.startTest();

            Task task = new Task(
                Subject = 'Test',
                MHCallTracking__MH_Tags__c = 'utm_source=Bing | utm_medium=cpc | utm_campaign=Data_Business-ADSL____DT_Prospecting_Exact_ | utm_content= just test'
            );

            insert task;

            for (Task t : [SELECT Last_Click_UTM_Source__c,Last_Click_UTM_Medium__c,Last_Click_UTM_Campaign__c,Last_Click_UTM_Content__c FROM Task WHERE Id =:task.Id]) {
                System.assertEquals(t.Last_Click_UTM_Source__c, 'Bing');
                System.assertEquals(t.Last_Click_UTM_Medium__c, 'cpc');
                System.assertEquals(t.Last_Click_UTM_Campaign__c, 'Data_Business-ADSL____DT_Prospecting_Exact_');
                System.assertEquals(t.Last_Click_UTM_Content__c, 'just test');
            }

        Test.stopTest();

    }

    @isTest static void test_populateUTM_Description() {
        
        Test.startTest();

            Task task = new Task(
                Subject = 'Test',
                Description = 'Last Click Source:test1\nLast Click Medium:test2\nLast Click Campaign:test3\nLast Click Content:test4\n'
            );

            insert task;

            task.Description = 'GA Client ID:12344\nLast Click Source:test1\nLast Click Medium:test2\nLast Click Campaign:test3\nLast Click Content:test4\n';
            update task;

            for (Task t : [SELECT Last_Click_UTM_Source__c,Last_Click_UTM_Medium__c,Last_Click_UTM_Campaign__c,Last_Click_UTM_Content__c FROM Task WHERE Id =:task.Id]) {
                System.assertEquals(t.Last_Click_UTM_Source__c, 'test1');
                System.assertEquals(t.Last_Click_UTM_Medium__c, 'test2');
                System.assertEquals(t.Last_Click_UTM_Campaign__c, 'test3');
                System.assertEquals(t.Last_Click_UTM_Content__c, 'test4');
            }

        Test.stopTest();

    }
    
    @isTest static void test_populateNextClosestActivityToOpportunity() {
        
        Test.startTest();
            
            User usr = new User();
            
           	for (User u : [SELECT Id FROM User WHERE Profile.Name = 'Salesforce - Manager' and IsActive = true LIMIT 1]) {
                usr = u;
            }
            
            if (usr.Id != null) {
                
                Opportunity opp = new Opportunity(
                    Name = 'Test Opportunity',
                    CloseDate = Date.today().addDays(30),
                    StageName = 'Discovery Phase'
                );    
                
                insert opp;
                
                System.runAs(usr) {
                
                    Task t = new Task(
                        Subject = 'Test',
                        WhatId = opp.Id,
                        ActivityDate =  Date.today().addDays(3)
                    );
        
                    insert t;
                    
                    Opportunity res_opp = [SELECT NextStep, NextActivity__c FROM Opportunity WHERE Id=:opp.Id];
                    
                    System.debug('#### res_opp :: ' + res_opp);
                    System.debug('#### t :: ' + t);
                    System.assertEquals(res_opp.NextStep, t.Subject);
                    System.assertEquals(res_opp.NextActivity__c, t.ActivityDate);
                }
            }
        
            
        
        Test.stopTest();
    }
    
    
}