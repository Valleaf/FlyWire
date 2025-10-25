public without sharing class LeadMassConvertQueueable implements Queueable {
    private final List<Id> leadIds;
    private final String FAILURE_MSG_PREFIX = System.Label.Lead_MassConv_ErrorPrefix;
    private static final LeadStatus convertStatus = [SELECT Id, ApiName FROM LeadStatus WHERE IsConverted=true LIMIT 1];
    private static final String NOTIF_TYPE_DEVNAME = System.Label.Lead_MassConv_NotificationTypeDevName;

    /** 
     * Constructor
     * @param leadIds List of Lead Ids to convert
     */
    public LeadMassConvertQueueable(List<Id> leadIds) {
        this.leadIds = (leadIds == null) ? new List<Id>() : leadIds;
    }

    /** 
     * Execute method for Queueable
     * @param qc QueueableContext
     * @Description Converts Leads in bulk whose Ids were passed in the constructor. Updates Leads with any conversion errors. Sends a summary Custom Notification to the running user upon completion.
     */
    public void execute(QueueableContext qc) {
        if (leadIds.isEmpty()) {
            System.debug(System.Label.Lead_MassConv_NoIds);
            return;
        }

        // Query leads to convert
        List<Lead> leads = [
            SELECT Id, Name, IsConverted, Convert__c, Company
            FROM Lead
            WHERE Id IN :leadIds
            AND Convert__c = true
            AND IsConverted = false
        ];

        // Convert in bulk and capture errors
        List<Database.LeadConvert> requests = new List<Database.LeadConvert>();
        Map<Id, Lead> mapLeadById = new Map<Id, Lead>(leads);

        for (Lead l : leads) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus(convertStatus.ApiName);
            requests.add(lc);
        }

        if (requests.isEmpty()){
            System.debug(System.Label.Lead_MassConv_NoLeadsAfterFilter);
            return;
        }

        List<Database.LeadConvertResult> results = Database.convertLead(requests);

        // Track outcomes and collect errors
        Integer successCount = 0;
        Integer failureCount = 0;
        List<Lead> toUpdateErrors = new List<Lead>();
        List<String> failedLeadNames = new List<String>();

        for (Database.LeadConvertResult currentResult : results) {
            if (currentResult.isSuccess()) {
                successCount++;
            } else {
                failureCount++;
                Lead srcLead = mapLeadById.get(currentResult.getLeadId());
                if (srcLead != null) {
                    String errMsg = FAILURE_MSG_PREFIX;
                    if (!currentResult.getErrors().isEmpty() && currentResult.getErrors()[0] != null) {
                        errMsg += ': ' + currentResult.getErrors()[0].getMessage();
                    }
                    srcLead.ConversionError__c = errMsg;
                    toUpdateErrors.add(srcLead);
                    if (failedLeadNames.size() < 10) {
                        failedLeadNames.add(srcLead.Name);
                    }
                }
            } 
        }
        if (!toUpdateErrors.isEmpty()) {
            update toUpdateErrors;
        }

        // Post-run summary via Custom Notification
        String title = System.Label.Lead_MassConv_SummaryTitle;
        String body = String.format(
            System.Label.Lead_MassConv_SummaryBody,
            new List<String>{
                String.valueOf(results.size()),
                String.valueOf(successCount),
                String.valueOf(failureCount)
            }
        );
        if (!failedLeadNames.isEmpty()) {
            body += '\n' + String.format(
                System.Label.Lead_MassConv_SummaryFailures,
                new List<String>{
                    String.valueOf(failedLeadNames.size()),
                    String.join(failedLeadNames, ', ')
                }
            );
        }

        try {
            Id notifTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = :NOTIF_TYPE_DEVNAME LIMIT 1].Id;

            Messaging.CustomNotification notif = new Messaging.CustomNotification();
            notif.setNotificationTypeId(notifTypeId);
            notif.setTitle(title);
            notif.setBody(body);
            if (!leads.isEmpty()) {
                notif.setTargetId(leads[0].Id);
            }
            // Send to the running user 
            notif.send(new Set<String>{ String.valueOf(UserInfo.getUserId()) });
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'LeadMassConvertQueueable: Failed to send custom notification: ' + e.getMessage());
        }
    }
}