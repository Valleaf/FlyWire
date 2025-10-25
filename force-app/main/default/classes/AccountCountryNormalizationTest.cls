@IsTest
private class AccountCountryNormalizationTest {

    @IsTest
    static void normalizeCountryOnInsert() {

        List<Account> accts = new List<Account>{
            TestDataFactory.createAccount('A1', 'US'),
            TestDataFactory.createAccount('A2', 'U.S.'),
            TestDataFactory.createAccount('A3', 'United States of America'),
            TestDataFactory.createAccount('A4', 'U.K'),
            TestDataFactory.createAccount('A5', 'United   Kingdom'),
            TestDataFactory.createAccount('A6', 'Canada'),
            TestDataFactory.createAccount('A7', 'Fra')
        };

        Test.startTest();
        insert accts;
        Test.stopTest();

        Map<String, String> expected = new Map<String, String>{
            'A1' => 'United States of America',
            'A2' => 'United States of America',
            'A3' => 'United States of America',
            'A4' => 'United Kingdom',
            'A5' => 'United Kingdom',
            'A6' => 'Canada',
            'A7' => 'France'
        };
        for (Account a : [SELECT Name, ShippingCountry FROM Account WHERE Name LIKE 'A%']) {
            Assert.areEqual(expected.get(a.Name), a.ShippingCountry, 'Mismatch for ' + a.Name);
        }
    }

    @IsTest
    static void normalizeCountryOnUpdate() {

        Account a = TestDataFactory.createAccount('B1', 'US');
        Account b = TestDataFactory.createAccount('B2', 'Canada');
        insert new List<Account>{a, b};

        a.ShippingCountry = 'U S A';
        b.ShippingCountry = 'UK'; // 
        
        Test.startTest();
        update new List<Account>{a, b};
        Test.stopTest();

        Map<String, String> expected = new Map<String, String>{
            'B1' => 'United States of America',
            'B2' => 'United Kingdom'
        };
        for (Account acc : [SELECT Name, ShippingCountry FROM Account WHERE Name LIKE 'B%']) {
            Assert.areEqual(expected.get(acc.Name), acc.ShippingCountry, 'Mismatch for ' + acc.Name);
        }
    }


    @IsTest
    static void normalizeCountryNull() {

        Account a = TestDataFactory.createAccount('Blank', '');
        insert a;
        a = [SELECT ShippingCountry FROM Account WHERE Id = :a.Id];
        Assert.isNull(a.ShippingCountry, 'Empty string should remain null after insert.');

        a.ShippingCountry = null;

        
        Test.startTest();
        update a;
        Test.stopTest();

        a = [SELECT ShippingCountry FROM Account WHERE Id = :a.Id];
        Assert.isNull(a.ShippingCountry, 'Null should remain null after update.');

    }

    @IsTest
    static void normalizeCountryMass() {
        // Build variants 
        List<String> usVariants = new List<String>{ 'US', 'U.S.', 'U S A', 'United States of America' };
        List<String> ukVariants = new List<String>{ 'UK', 'U.K', 'United   Kingdom', 'Great Britain', 'GB' };

        List<Account> accts = new List<Account>();

        // 120 US variants (rotate through usVariants)
        Integer usIdx = 0;
        for (Integer i = 1; i <= 120; i++) {
            String variant = usVariants[usIdx];
            usIdx++;
            if (usIdx == usVariants.size()) {
                usIdx = 0;
            }
            accts.add(TestDataFactory.createAccount('Mass_US_' + i, variant));
        }

        // 80 UK variants (rotate through ukVariants)
        Integer ukIdx = 0;
        for (Integer i = 1; i <= 80; i++) {
            String variant = ukVariants[ukIdx];
            ukIdx++;
            if (ukIdx == ukVariants.size()) ukIdx = 0;
            accts.add(TestDataFactory.createAccount('Mass_UK_' + i, variant));
        }

        // 40 unchanged (Spain)
        for (Integer i = 1; i <= 40; i++) {
            accts.add(TestDataFactory.createAccount('Mass_CA_' + i, 'Spain'));
        }

        Test.startTest();
        insert accts;
        Test.stopTest();

        // Verify results
        Integer usCount = 0, ukCount = 0, caCount = 0;
        for (Account a : [SELECT Name, ShippingCountry FROM Account WHERE Name LIKE 'Mass_%']) {
            if (a.ShippingCountry == 'United States of America') {
                usCount++;
            } else if (a.ShippingCountry == 'United Kingdom') {
                ukCount++;
            } else if (a.ShippingCountry == 'Spain') {
                caCount++;
            }
        }

        Assert.areEqual(120, usCount, 'Expected 120 Accounts normalized to United States of America');
        Assert.areEqual(80, ukCount, 'Expected 80 Accounts normalized to United Kingdom');
        Assert.areEqual(40, caCount, 'Expected 40 Accounts left as Spain (unchanged)');
    }

}