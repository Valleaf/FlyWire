public with sharing class BillingContactsController {

    public class BillingContactWrapper {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String name;
        @AuraEnabled public String title;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String accountName;
    }

    /**
     * Fetch billing contacts for the given Account Id, optionally filtered by search term.
     * @param accountId The Id of the Account to fetch billing contacts for.
     * @param searchTerm Optional search term to filter contacts by Name, Email, or Phone.
     * @return List of BillingContactWrapper representing the billing contacts.
     */
    @AuraEnabled(cacheable=true)
    public static List<BillingContactWrapper> getBillingContacts(Id accountId, String searchTerm) {
        try {
            if (accountId == null) {
                System.debug(LoggingLevel.WARN, 'BillingContactsController.getBillingContacts called with null accountId');
                return new List<BillingContactWrapper>();
            }

            Boolean hasSearch = !String.isBlank(searchTerm);
            String likeTerm = hasSearch ? '%' + searchTerm.trim() + '%' : null;

            // Direct billing contacts (on Account)
            // If searchTerm is provided, filter by it on Name, Email, or Phone, otherwise get all
            List<Contact> direct = hasSearch
                ? [
                    SELECT Id, Name, Title, Email, Phone, AccountId, Account.Name
                    FROM Contact
                    WHERE AccountId = :accountId
                      AND Billing_Contact__c = true
                      AND (Name LIKE :likeTerm OR Email LIKE :likeTerm OR Phone LIKE :likeTerm)
                    LIMIT 1000
                  ]
                : [
                    SELECT Id, Name, Title, Email, Phone, AccountId, Account.Name
                    FROM Contact
                    WHERE AccountId = :accountId
                      AND Billing_Contact__c = true
                    LIMIT 1000
                  ];

            // Indirect billing contacts via AccountContactRelation (Related Contacts)
            // If searchTerm is provided, filter by it on Name, Email, or Phone, otherwise get all
            List<AccountContactRelation> acrs = hasSearch
                ? [
                    SELECT Id, AccountId, ContactId,
                           Contact.Id, Contact.Name, Contact.Title, Contact.Email, Contact.Phone,
                           Contact.AccountId, Contact.Account.Name, Contact.Billing_Contact__c
                    FROM AccountContactRelation
                    WHERE AccountId = :accountId
                      AND IsActive = true
                      AND Contact.Billing_Contact__c = true
                      AND (Contact.Name LIKE :likeTerm OR Contact.Email LIKE :likeTerm OR Contact.Phone LIKE :likeTerm)
                    LIMIT 1000
                  ]
                : [
                    SELECT Id, AccountId, ContactId,
                           Contact.Id, Contact.Name, Contact.Title, Contact.Email, Contact.Phone,
                           Contact.AccountId, Contact.Account.Name, Contact.Billing_Contact__c
                    FROM AccountContactRelation
                    WHERE AccountId = :accountId
                      AND IsActive = true
                      AND Contact.Billing_Contact__c = true
                    LIMIT 1000
                  ];

            // Merge & dedupe by Contact Id
            Map<Id, BillingContactWrapper> byId = new Map<Id, BillingContactWrapper>();

            if (direct.isEmpty() && acrs.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'BillingContactsController.getBillingContacts found no billing contacts for accountId: ' + accountId);
                return byId.values();
            }

            if (!direct.isEmpty()) {
                for (Contact c : direct) {
                    BillingContactWrapper cWrap = new BillingContactWrapper();
                    cWrap.contactId   = c.Id;
                    cWrap.name        = c.Name;
                    cWrap.title       = c.Title;
                    cWrap.email       = c.Email;
                    cWrap.phone       = c.Phone;
                    cWrap.accountName = (c.Account != null ? c.Account.Name : null);
                    byId.put(cWrap.contactId, cWrap);
                }
            }

            if (!acrs.isEmpty()) {
                for (AccountContactRelation r : acrs) {
                    Contact c = r.Contact;
                    BillingContactWrapper cWrap = byId.get(c.Id);
                    if (cWrap == null) {
                        cWrap = new BillingContactWrapper();
                        cWrap.contactId   = c.Id;
                        cWrap.name        = c.Name;
                        cWrap.title       = c.Title;
                        cWrap.email       = c.Email;
                        cWrap.phone       = c.Phone;
                        cWrap.accountName = (c.Account != null ? c.Account.Name : null);
                        byId.put(c.Id, cWrap);
                    }
                }
            }

            return byId.values();


        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR,
                'BillingContactsController.getBillingContacts QueryException: ' + qe.getMessage() +
                ' | accountId=' + String.valueOf(accountId) +
                ' | searchTerm=' + String.valueOf(searchTerm));
            throw new AuraHandledException(System.Label.BillingContacts_QueryError);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'BillingContactsController.getBillingContacts unexpected error: ' + e.getMessage() +
                ' | accountId=' + String.valueOf(accountId) +
                ' | searchTerm=' + String.valueOf(searchTerm));
            throw new AuraHandledException(System.Label.BillingContacts_GenericError);
        }
    }
}