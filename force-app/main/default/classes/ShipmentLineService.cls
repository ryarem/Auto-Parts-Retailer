public without sharing class ShipmentLineService {
    public static void recalculateQuantities(Set<Id> shipmentLineIds) {
        Map<Id, Shipment_Line__c> newRecords = new Map<Id, Shipment_Line__c>();
        for (Id shipmentLineId : shipmentLineIds) {
            Shipment_Line__c shipmentLine = new Shipment_Line__c(
                Id = shipmentLineId,
                Qty_Shipped__c = 0,
                Qty_Received__c = 0
            );
            newRecords.put(shipmentLine.Id, shipmentLine);
        }
        for (AggregateResult aggRes : [
            SELECT
                Shipment_Line__c shipmentLineId,
                Movement_Type__c movementType,
                SUM(Delta_Qty__c) qty
            FROM Stock_Movement__c
            WHERE Shipment_Line__c IN :newRecords.keySet()
            AND Movement_Type__c IN ('Transfer Out', 'Transfer In')
            GROUP BY Shipment_Line__c, Movement_Type__c
        ]) {
            Id shipmentLineId = (Id) aggRes.get('shipmentLineId');
            String movementType = (String) aggRes.get('movementType');
            Decimal qty = (Decimal) aggRes.get('qty');
            Shipment_Line__c shipmentLine = newRecords.get(shipmentLineId);
            if (movementType == 'Transfer Out') {
                shipmentLine.Qty_Shipped__c = -qty;
            }
            if (movementType == 'Transfer In') {
                shipmentLine.Qty_Received__c = qty;
            }
        }
        update newRecords.values();
    }
}