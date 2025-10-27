@IsTest
private class LeadMassConvertTest {


    @isTest
    static void convertOnInsert() {
        // Create two leads; only one will be converted
        Lead a = TestDataFactory.createLead('L1', true);
        Lead b = TestDataFactory.createLead('L2', false);

        Test.startTest();
        insert new List<Lead>{ a, b }; 
        Test.stopTest();               

        Map<String, Boolean> expectedConverted = new Map<String, Boolean>{
            'L1' => true,
            'L2' => false
        };
        for (Lead l : [
            SELECT LastName, IsConverted, ConvertedAccountId, ConvertedContactId, ConversionError__c
            FROM Lead WHERE Id IN :new List<Id>{ a.Id, b.Id }
        ]) {
            Assert.areEqual(expectedConverted.get(l.LastName), l.IsConverted, 'Mismatch for ' + l.LastName);
            if (l.IsConverted) {
                Assert.isNull(l.ConversionError__c, 'No error expected on success for ' + l.LastName);
                Assert.areNotEqual(null, l.ConvertedAccountId, 'Account must be created/linked for ' + l.LastName);
                Assert.areNotEqual(null, l.ConvertedContactId, 'Contact must be created/linked for ' + l.LastName);
            } else {
                Assert.isNull(l.ConversionError__c, 'No error when not requested to convert for ' + l.LastName);
            }
        }
    }

    @IsTest
    static void convertOnUpdate() {
        // Create two leads; only one will be converted
        Lead a = TestDataFactory.createLead('L1', false);
        Lead b = TestDataFactory.createLead('L2', false);
        insert new List<Lead>{ a, b };

        a.Convert__c = true;

        Test.startTest();
        update new List<Lead>{ a, b }; 
        Test.stopTest();               

        Map<String, Boolean> expectedConverted = new Map<String, Boolean>{
            'L1' => true,
            'L2' => false
        };
        for (Lead l : [
            SELECT LastName, IsConverted, ConvertedAccountId, ConvertedContactId, ConversionError__c
            FROM Lead WHERE Id IN :new List<Id>{ a.Id, b.Id }
        ]) {
            Assert.areEqual(expectedConverted.get(l.LastName), l.IsConverted, 'Mismatch for ' + l.LastName);
            if (l.IsConverted) {
                Assert.isNull(l.ConversionError__c, 'No error expected on success for ' + l.LastName);
                Assert.areNotEqual(null, l.ConvertedAccountId, 'Account must be created/linked for ' + l.LastName);
                Assert.areNotEqual(null, l.ConvertedContactId, 'Contact must be created/linked for ' + l.LastName);
            } else {
                Assert.isNull(l.ConversionError__c, 'No error when not requested to convert for ' + l.LastName);
            }
        }
    }

    @IsTest
    static void convertMass() {

        final Integer LEAD_COUNT = 500; 
        // Build 500 leads
        List<Lead> bulkList = new List<Lead>();
        for (Integer i = 1; i <= LEAD_COUNT; i++) {
            bulkList.add(TestDataFactory.createLead('Bulk' + i, false));
        }
        insert bulkList;

        for (Lead l : bulkList) {
            l.Convert__c = true;
        }

        Test.startTest();
        update bulkList; 
        Test.stopTest();

        Integer converted = 0;
        for (Lead l : [SELECT Id, IsConverted FROM Lead WHERE Id IN :bulkList]) {
            if (l.IsConverted) converted++;
        }
        Assert.areEqual(LEAD_COUNT, converted, 'All 500 should be converted');
    }

    @isTest
    static void failureTest(){
        // Empty conversion

        Test.startTest();
        System.enqueueJob(new LeadMassConvertQueueable(new List<Id>{null  }));
        Test.stopTest();

        Lead[] listOfLeads = [SELECT Id FROM Lead];
        // Shoul be empty
        Assert.areEqual(0, listOfLeads.size(), 'No leads should be created');
       

    }
}