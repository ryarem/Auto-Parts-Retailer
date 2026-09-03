public inherited sharing class StockMovementService {

    public static void validateDeltaQuantity(List<Stock_Movement__c> listNew) {
        for (Stock_Movement__c movement : listNew) {
            if (movement.Delta_Qty__c == 0) {
                movement.addError('Delta Quantity can not be zero');
                continue;
            }
            switch on movement.Movement_Type__c {
                when 'Deallocation' {
                    if (movement.Delta_Qty__c < 0) {
                        movement.addError(
                            'Deallocation must have a positive Delta Quantity'
                        );
                    }
                }
                when 'Allocation' {
                    if (movement.Delta_Qty__c > 0) {
                        movement.addError(
                            'Allocation must have a negative Delta Quantity'
                        );
                    }
                }
                when 'Transfer Out' {
                    if (movement.Delta_Qty__c > 0) {
                        movement.addError(
                            'Transfer Out must have a negative Delta Quantity'
                        );
                    }
                }
                when 'Transfer In' {
                    if (movement.Delta_Qty__c < 0) {
                        movement.addError(
                            'Transfer In must have a positive Delta Quantity'
                        );
                    }
                }
                when 'Receipt' {
                    if (movement.Delta_Qty__c < 0) {
                        movement.addError(
                            'Receipt must have a positive Delta Quantity'
                        );
                    }
                }
                when 'Sale' {
                    if (movement.Delta_Qty__c > 0) {
                        movement.addError(
                            'Sale must have a negative Delta Quantity'
                        );
                    }
                }
            }
        } 
    }

    public static void recalculateInventoryQuantities(List<Stock_Movement__c> newMovements) {
        Set<Id> inventoryRecordIds = new Set<Id>();
        for (Stock_Movement__c movement: newMovements) {
            if (movement.Delta_Qty__c != null && movement.Delta_Qty__c != 0) {
                inventoryRecordIds.add(movement.Inventory_Record__c);
            }
        }
        if (!inventoryRecordIds.isEmpty()) {
            InventoryRecordService.recalculateQuantities(inventoryRecordIds);
        }
    }

    public static void recalculateInventoryQuantitiesAfterUpdate(List<Stock_Movement__c> newMovements, Map<Id, Stock_Movement__c> oldMap) {
        Set<Id> inventoryRecordIds = new Set<Id>();
        for (Stock_Movement__c movement: newMovements) {
            Stock_Movement__c oldMovement = oldMap.get(movement.Id);
            if (movement.Delta_Qty__c != oldMovement.Delta_Qty__c) {
                inventoryRecordIds.add(movement.Inventory_Record__c);
            }
        }
        if (!inventoryRecordIds.isEmpty()) {
            InventoryRecordService.recalculateQuantities(inventoryRecordIds);
        }
    }

    public static void recalculateOrderItems(List<Stock_Movement__c> movements) {
        Set<Id> orderItemIds = new Set<Id>();
        for (Stock_Movement__c m : movements) {
            if (m.Order_Product__c == null) 
            continue;
            if (m.Movement_Type__c != 'Allocation' &&
            m.Movement_Type__c != 'Deallocation') {
            continue;
        }
        orderItemIds.add(m.Order_Product__c);
        }
        if (!orderItemIds.isEmpty()) {
            OrderProductService.recalculateQuantities(orderItemIds);
        }   
    }

    public static void recalculateShipmentLines(List<Stock_Movement__c> movements) {
        Set<Id> shipmentLineIds = new Set<Id>();
        for (Stock_Movement__c m : movements) {
            if (m.Shipment_Line__c == null) {
                continue;
            }
            if (m.Movement_Type__c != 'Transfer Out' && m.Movement_Type__c != 'Transfer In') {
                continue;
            }
            shipmentLineIds.add(m.Shipment_Line__c);
        }
        if (!shipmentLineIds.isEmpty()) {
            ShipmentLineService.recalculateQuantities(shipmentLineIds);
        }
    }

    public static List<Stock_Movement__c> buildTransferOutMovements(List<Shipment_Line__c> lines) {
        List<Stock_Movement__c> result = new List<Stock_Movement__c>();
        Set<Id> partIds = new Set<Id>();
        Set<Id> sourceLocationIds = new Set<Id>();
        for (Shipment_Line__c line : lines) {
            if (line.Part__c == null) {
                continue;
            }
            partIds.add(line.Part__c);
            sourceLocationIds.add(line.Shipment__r.SourceLocationId);
        }
        List<InventoryRecord__c> invRecords = [
            SELECT Id, Part__c, Location__c
            FROM InventoryRecord__c
            WHERE Part__c IN :partIds
            AND Location__c IN :sourceLocationIds
        ];
        for (Shipment_Line__c line : lines) {
            if (line.Part__c == null) {
                continue;
            }
            Id invRecordId = findInventoryRecord(line.Part__c, line.Shipment__r.SourceLocationId, invRecords);
            if (invRecordId == null) {
                throw new StockException('Could not find inventory for Part ID '+line.Part__c + ' and Location ID '+line.Shipment__r.SourceLocationId);
            }
            result.add(new Stock_Movement__c(
                Inventory_Record__c = invRecordId,
                Part__c = line.Part__c,
                Shipment_Line__c = line.Id,
                Movement_Type__c = 'Transfer Out',
                Delta_Qty__c = -line.Qty_Shipped__c
            ));
        }
        return result;
    }

    private static Id findInventoryRecord(Id partId, Id locationId, List<InventoryRecord__c> invRecords) {
        for (InventoryRecord__c invRecord: invRecords) {
            if (invRecord.Part__c == partId && invRecord.Location__c == locationId) {
                return invRecord.Id;
            }
        }
        return null;
    }

    public class StockException extends Exception {}
}