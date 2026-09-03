trigger ShipmentTrigger on Shipment (before update, after update) {
    new ShipmentTriggerHandler(Trigger.new, Trigger.oldMap, Trigger.operationType).handle();
}