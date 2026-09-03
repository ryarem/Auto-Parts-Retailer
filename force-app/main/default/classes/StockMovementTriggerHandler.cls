public without sharing class StockMovementTriggerHandler {
    private List<Stock_Movement__c> listNew;
    private Map<Id, Stock_Movement__c> oldMap;
    private TriggerOperation operation;

    public StockMovementTriggerHandler(
        List<Stock_Movement__c> listNew,
        Map<Id, Stock_Movement__c> oldMap,
        TriggerOperation operation
    ) {
        this.listNew = listNew;
        this.oldMap = oldMap;
        this.operation = operation;
    }

    public void handle() {
        switch on operation {
            when BEFORE_INSERT, BEFORE_UPDATE {
                StockMovementService.validateDeltaQuantity(listNew);
            }
            when AFTER_INSERT, AFTER_UNDELETE {
                StockMovementService.recalculateInventoryQuantities(listNew);
                StockMovementService.recalculateOrderItems(listNew);
                StockMovementService.recalculateShipmentLines(listNew);
            }
            when AFTER_UPDATE {
                StockMovementService.recalculateInventoryQuantitiesAfterUpdate(listNew, oldMap);
                StockMovementService.recalculateOrderItems(listNew);
                StockMovementService.recalculateShipmentLines(listNew);
            }
            when AFTER_DELETE {
                StockMovementService.recalculateInventoryQuantities(oldMap.values());
                StockMovementService.recalculateOrderItems(oldMap.values());
                StockMovementService.recalculateShipmentLines(oldMap.values());
            }
        }
    }
}