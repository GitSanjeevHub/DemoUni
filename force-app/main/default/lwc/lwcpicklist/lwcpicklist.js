/**
 * Created by burnside on 2019-06-02.
 */

import { LightningElement, api, track, wire } from 'lwc';
import getPickListValues from '@salesforce/apex/PicklistController.getPickListValues';

export default class LwcPicklist extends LightningElement {

    @api label;
    @api variant;
    @api objectType;
    @api selectedField;
    @api selectedValue;
    @track options;

    @wire(getPickListValues, { objectType: '$objectType', selectedField: '$selectedField' })
    wiredOptions({ error, data }) {

        if (data){
            this.options = data;
        }
        else {
            console.log(error);
            console.log(JSON.stringify(error));
        }

    }

    handleChange(event){

        console.log('handleChange');

        const selectedValue = event.detail.value;
        console.log(selectedValue);

        const selectedEvent = new CustomEvent('change', { detail : {selectedValue}});
        console.log(JSON.stringify(selectedEvent));

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

}