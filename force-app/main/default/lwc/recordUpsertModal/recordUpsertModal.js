import { LightningElement, api } from 'lwc';

export default class RecordUpsertModal extends LightningElement {

    @api recordId;
    @api objectName;
    @api columns;

    //Tell lwcModal to open, through its custom showModal function
    @api requestModalOpen(){
        this.template.querySelector('c-lwc-modal').showModal();
    }

    //Tell lwcModal to close through its custom closeModal function
    @api requestModalClose(){
        this.template.querySelector('c-lwc-modal').closeModal();
    }

    //What to do when the modal has closed
    modalHasClosed(){
        
    }

}