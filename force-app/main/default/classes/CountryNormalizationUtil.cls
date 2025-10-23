public without sharing class CountryNormalizationUtil {
    /**
     * Normalizes country fields on the given records. Done in before triggers, without DML.
     * @param records List of SObjects to process.
     * @param fields List of SObjectFields representing country fields to normalize.
     */
    public static void normalizeCountryFields(List<SObject> records, List<SObjectField> fields) {
        if (records == null || records.isEmpty() || fields == null || fields.isEmpty()) {
            System.debug('CountryNormalizationUtil: No records or fields to process.');
            return;
        }

        // Iterate over each record and normalize specified country fields
        for (SObject sob : records) {
            for (SObjectField fieldToken : fields) {
                // Get the current value of the country field
                Object val = sob.get(fieldToken);
                // Check if the field is null or not a String
                if (val == null || !(val instanceof String)) {
                    System.debug('CountryNormalizationUtil: Field ' + fieldToken + ' is null or not a String. Skipping normalization.');
                    continue;
                }

                String before = (String) val;
                String after = CountryNormalizationService.normalizeCountry(before);
                // Update the field only if normalization changed the value
                if (after != null && after != before) {
                    sob.put(fieldToken, after);
                }
            }
        }
    }
}