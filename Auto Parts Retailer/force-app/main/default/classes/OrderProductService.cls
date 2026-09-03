public without sharing class OrderProductService {
    public static void recalculateQuantities(Set<Id> orderItemIds) {
        Map<Id, OrderItem> newRecords = new Map<Id, OrderItem>();
        for (Id orderItemId : orderItemIds) {
            OrderItem oi = new OrderItem(
                Id = orderItemId,
                Qty_Allocated__c = 0
            );
            newRecords.put(oi.Id, oi);
        }
        for (AggregateResult aggRes: [
            SELECT SUM(Delta_Qty__c) qtyAllocated,
                   Order_Product__c orderItemId
            FROM Stock_Movement__c
            WHERE Order_Product__c IN :newRecords.keySet()
            AND Movement_Type__c IN ('Allocation', 'Deallocation')
            GROUP BY Order_Product__c
        ]) {
            Decimal qtyAllocated = (Decimal) aggRes.get('qtyAllocated');
            Id orderItemId = (Id) aggRes.get('orderItemId');
            OrderItem oi = newRecords.get(orderItemId);
            oi.Qty_Allocated__c = -qtyAllocated;
        }
        update newRecords.values();
    }
}