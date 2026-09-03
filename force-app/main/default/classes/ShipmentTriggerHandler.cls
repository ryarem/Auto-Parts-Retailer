public without sharing class ShipmentTriggerHandler {
    private List<Shipment> listNew;
    private Map<Id, Shipment> oldMap;
    private TriggerOperation operation;

    public ShipmentTriggerHandler(
        List<Shipment> listNew,
        Map<Id, Shipment> oldMap,
        TriggerOperation operation
    ) {
        this.listNew = listNew;
        this.oldMap = oldMap;
        this.operation = operation;
    }

    public void handle() {
        switch on operation {
            when BEFORE_UPDATE {
                ShipmentService.preventStatusRollback(listNew, oldMap);
            }
            when AFTER_UPDATE {
                processDispatchedShipments();
            }
        }
    }

    private void processDispatchedShipments() {
        List<Shipment> dispatchedShipments = new List<Shipment>();
        for (Shipment shipment : listNew) {
            Shipment oldShipment = oldMap.get(shipment.Id);
            if (
                oldShipment.Status != 'Dispatched' &&
                shipment.Status == 'Dispatched'
            ) {
                dispatchedShipments.add(shipment);
            }   
        }     
        if (!dispatchedShipments.isEmpty()) {
            ShipmentService.processDispatched(dispatchedShipments);
        }
    }
}