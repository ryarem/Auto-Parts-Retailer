public without sharing class ShipmentService {
    public static void preventStatusRollback(List<Shipment> listNew, Map<Id, Shipment> oldMap) {
        Map<String, Integer> statusOrder = new Map<String, Integer>{
            'Draft' => 1,
            'Approved' => 2,
            'Picking' => 3,
            'Dispatched' => 4,
            'In Transit' => 5,
            'Received' => 6
        };
        for (Shipment shipment : listNew) {
            Shipment oldShipment = oldMap.get(shipment.Id);
            if (oldShipment.Status == 'Cancelled') {
                shipment.addError(
                    'Cancelled Shipment can not be changed'
                );
                continue;
            }
            if (shipment.Status == 'Cancelled') {
                continue;
            }
        Integer oldStatusOrder = statusOrder.get(oldShipment.Status);
        Integer newStatusOrder = statusOrder.get(shipment.Status);
            if (newStatusOrder < oldStatusOrder) {
                shipment.addError(
                    'Shipment status rollback is not allowed'
                );
            }
        }
    }
    
    public static void processDispatched(List<Shipment> dispatchedShipments) {
        Set<Id> shipmentIds = new Set<Id>();
        for (Shipment s : dispatchedShipments) {
            shipmentIds.add(s.Id);
        }
        List<Shipment_Line__c> lines = [
            SELECT Id, Part__c, Qty_Shipped__c, Shipment__r.SourceLocationId
            FROM Shipment_Line__c
            WHERE Shipment__c IN :shipmentIds
        ];
        List<Stock_Movement__c> movements = StockMovementService.buildTransferOutMovements(lines);
        insert movements;
    }
}