public with sharing class InventoryRecordTriggerHandler {
    
    private List<InventoryRecord__c> listNewInventoryRecord;
    private Map<Id, InventoryRecord__c> mapOldInventoryRecord;
    private TriggerOperation operation;

    public InventoryRecordTriggerHandler(
        List<InventoryRecord__c> listNewInventoryRecord,
        Map<Id, InventoryRecord__c> mapOldInventoryRecord,
        TriggerOperation operation
    ) {
        this.listNewInventoryRecord = listNewInventoryRecord;
        this.mapOldInventoryRecord = mapOldInventoryRecord;
        this.operation = operation;
    }

    public void handle() {
        switch on operation {
            when BEFORE_UPDATE {
                InventoryRecordService.preventNegativeQtyOnHand(listNewInventoryRecord);
            }
            when AFTER_UPDATE {
                processReorderTasks();
            }
        }
    }

    private void processReorderTasks() {
        List<InventoryRecord__c> recordsToProcess = new List<InventoryRecord__c>();

        for (InventoryRecord__c rec : listNewInventoryRecord) {

            InventoryRecord__c oldRec = mapOldInventoryRecord.get(rec.Id);

            if (
                oldRec.Qty_On_Hand__c != rec.Qty_On_Hand__c &&
                rec.Qty_On_Hand__c < rec.Reorder_Point__c
            ) {
                recordsToProcess.add(rec);
            }
        }

        if (!recordsToProcess.isEmpty()) {
            InventoryRecordService.createReorderTasks(recordsToProcess);
        }
    }
}