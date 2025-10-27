public without sharing class LeadTriggerHandler extends TriggerHandler {

    private List<Lead> oldList = (List<Lead>)Trigger.old;
    private List<Lead> newList = (List<Lead>)Trigger.new;
    private Map<Id,Lead> oldMap = (Map<Id,Lead>)Trigger.oldMap;
    private Map<Id,Lead> newMap = (Map<Id,Lead>)Trigger.newMap;

    public override void afterInsert() {
        if (!FeatureManagement.checkPermission('LeadMassConvertBypass')) {
            // Collect Leads with Convert__c = true and start the batch process
            Set<Id> toConvertIds = new Set<Id>();
            for (Lead l : newList) {
                if (l.Convert__c == true) {
                    toConvertIds.add(l.Id);
                }
            }
            if (!toConvertIds.isEmpty()) {
                System.enqueueJob(new LeadMassConvertQueueable(new List<Id>(toConvertIds)));
            }

        }
    }

    public override void afterUpdate() {
        if (!FeatureManagement.checkPermission('LeadMassConvertBypass')) {
            // Collect Leads whose Convert__c flipped to true and are not converted. Do not reprocess those with Conversion_Error__c set.
            Set<Id> toConvertIdsUpdate = new Set<Id>();
            for (Lead l : newList) {
                Lead oldL = oldMap.get(l.Id);
                if (l.Convert__c == true && oldL.Convert__c != true && l.IsConverted == false && l.ConversionError__c == null) {
                    toConvertIdsUpdate.add(l.Id);
                }
            }
            if (!toConvertIdsUpdate.isEmpty()) {
                System.enqueueJob(new LeadMassConvertQueueable(new List<Id>(toConvertIdsUpdate)));
            }
        }
    }

}