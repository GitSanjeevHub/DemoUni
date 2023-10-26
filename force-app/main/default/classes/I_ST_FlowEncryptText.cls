/**
 * @author Jie Tan
 * @date 05/10/2020
 * 
 * @group IST
 * 
 * @description To provide an invocable method for flows to encrypt a string
 */

global with sharing class I_ST_FlowEncryptText {
    /**
     * @description Encrypt a List of Strings with AES128 and handle URL special characters
     * @param
     *      inputs - a List of String to be encrypted
     * @return Encrypted string
     */
    @InvocableMethod(label='Encrypt URL Strings')
    global static List<String> getEncryptedStrings(List<String> inputs)
    {
        List<String> outputs = new List<String>();
        String key = I_ST_GenericUtils.getKey();

        for(String input : inputs) {
            String output = I_ST_GenericUtils.encrypt('AES128', key, input);
            // '+' & '/' are special characters in URL
            output = output.replace('+', '-').replace('/', '_');
            outputs.add(output);
        }
        
        return outputs;
    }
}