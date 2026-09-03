import { LightningElement, api, wire } from 'lwc';
import getInventoryByLocation from '@salesforce/apex/InventoryDashboardController.getInventoryByLocation';

const columns = [
    { label: 'Part Number', fieldName: 'partNumber' },
    { label: 'Part Name', fieldName: 'partName' },
    { label: 'Category', fieldName: 'category' },

    {
        label: 'On Hand',
        fieldName: 'qtyOnHand',
        type: 'number',
        cellAttributes: {
            class: { fieldName: 'onHandClass' }
        }
    },

    {
        label: 'Allocated',
        fieldName: 'qtyAllocated',
        type: 'number'
    },

    {
        label: 'Available',
        fieldName: 'qtyAvailable',
        type: 'number',
        cellAttributes: {
            class: { fieldName: 'availableClass' }
        }
    },

    {
        label: 'Reorder Point',
        fieldName: 'reorderPoint',
        type: 'number'
    }
];

export default class InventoryDashboard extends LightningElement {
    @api recordId;

    columns = columns;

    data = [];
    allData = [];

    @wire(getInventoryByLocation, { locationId: '$recordId' })
    wiredInventory({ data, error }) {
        if (data) {
            this.allData = data.map(record => {
                let onHandClass = '';
                let availableClass = '';

                const available = record.Qty_Available__c || 0;
                const reorder = record.Reorder_Point__c || 0;

                if (record.Qty_On_Hand__c === 0) {
                    onHandClass = 'slds-text-color_error';
                } else if (available <= reorder) {
                    onHandClass = 'slds-text-color_error';
                }
                return {
                    Id: record.Id,

                    partNumber: record.Part__r?.Part_Number__c,
                    partName: record.Part__r?.Name,
                    category: record.Part__r?.Category__c,

                    qtyOnHand: record.Qty_On_Hand__c,
                    qtyAllocated: record.Qty_Allocated__c,
                    qtyAvailable: record.Qty_Available__c,
                    reorderPoint: record.Reorder_Point__c,

                    onHandClass: onHandClass,
                    availableClass: availableClass
                };
            });
            this.data = this.allData;
        } else if (error) {
            console.error(error);
        }
    }

    handleSearch(event) {
        const key = event.target.value?.toLowerCase();
        if (!key) {
            this.data = this.allData;
            return;
        }
        this.data = this.allData.filter(item => {
            return (
                (item.partNumber &&
                    item.partNumber.toLowerCase().includes(key)) ||

                (item.category &&
                    item.category.toLowerCase().includes(key))
            );
        });
    }
}