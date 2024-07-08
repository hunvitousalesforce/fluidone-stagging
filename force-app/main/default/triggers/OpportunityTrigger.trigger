/**
 * @description       : 
 * @author            : jamesgoode@fluidone.com
 * @group             : 
 * @last modified on  : 18/06/2024
 * @last modified by  : jamesgoode@fluidone.com
**/
trigger OpportunityTrigger on Opportunity (after insert, after update) 
{
    new SendToCPQTrigger().run();
}