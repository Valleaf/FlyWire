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
}