public with sharing class InventoryDashboardController {
    @AuraEnabled(cacheable=true)
    public static List<InventoryRecord__c> getInventoryByLocation(Id locationId) {
        return [
            SELECT
                Id,
                Qty_On_Hand__c,
                Qty_Allocated__c,
                Qty_Available__c,
                Reorder_Point__c,
                Part__r.Part_Number__c,
                Part__r.Name,
                Part__r.Category__c
            FROM InventoryRecord__c
            WHERE Location__c = :locationId
            ORDER BY Part__r.Part_Number__c
        ];
    }
}