public without sharing class AccountCountryNormalizationBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Target existing data with non-null ShippingCountry
        return Database.getQueryLocator([
            SELECT Id, Name, ShippingCountry
            FROM Account
            WHERE ShippingCountry != null
        ]);
    }

    /**
     * Executes the batch on the given scope of Account records.
     * * Normalizes the ShippingCountry field and updates records if changes were made.
     * @param bc The batchable context.
     * @param scope The list of Account records to process.
     */
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        if (scope.isEmpty()) return;

        Map<Id, String> original = new Map<Id, String>();
        for (Account a : scope) {
            original.put(a.Id, a.ShippingCountry);
        }

        CountryNormalizationUtil.normalizeCountryFields(
            (List<SObject>)scope,
            new List<SObjectField>{ Account.ShippingCountry }
        );

        List<Account> toUpdate = new List<Account>();
        for (Account a : scope) {
            String before = original.get(a.Id);
            String after  = a.ShippingCountry;
            if (after != null && before != after) {
                toUpdate.add(a);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    /**
     * Utility method to run the batch with the given scope size.
     * @param scopeSize The batch scope size. If null, defaults to 200.
     * @return The Job ID of the batch job.
     */
    public static Id run(Integer scopeSize) {
        return Database.executeBatch(new AccountCountryNormalizationBatch(), scopeSize == null ? 200 : scopeSize);
    }
}