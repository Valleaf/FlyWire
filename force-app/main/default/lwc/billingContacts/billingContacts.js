import { LightningElement, api, track } from 'lwc';
import getBillingContacts from '@salesforce/apex/BillingContactsController.getBillingContacts';

// Column labels
import LABEL_COL_NAME from '@salesforce/label/c.BillingContacts_Column_Name';
import LABEL_COL_TITLE from '@salesforce/label/c.BillingContacts_Column_Title';
import LABEL_COL_EMAIL from '@salesforce/label/c.BillingContacts_Column_Email';
import LABEL_COL_PHONE from '@salesforce/label/c.BillingContacts_Column_Phone';
import LABEL_COL_PRIMARY from '@salesforce/label/c.BillingContacts_Column_PrimaryAccount';

// UI labels
import LABEL_TITLE from '@salesforce/label/c.BillingContacts_Title';
import LABEL_SEARCH from '@salesforce/label/c.BillingContacts_SearchLabel';
import LABEL_SEARCH_PH from '@salesforce/label/c.BillingContacts_SearchPlaceholder';
import LABEL_EMPTY from '@salesforce/label/c.BillingContacts_EmptyState';
import LABEL_PREV from '@salesforce/label/c.BillingContacts_Prev';
import LABEL_NEXT from '@salesforce/label/c.BillingContacts_Next';
import LABEL_PAGE from '@salesforce/label/c.BillingContacts_Page';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BillingContacts extends LightningElement {
    @api recordId; // Account Id from the record page
    @api pageSize = 10; 

    @track rows = [];
    loading = false;
    searchTerm = '';
    debounce;

    bcTitle = LABEL_TITLE;
    bcSearchLabel = LABEL_SEARCH;
    bcSearchPlaceholder = LABEL_SEARCH_PH;
    bcEmptyState = LABEL_EMPTY;
    bcPrevLabel = LABEL_PREV;
    bcNextLabel = LABEL_NEXT;
    bcPageLabel = LABEL_PAGE;


    // datatable columns
    columns = [
        { label: LABEL_COL_NAME, fieldName: 'contactUrl', type: 'url', typeAttributes: { label: { fieldName: 'name' }, target: '_blank' } },
        { label: LABEL_COL_TITLE, fieldName: 'title' },
        { label: LABEL_COL_EMAIL, fieldName: 'email', type: 'email' },
        { label: LABEL_COL_PHONE, fieldName: 'phone', type: 'phone' },
        { label: LABEL_COL_PRIMARY, fieldName: 'accountName' }
    ];

    // pagination state
    page = 1;

    connectedCallback() {
        this.fetchData();
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value || '';
        clearTimeout(this.debounce);
        this.debounce = setTimeout(() => this.fetchData(), 300);
    }

    get hasResults() {
        return Array.isArray(this.rows) && this.rows.length > 0;
    }

    get totalPages() {
        const total = this.rows ? this.rows.length : 0;
        return Math.max(1, Math.ceil(total / (this.pageSize || 10)));
    }

    get pagedRows() {
        const size = this.pageSize || 10;
        const start = (this.page - 1) * size;
        return (this.rows || []).slice(start, start + size);
    }

    get isPrevDisabled() {
        return this.page <= 1;
    }

    get isNextDisabled() {
        return this.page >= this.totalPages;
    }

    get pageSizeNum() {
        const n = parseInt(this.pageSize, 10);
        return isNaN(n) ? 10 : n;
    }

        get totalPages() {
        const total = this.rows ? this.rows.length : 0;
        return Math.max(1, Math.ceil(total / this.pageSizeNum));
    }

    get pagedRows() {
        const size = this.pageSizeNum;
        const start = (this.page - 1) * size;
        return (this.rows || []).slice(start, start + size);
    }

    handlePrev() {
        if (this.page > 1) {
            this.page -= 1;
        }
    }

    handleNext() {
        if (this.page < this.totalPages) {
            this.page += 1;
        }
    }

    /**
     * Fetch billing contacts from the database, asynchrnously.
     */
    async fetchData() {
        if (!this.recordId) return;
        this.loading = true;
        try {
            const data = await getBillingContacts({ accountId: this.recordId, searchTerm: this.searchTerm });
            this.rows = (data || []).map(d => ({
                ...d,
                contactUrl: `/lightning/r/Contact/${d.contactId}/view`
            }));
            this.page = 1; // reset to first page on new data
        } catch (e) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error loading Billing Contacts',
                message: (e && e.body && e.body.message) ? e.body.message : (e && e.message) ? e.message : 'An unexpected error occurred.',
                variant: 'error',
                mode: 'dismissible'
            }));
            this.rows = [];
            this.page = 1;
        } finally {
            this.loading = false;
        }
    }
}