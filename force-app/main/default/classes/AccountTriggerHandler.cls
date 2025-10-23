public without sharing class AccountTriggerHandler  extends TriggerHandler{

    private List<Account> oldList = (List<Account>)Trigger.old;
    private List<Account> newList = (List<Account>)Trigger.new;
    private Map<Id,Account> oldMap = (Map<Id,Account>)Trigger.oldMap;
    private Map<Id,Account> newMap = (Map<Id,Account>)Trigger.newMap;

    public override void beforeInsert(){
        // Normalize ShippingCountry on insert i.e. US, U.S. -> United States of America
        if(!FeatureManagement.checkPermission('AccountCountryNormalizationBypass')){
            // Collect only records with a non-null ShippingCountry
            List<Account> accountsToProcess = new List<Account>();
            for (Account acc : newList){
                if (acc.ShippingCountry != null){
                    accountsToProcess.add(acc);
                }
            }
            if (!accountsToProcess.isEmpty()){
                CountryNormalizationUtil.normalizeCountryFields(
                    accountsToProcess,
                    new List<SObjectField>{ Account.ShippingCountry }
                );
            }
        }
    }

    public override void beforeUpdate(){
        // Normalize ShippingCountry on update if it is changed i.e. U S A -> United States of America 
        if(!FeatureManagement.checkPermission('AccountCountryNormalizationBypass')){
            // Only process records where ShippingCountry changed and is not null
            List<Account> accountsToProcess = new List<Account>();
            for (Account acc : newList){
                Account oldAcc = oldMap.get(acc.Id);
                if (acc.ShippingCountry != null && acc.ShippingCountry != oldAcc.ShippingCountry){
                    accountsToProcess.add(acc);
                }
            }
            if (!accountsToProcess.isEmpty()){
                CountryNormalizationUtil.normalizeCountryFields(
                    accountsToProcess,
                    new List<SObjectField>{ Account.ShippingCountry }
                );
            }
        }
    }
}