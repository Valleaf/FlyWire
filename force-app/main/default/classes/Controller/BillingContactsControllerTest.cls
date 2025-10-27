@IsTest
private class BillingContactsControllerTest {

    @testSetup
    static void setupData() {

        // Accounts
        Account accA = TestDataFactory.createAccount('Test Account A');
        Account accB = TestDataFactory.createAccount('Test Account B');
        insert new List<Account>{ accA, accB };

        // Contacts 
        Contact directBilling      = TestDataFactory.createContact('DirectBilling', accA, true);
        Contact directNonBilling   = TestDataFactory.createContact('DirectNonBilling', accA, false);
        Contact indirectBilling    = TestDataFactory.createContact('IndirectBilling', accB, true);
        Contact indirectNonBilling = TestDataFactory.createContact('IndirectNonBilling', accB, false);

        // Set emails/phones for search testing
        directBilling.Email = 'direct.billing@example.com';
        directBilling.Phone = '555-0101';
        indirectBilling.Email = 'indirect.billing@example.com';
        indirectBilling.Phone = '555-0103';

        insert new List<Contact>{ directBilling, directNonBilling, indirectBilling, indirectNonBilling };

        // ACRs
        AccountContactRelation acr1 = TestDataFactory.createACR(accA, indirectBilling, true);
        AccountContactRelation acr2 = TestDataFactory.createACR(accA, indirectNonBilling, true);
        insert new List<AccountContactRelation>{ acr1, acr2 };
    }

    @IsTest
    static void testFindDirectAndIndirectContacts() {
        Account accA = [SELECT Id FROM Account WHERE Name = 'Test Account A' LIMIT 1];

        Test.startTest();
        List<BillingContactsController.BillingContactWrapper> result =
            BillingContactsController.getBillingContacts(accA.Id, null);
        Test.stopTest();

        Assert.areEqual(2, result.size(), 'Expected exactly 2 billing contacts for Account A.');

        Set<String> names = new Set<String>();
        for (BillingContactsController.BillingContactWrapper w : result) {
            names.add(w.name);
            Assert.isTrue(w.contactId != null, 'Wrapper must include contactId.');
            Assert.isTrue(!String.isBlank(w.name), 'Wrapper must include name.');
        }

        Assert.isTrue(names.contains('DirectBilling'), 'Missing direct billing contact.');
        Assert.isTrue(names.contains('IndirectBilling'), 'Missing indirect billing contact via ACR.');
        Assert.isTrue(!names.contains('DirectNonBilling'), 'Non-billing direct contact should not be returned.');
        Assert.isTrue(!names.contains('IndirectNonBilling'), 'Non-billing indirect contact should not be returned.');
    }

    @IsTest
    static void testFilterName() {

        Account accA = [SELECT Id FROM Account WHERE Name = 'Test Account A' LIMIT 1];

        Test.startTest();
        List<BillingContactsController.BillingContactWrapper> byName =
            BillingContactsController.getBillingContacts(accA.Id, 'DirectBilling');
        Test.stopTest();

        Assert.areEqual(2, byName.size(), 'Search by name should return exactly two contact.');
    }
    @IsTest
    static void testFilterEmail() {
        Account accA = [SELECT Id FROM Account WHERE Name = 'Test Account A' LIMIT 1];

        Test.startTest();
        List<BillingContactsController.BillingContactWrapper> byEmail =
            BillingContactsController.getBillingContacts(accA.Id, 'indirect.billing@example.com');
        Test.stopTest();

        Assert.areEqual(1, byEmail.size(), 'Search by email should return exactly one contact.');
        Assert.areEqual('IndirectBilling', byEmail[0].name, 'Expected IndirectBilling to match email search.');

    }
    @IsTest
    static void testFilterPhone() {
        Account accA = [SELECT Id FROM Account WHERE Name = 'Test Account A' LIMIT 1];

        Test.startTest();
        List<BillingContactsController.BillingContactWrapper> byPhone =
            BillingContactsController.getBillingContacts(accA.Id, '555-0101');
        Test.stopTest();

        Assert.areEqual(1, byPhone.size(), 'Search by phone should return exactly one contact.');
        Assert.areEqual('DirectBilling', byPhone[0].name, 'Expected DirectBilling to match phone search.');
    }

    @IsTest
    static void testEmpty() {
        Test.startTest();
        List<BillingContactsController.BillingContactWrapper> result =
            BillingContactsController.getBillingContacts(null, null);
        Test.stopTest();

        Assert.areEqual(0, result.size(), 'Null accountId should return an empty list.');
    }
}