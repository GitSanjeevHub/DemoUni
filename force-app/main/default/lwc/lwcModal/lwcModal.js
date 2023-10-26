import { LightningElement, track, api } from 'lwc';

export default class LWCModal extends LightningElement {

    //Opens/closes the modal
    @track modalShown;
    
    //Parent-accessible method to open modal
    @api
    showModal(){
        this.modalShown = true;
        //Tells parent that modal is opened
        this.dispatchEvent(new CustomEvent('open'));
    }

    //Parent-accessible method to close modal
    @api
    closeModal(){
        this.modalShown = false;
        //Tells parent that modal is closed
        this.dispatchEvent(new CustomEvent('close')); 
    }

}