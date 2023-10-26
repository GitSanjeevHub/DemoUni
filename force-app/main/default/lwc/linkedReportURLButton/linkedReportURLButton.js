import { LightningElement, api, track, wire } from 'lwc';
import getReportPortalURL from '@salesforce/apex/ReportMetadataAccess.getReportPortalURL';

export default class LinkedReportURLButton extends LightningElement {

    @track reportId;
    @api reportAPIName;

    @api recordId;
    @api linkedFilterField;

    @track reportURL;


    @wire(getReportPortalURL, { reportAPIName : '$reportAPIName'}) 
    reportWired({error, data}){
        if (data){
            let reportBaseURL = data;
            console.log(reportBaseURL);

            this.reportURL = reportBaseURL + '?'+
                'reportFilters=%5B%7B"operator"%3A"equals"%2C"value"%3A"'+
                this.recordId+'"%2C"column"%3A"'+this.linkedFilterField+'"%7D%5D';
        }
        if (error){
            console.log(JSON.stringify(error));
        }
    }

}