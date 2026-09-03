trigger InventoryRecordTrigger on InventoryRecord__c (before update, after update) {
    new InventoryRecordTriggerHandler(Trigger.new, Trigger.oldMap, Trigger.operationType).handle();
}