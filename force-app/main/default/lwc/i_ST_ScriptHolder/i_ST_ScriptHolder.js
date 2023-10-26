import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import jQuery from '@salesforce/resourceUrl/I_ST_latrobeJQuery';
import dsLtu from '@salesforce/resourceUrl/I_ST_dsLtu';
import ltuLegacy from '@salesforce/resourceUrl/I_ST_ltuLegacy';
import funnelbackAutoCompletion from '@salesforce/resourceUrl/I_ST_funnelbackAutoCompletion';
import typeAheadBundle from '@salesforce/resourceUrl/I_ST_typeAheadBundle';

export default class ScriptHolder extends LightningElement {
    @track ltuLegacyInitialised = false;
    @track jQueryInitialised = false;
    @track dsLtuInitialised = false;
    @track funnelbackAutoCompletionInitialised = false;
    @track typeAheadBundleInitialised = false;
    
    renderedCallback() {
        var myCmp = this;

        console.log('try rerender');
        console.log('this.jQueryInitialised', this.jQueryInitialised);
        console.log('this.ltuLegacyInitialised', this.ltuLegacyInitialised);
        console.log('this.dsLtuInitialised', this.dsLtuInitialised);

        if(!this.jQueryInitialised){
            loadScript(this, jQuery)
            .then(() => {
                console.log('loaded jQuery script');
                this.jQueryInitialised = true;
                console.log('this.jQueryInitialised', this.jQueryInitialised);

                $('document').ready(function() {
                    myCmp.loadTypeAhead();
                });
                //this.rerenderScripts();
            })
            .catch(error => console.error(error));
        }
    }

    loadTypeAhead() {
        loadScript(this, typeAheadBundle)
            .then(() => {
                console.log('loaded typeAheadBundle script');
                this.typeAheadBundleInitialised = true;
                this.loadFunnelBack();
            })
        .catch(error => {loadTypeAhead(); console.error(error)});
    }

    loadFunnelBack() {
        loadScript(this, funnelbackAutoCompletion)
            .then(() => {
                console.log('loaded funnelbackAutoCompletion script');
                this.funnelbackAutoCompletionInitialised = true;
                this.loadLtuLegacy();
            })
        .catch(error => {loadFunnelBack(); console.error(error)});
    }

    loadLtuLegacy() {
        loadScript(this, ltuLegacy)
            .then(() => {
                console.log('loaded ltuLegacy script');
                this.ltuLegacyInitialised = true;
                this.loadDsLtu();
            })
        .catch(error => {loadLtuLegacy(); console.error(error)});
    }

    loadDsLtu() {
        loadScript(this, dsLtu)
            .then(() => {
                console.log('loaded dsLtu script');
                this.dsLtuInitialised = true;
            })
        .catch(error => {loadLtuLegacy(); console.error(error)});
    }
}