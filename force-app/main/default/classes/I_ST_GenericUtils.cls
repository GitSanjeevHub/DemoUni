/**
 * @author Jie Tan
 * @date 05/10/2020
 * 
 * @group IST
 * 
 * @description Generic utility class for IST project
 * @Comments: 14-Sep-2021: Changed to WITHOUT sharing to allow the guests users access within the Flow
 */

public without sharing class I_ST_GenericUtils {
    /**
     * @description Encrypt a String
     * @param
     *      algorithm - algorithm for encryption
     *      AESkey - private key for encryption
     *      clearText - String to be encrypted
     * @return Encrypted string
     */
    public static String encrypt(String algorithm, String AESKey, String clearText) {
        Blob key = EncodingUtil.base64Decode(AESKey);
        Blob cipherBlob = Crypto.encryptWithManagedIV(algorithm, key, Blob.valueOf(clearText));
        String cipherText = EncodingUtil.base64Encode(cipherBlob);
        return cipherText;
    }

    /**
     * @description Decrypt a String
     * @param
     *      algorithm - algorithm for decryption
     *      AESkey - private key for decryption
     *      cipherText - String to be decrypted
     * @return Decrypted string
     */
    public static String decrypt(String algorithm, String AESKey, String cipherText) {
        Blob key = EncodingUtil.base64Decode(AESKey);
        Blob clearBlob = Crypto.decryptWithManagedIV(algorithm, key, EncodingUtil.base64Decode(cipherText));
        String clearText = clearBlob.toString();
        return clearText;
    }

    /**
     * @description Populate custom setting I_ST_Scheduler__c values
     * @param N/A
     * @return N/A
     */
    public static void setupScheduler()
	{
        I_ST_Scheduler__c sch = I_ST_Scheduler__c.getOrgDefaults();
		//-------------------------------------------------------//
		//--- if custom setting has no record then create one ---//
		//-------------------------------------------------------//
		if (String.isBlank(sch.I_ST_Private_Key__c))
		{
            Blob key = Crypto.generateAesKey(128);
			insert new I_ST_Scheduler__c(
                SetupOwnerId = UserInfo.getOrganizationId(),
                I_ST_Private_Key__c = EncodingUtil.base64Encode(key)
            );
		}
	}

    /**
     * @description Get private key from custom setting I_ST_Scheduler__c
     * @param N/A
     * @return N/A
     */
    public static String getKey()
	{
        return I_ST_Scheduler__c.getInstance().I_ST_Private_Key__c;
	}

    /**
     * @description Cast picklist fields due to issue with passing sObjects to invocable methods
     * @param
     *      records - records with picklist fields to cast
     * @return A list of records with casted picklists
     */
    public static List<SObject> setPicklists(List<SObject> records) {
        DescribeSObjectResult d = records.getSObjectType().getDescribe();
        for(SObject record : records) {
            for(String fieldName : record.getPopulatedFieldsAsMap().keySet()) {
                if(String.ValueOf(d.fields.getMap().get(fieldName).getDescribe().getType()) == 'PICKLIST') {
                    record.put(fieldName, String.valueOf(record.get(fieldName)));
                }
            }
        }
        return records;
    }

    /**
     * @description Save records and bypass duplicate rules
     * @param
     *      records - records to save
     *      operation - DML operation type
     * @return A list of Ids of the saved records
     */
    public static List<String> save(List<SObject> records, String operation) {
        List<String> recordIds = new List<String>();
        List<Database.SaveResult> results = new List<Database.SaveResult>();

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;

        if(operation.equalsIgnoreCase('Insert')) {
            results = Database.insert(records, dml);
        } else if(operation.equalsIgnoreCase('Update')) {
            results = Database.update(records, dml);
        }
        
        for(Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                // DML failed
                for(Database.Error duplicateError : result.getErrors()) {
                    // Verify that record is a dupe before casting
                    if (duplicateError instanceof Database.DuplicateError) {
                        Datacloud.DuplicateResult duplicateResult = ((Database.DuplicateError)duplicateError).getDuplicateResult();
                    } else {
                        // Should catch all other errors 
                        System.debug('Error thrown but not a dupe result');
                        System.debug('Message ' + duplicateError.getMessage());
                        System.debug('Fields ' + duplicateError.getFields());
                    }
                }
            } else {
                System.debug('Contact has been inserted!');
                recordIds.add(result.getId());
            }
        }

        return recordIds;
    }
}