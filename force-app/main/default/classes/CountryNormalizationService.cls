public without sharing class CountryNormalizationService {
    private static Map<String, String> aliasToStandard;


    // Lazy init of cache
    private static Map<String, String> getAliasMap() {
        if (aliasToStandard == null) {
            aliasToStandard = buildAliasMap();
        }
        return aliasToStandard;
    }

    /**
     * Builds the alias-to-standard country name map from CMDT records.
     * Prefer CMDT.getAll() (no SOQL) and fallback to SOQL if any Aliases__c value is at/over 255 chars.
     * WARNING: CountryName__mdt.getAll() truncates text-area fields to 255 chars. If we detect 255,
     * we use SOQL to read the full value set.
     * @return Map of normalized alias keys to standard country names.
     */
    private static Map<String, String> buildAliasMap() {
        // Try getAll() first
        List<CountryName__mdt> records = CountryName__mdt.getAll().values();
        Boolean requiresSoql = false;

        for (CountryName__mdt rec : records) {
            if (!String.isBlank(rec.Aliases__c) && rec.Aliases__c.length() >= 255) {
                requiresSoql = true;
                break;
            }
        }

        if (requiresSoql) {
            System.debug('CountryNormalizationService: Aliases__c length >= 255 detected via getAll(); falling back to SOQL to avoid truncation.');
            records = [
                SELECT MasterLabel, Aliases__c
                FROM CountryName__mdt
            ];
        } 

        return buildAliasMapFromRecords(records);
    }

    /**
     * Builds the alias-to-standard country name map from the given CMDT records.
     * @param records List of CountryName__mdt records.
     * @return Map of normalized alias keys to standard country names.
     */
    private static Map<String, String> buildAliasMapFromRecords(List<CountryName__mdt> records) {
        Map<String, String> mapOut = new Map<String, String>();
        for (CountryName__mdt rec : records) {
            String standard = rec.MasterLabel != null ? rec.MasterLabel.trim() : null;
            if (String.isBlank(standard)){
                System.debug('CountryNormalizationService: Skipping CMDT record with blank MasterLabel.');
                continue;
            } 

            String standardKey = normalizeKey(standard);
            if (!String.isBlank(standardKey)) {
                mapOut.put(standardKey, standard);
            }

            if (!String.isBlank(rec.Aliases__c)) {
                for (String alias : rec.Aliases__c.split('\\s*;\\s*')) {
                    if (String.isBlank(alias)){
                        System.debug('CountryNormalizationService: Skipping blank alias in CMDT record for ' + standard);
                        continue;
                    } 
                    String key = normalizeKey(alias);
                    if (!String.isBlank(key) && !mapOut.containsKey(key)) {
                        mapOut.put(key, standard);
                    }
                }
            }
        }
        return mapOut;
    }

    /**
     * Normalizes the input string to create a consistent key for alias mapping.
     * Converts to lowercase and removes non-alphabetic characters.
     * @param input The input country name or alias.
     * @return The normalized key string.
     */
    private static String normalizeKey(String input) {
        if (String.isBlank(input)){
            System.debug('CountryNormalizationService: Input for key normalization is blank or null.');
            return null;
        } 
        String s = input.toLowerCase();
        s = s.replaceAll('[^a-z]', ''); // remove punctuation, spaces, digits
        return s;
    }

        /**
     * Normalize the given country name to its standard form based on CMDT mappings.
     * If no mapping is found, returns the trimmed original input.
     * @param input The country name or alias to normalize.
     * @return The normalized country name or the original trimmed input if no mapping exists.
     */
    public static String normalizeCountry(String input) {
        if (String.isBlank(input)){
            System.debug('CountryNormalizationService: Input is blank or null. Returning as is.');
            return input;
        } 
        String key = normalizeKey(input);
        if (String.isBlank(key)){
            System.debug('CountryNormalizationService: Normalized key is blank. Returning trimmed input.');
            return input.trim();
        } 

        String standard = getAliasMap().get(key);
        return standard != null ? standard : input.trim();
    }


}