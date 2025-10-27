@IsTest
public class TestDataFactory {

    // Accounts
    public static Account createAccount(String name) {
        return new Account(Name = name);
    }

    public static Account createAccount(String name, String shippingCountry) {
        Account a = createAccount(name);
        a.ShippingCountry = shippingCountry;
        return a;
    }

    // Leads
    public static Lead createLead(String lastName) {
        return new Lead(
            LastName = lastName,
            Company  = lastName + ' Company'
        );
    }

    public static Lead createLead(String lastName, Boolean convertFlag) {
        Lead l = createLead(lastName);
        l.Convert__c = convertFlag;
        return l;
    }

    // Contacts
    public static Contact createContact(String lastName, Account acc, Boolean isBilling) {
        return createContact(lastName, acc != null ? acc.Id : null, isBilling, null, null);
    }
    public static Contact createContact(String lastName, Id accountId, Boolean isBilling) {
        return createContact(lastName, accountId, isBilling, null, null);
    }
    public static Contact createContact(String lastName, Id accountId, Boolean isBilling, String email, String phone) {
        Contact c = new Contact(
            LastName = lastName,
            AccountId = accountId,
            Billing_Contact__c = isBilling
        );
        c.Email = (email != null) ? email : lastName.toLowerCase().replace(' ', '') + '@example.com';
        c.Phone = (phone != null) ? phone : '555-0100';
        return c;
    }

    // AccountContactRelation
    public static AccountContactRelation createAcr(Account acc, Contact con, Boolean isActive) {
        return new AccountContactRelation(
            AccountId = acc.Id,
            ContactId = con.Id,
            IsActive  = isActive
        );
    }
}