trigger StockMovementTrigger on Stock_Movement__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    new StockMovementTriggerHandler(Trigger.new, Trigger.oldMap, Trigger.operationType).handle();
}