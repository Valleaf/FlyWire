@IsTest
private class AccountCountryNormalizationBatchTest {

    @IsTest
    static void testNormalizeBatch() {
        // Create records with mixed inputs
        List<Account> accts = new List<Account>{
            TestDataFactory.createAccount('B1', 'US'),
            TestDataFactory.createAccount('B2', 'U.S.'),
            TestDataFactory.createAccount('B3', 'UK'),
            TestDataFactory.createAccount('B4', 'United   Kingdom'),
            TestDataFactory.createAccount('B5', 'Canada') // unchanged
        };
        insert accts;

        Test.startTest();
        Id jobId = AccountCountryNormalizationBatch.run(200);
        Test.stopTest();

        // Verify canonicalization
        Map<String, String> expected = new Map<String, String>{
            'B1' => 'United States of America',
            'B2' => 'United States of America',
            'B3' => 'United Kingdom',
            'B4' => 'United Kingdom',
            'B5' => 'Canada'
        };
        for (Account a : [SELECT Name, ShippingCountry FROM Account WHERE Name LIKE 'B%']) {
            Assert.areEqual(expected.get(a.Name), a.ShippingCountry, 'Mismatch for ' + a.Name);
        }
    }
}