@IsTest
public class TestDataFactory {

    public static Account createAccount(String name) {
        return new Account(Name = name);
    }

    public static Account createAccount(String name, String shippingCountry) {
        Account a = createAccount(name);
        a.ShippingCountry = shippingCountry;
        return a;
    }
}