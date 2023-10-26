import { LightningElement, api, wire } from 'lwc';
import getRecordTypeInfos from 
    '@salesforce/apex/DataAccess.getRecordTypeInfosByDeveloperName';

export default class LwcGetRecordTypeInfos extends LightningElement {

    @api objectApiName;

    @wire (getRecordTypeInfos, { objectName: '$objectApiName' }) wiredMetadataInfo({ error, data}){
        if (data){
            this.dispatchEvent( new CustomEvent(
                'wire', { 
                    detail : {
                        data: data
                    }
                })
            );
            
        }
        else if (error){
            console.log("record type wire failed");
            console.log(error);
        }
    }

}