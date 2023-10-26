/**
 * @author Jie Tan
 * @date 05/10/2020
 * 
 * @group IST
 * 
 * @description To provide an invocable method for flows to decrypt a string
 * @Comments: 14-Sep-2021: Changed to WITHOUT sharing to allow the guests users access within the Flow
 */

global without sharing class I_ST_FlowDecryptText {
    /**
     * @description Decrypt a List of Strings with AES128 and handle URL special characters
     * @param
     *      inputs - a List of Strings to be decrypted
     * @return Decrypted string
     */
    @InvocableMethod(label='Decrypt URL Strings')
    global static List<String> getDecryptedStrings(List<String> inputs)
    {
        List<String> outputs = new List<String>();
        String key = I_ST_GenericUtils.getKey();

        for(String input : inputs) {
            //decode any url encoding
            input = EncodingUtil.urlDecode(input, 'UTF-8');

            // '+' & '/' are special characters in URL
            input = input.replace('-', '+').replace('_', '/');
            String output = I_ST_GenericUtils.decrypt('AES128', key, input);
            outputs.add(output);
        }
        
        return outputs;
    }
}