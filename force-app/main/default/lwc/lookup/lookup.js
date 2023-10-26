import { LightningElement, track, api } from 'lwc';

const MINIMAL_SEARCH_TERM_LENGTH = 2; // Min number of chars required to search
const SEARCH_DELAY = 300; // Wait 300 ms after user stops typing then, peform search

export default class Lookup extends LightningElement {

    @api label;
    @api selection = [];
    @api placeholder = '';
    @api isMultiEntry = false;
    @api errors = [];
    @api scrollAfterNItems;
    @api customKey;
    @api objectName;

    @track firstRecordName;

    @track searchTerm = '';
    @track searchResults = [];
    @track hasFocus = false;
    @track inputValue;

    @api editDisabled = false;

    cleanSearchTerm;
    blurTimeout;
    searchThrottlingTimeout;

// EXPOSED FUNCTIONS

    @api
    setSearchResults(results) {
        //console.log('setSetResults');
        //console.log(results);
        this.searchResults = results.map(result => {
            if (typeof result.icon === 'undefined') {
                result.icon = 'standard:default';
            }
            return result;
        });
    }

    @api
    getSelection() {
        //console.log('lookup-getSelection');
        return this.selection;
    }

    @api
    getkey(){
        //console.log('lookup-getKey');
        return this.customKey;
    }


// INTERNAL FUNCTIONS

    renderedCallback(){

        let comboBoxDivTag = this.template.querySelector('.slds-combobox__form-element');
        
        let pillAreaTag = this.template.querySelector('.slds-combobox__input');

        if (this.isMultiEntry) {
            pillAreaTag.value = this.searchTerm;
        }
        else {
            pillAreaTag.value = this.hasSelection() ? this.selection[0].title : this.searchTerm;
        }
        this.inputValue = pillAreaTag.value;

        if (pillAreaTag.scrollHeight >= 35)
            comboBoxDivTag.style.height = pillAreaTag.scrollHeight + 'px';
        else
            comboBoxDivTag.style.height = 35 + 'px';

        //Ensure last item is not clipped by scrollable section
        let icons = this.template.querySelectorAll("li");
        if (icons && icons.length){
            icons[icons.length-1].scrollIntoView(false, {behavior: 'smooth'});
        }
        
    }

    

    updateSearchTerm(newSearchTerm) {

        //console.log('updateSearchTerm '+newSearchTerm);

        this.searchTerm = newSearchTerm;

        // Compare clean new search term with current one and abort if identical
        const newCleanSearchTerm = newSearchTerm.trim().replace(/\*/g, '').toLowerCase();
        if (this.cleanSearchTerm === newCleanSearchTerm) {
            return;
        }

        // Save clean search term
        this.cleanSearchTerm = newCleanSearchTerm;

        // Ignore search terms that are too small
        if (newCleanSearchTerm.length < MINIMAL_SEARCH_TERM_LENGTH) {
            this.searchResults = [];
            return;
        }

        // Apply search throttling (prevents search if user is still typing)
        if (this.searchThrottlingTimeout) {
            clearTimeout(this.searchThrottlingTimeout);
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.searchThrottlingTimeout = setTimeout(() => {
                // Send search event if search term is long enougth
                if (this.cleanSearchTerm.length >= MINIMAL_SEARCH_TERM_LENGTH) {
                    const searchEvent = new CustomEvent('search', {
                        detail: {
                            objectName: this.objectName,
                            searchTerm: this.cleanSearchTerm,
                            selectedIds: this.selection.map(element => element.id)
                        }
                    });
                    //console.log(JSON.stringify(searchEvent));
                    this.dispatchEvent(searchEvent);
                }
                this.searchThrottlingTimeout = null;
            },
            SEARCH_DELAY
        );
    }

    isSelectionAllowed() {
        if (this.isMultiEntry) {
            return true;
        }
        return !this.hasSelection();
    }

    hasResults() {
        return this.searchResults.length > 0;
    }

    hasSelection() {
        return this.selection.length > 0;
    }


// EVENT HANDLING

    handleInput(event) {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }
        this.updateSearchTerm(event.target.value);
    }

    handleResultClick(event) {
        //console.log('handleResultClick');
        const recordId = event.currentTarget.dataset.recordid;

        // Save selection
        let selectedItem = this.searchResults.filter(result => result.id === recordId);
        if (selectedItem.length === 0) {
            return;
        }
        selectedItem = selectedItem[0];
        const newSelection = [...this.selection];
        newSelection.push(selectedItem);
        this.selection = newSelection;

        this.firstRecordName = selectedItem.title;

        // Reset search
        this.searchTerm = '';
        this.searchResults = [];

        // Notify parent components that selection has changed
        this.dispatchSelectionChangeEvent();
    }

    handleComboboxClick() {
        // Hide combobox immediatly
        if (this.blurTimeout) {
            window.clearTimeout(this.blurTimeout);
        }
        this.hasFocus = false;
    }

    handleFocus() {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }
        this.hasFocus = true;
    }

    handleBlur() {
        // Prevent action if selection is not allowed
        if (!this.isSelectionAllowed()) {
            return;
        }
        // Delay hiding combobox so that we can capture selected result
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.blurTimeout = window.setTimeout(() => {
                this.hasFocus = false;
                this.blurTimeout = null;
            },
            300
        );
    }

    handleRemoveSelectedItem(event) {

        console.log('HANDLEREMOVESELECTEDITEM');
        const recordId = event.currentTarget.name;
        this.selection = this.selection.filter(item => item.id !== recordId);

        
        // Notify parent components that selection has changed
        this.dispatchSelectionChangeEvent();
    }

    handleClearSelection() {
        this.selection = [];

        let comboBoxDivTag = this.template.querySelector('.slds-combobox__form-element');
        comboBoxDivTag.style.height = '35px';

        // Notify parent components that selection has changed
        this.dispatchSelectionChangeEvent();
    }

    dispatchSelectionChangeEvent(){

        let event = new CustomEvent('selectionchange', {
            detail: {
                selection : JSON.stringify(this.selection)
            }
        });
        console.log(JSON.parse(JSON.stringify(event.detail)));
        this.dispatchEvent(event);

       
    }


// STYLE EXPRESSIONS

    get getContainerClass() {
        let css = 'slds-combobox_container slds-has-inline-listbox ';
        if (this.hasFocus && this.hasResults()) {
            css += 'slds-has-input-focus ';
        }
        if (this.errors.length > 0) {
            css += 'has-custom-error';
        } 
        return css;
    }

    get getDropdownClass() {
        let css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ';
        if (this.hasFocus && this.hasResults()) {
            css += 'slds-is-open';
        } else {
            css += 'slds-combobox-lookup';
        }
        return css;
    }

    get getInputClass() {
        let css = 'slds-input slds-combobox__input has-custom-height '
            + (this.errors.length === 0 ? '' : 'has-custom-error ');
        if (!this.isMultiEntry) {
            css += 'slds-combobox__input-value '
                + (this.hasSelection() ? 'has-custom-border' : '');
        }
        return css;
    }

    get getComboboxClass() {
        let css = 'slds-combobox__form-element slds-input-has-icon ';
        if (this.isMultiEntry) {
            css += 'slds-input-has-icon_right';
        } else {
            css += (this.hasSelection() ? 'slds-input-has-icon_left-right' : 'slds-input-has-icon_right');
        }
        return css;
    }

    get getSearchIconClass() {
        let css = 'slds-input__icon slds-input__icon_right ';
        if (!this.isMultiEntry) {
            css += (this.hasSelection() ? 'slds-hide' : '');
        }
        return css;
    }

    get getClearSelectionButtonClass() {
        return 'slds-button slds-button_icon slds-input__icon slds-input__icon_right '
            + (this.hasSelection() ? '' : 'slds-hide');
    }

    get getSelectIconName() {
        return this.hasSelection() ? this.selection[0].icon : 'standard:default';
    }

    get getSelectIconClass() {
        return 'slds-combobox__input-entity-icon '
            + (this.hasSelection() ? '' : 'slds-hide');
    }


    get getListboxClass() {
        return 'slds-listbox slds-listbox_vertical slds-dropdown slds-dropdown_fluid '
            + (this.scrollAfterNItems ? 'slds-dropdown_length-with-icon-' + this.scrollAfterNItems : '');
    }

    get isInputReadonly() {
        if (this.isMultiEntry) {
            return false;
        }
        return this.hasSelection();
    }

    get isExpanded() {
        return this.hasResults();
    }
}