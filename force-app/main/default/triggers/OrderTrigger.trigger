/**
 * @description       : 
 * @author            : matthew.rosete@pracedo.com
 * @group             : 
 * @last modified on  : 27-10-2022
 * @last modified by  : matthew.rosete@pracedo.com
**/
trigger OrderTrigger on Order (after insert, after update) {
    new OrderTriggerHandler().run();
}