public with sharing class InventoryRecordService {
    public static void preventNegativeQtyOnHand(List<InventoryRecord__c> listNewInventoryRecord) {
        for (InventoryRecord__c rec : listNewInventoryRecord) {
            if (rec.Qty_On_Hand__c < 0) {
                rec.addError('Can’t decrease Quantity on Hand to Negative value');
            }
            if (rec.Qty_Available__c < 0) {
                rec.addError('Can’t decrease Quantity Available to Negative value');
            }
        }
    }

    public static void createReorderTasks(List<InventoryRecord__c> recordsToProcess) {
        Set<Id> partIds = new Set<Id>();

        for (InventoryRecord__c rec : recordsToProcess) {
            partIds.add(rec.Part__c);
        }

        Map<Id, Task> openTasksByPart = new Map<Id, Task>();

        for (Task t : [
            SELECT Id, WhatId
            FROM Task
            WHERE WhatId IN :partIds
            AND Status != 'Completed'
        ]) {
            openTasksByPart.put(t.WhatId, t);
        }

        List<Task> tasksToInsert = new List<Task>();

        for (InventoryRecord__c fullRec : recordsToProcess) {

            if (fullRec.Part__c == null || fullRec.Location__c == null) {
                continue;
            }

            if (openTasksByPart.containsKey(fullRec.Part__c)) {
                continue;
            }

            tasksToInsert.add(new Task(
                Subject = 'Reorder required: ' +
                           fullRec.Part_Name__c +
                           ' at ' +
                           fullRec.Location_Name__c,
                WhatId = fullRec.Part__c,
                OwnerId = UserInfo.getUserId(),
                ActivityDate = Date.today().addDays(7),
                Status = 'Open'
            ));
        }

        insert tasksToInsert;
    }

    public static void recalculateQuantities(Set<Id> inventoryRecordIds) {
        Map<Id, InventoryRecord__c> newRecords = new Map<Id, InventoryRecord__c>();
        for (Id invRecordId: inventoryRecordIds) {
            InventoryRecord__c invRecord = new InventoryRecord__c(
                Id = invRecordId,
                Qty_On_Hand__c = 0,
                Qty_Allocated__c = 0
            );
            newRecords.put(invRecord.Id, invRecord);
        }
        for (AggregateResult aggRes: [
            SELECT SUM(Delta_Qty__c) qtyOnHand, Inventory_Record__c invRec
            FROM Stock_Movement__c
            WHERE Inventory_Record__c IN :newRecords.keySet()
            AND Movement_Type__c NOT IN ('Allocation', 'Deallocation')
            GROUP BY Inventory_Record__C
        ]) {
            Decimal qtyOnHand = (Decimal) aggRes.get('qtyOnHand');
            Id invRecId = (Id) aggRes.get('invRec');
            InventoryRecord__c invRec = newRecords.get(invRecId);
            invRec.Qty_On_Hand__c = qtyOnHand;
        }
        for (AggregateResult aggRes: [
            SELECT SUM(Delta_Qty__c) qtyAllocated, Inventory_Record__c invRec
            FROM Stock_Movement__c
            WHERE Inventory_Record__c IN :newRecords.keySet()
            AND Movement_Type__c IN ('Allocation', 'Deallocation')
            GROUP BY Inventory_Record__C
        ]) {
            Decimal qtyAllocated = (Decimal) aggRes.get('qtyAllocated');
            Id invRecId = (Id) aggRes.get('invRec');
            InventoryRecord__c invRec = newRecords.get(invRecId);
            invRec.Qty_Allocated__c = -qtyAllocated;
        }
        update newRecords.values();
    }
}