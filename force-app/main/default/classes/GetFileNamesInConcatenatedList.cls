public with sharing class GetFileNamesInConcatenatedList {
    
    @InvocableMethod
    public static List<String> getFileNamesInConcatenatedList(List<Id> recordIds) {

        List<String> concatenatedStrings = new List<String>();
        
        Map<Id, ContentDocumentLink> links = new Map<Id, ContentDocumentLink>([
            SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink
            WHERE LinkedEntityId IN :recordIds]);
        System.debug('links '+links);

        for (Id recordId : recordIds){
            System.debug('recordId '+recordId);

            List<String> namesForThisRecord = new List<String>();

            for (ContentDocumentLink link : links.values()){
                namesForThisRecord.add((String) link.getSObject('ContentDocument').get('Title'));
            }

            if (!namesForThisRecord.isEmpty()){
                String concatenatedNamesForThisRecord = String.join(namesForThisRecord, '\n');
                System.debug('concatenatedNamesForThisRecord '+concatenatedNamesForThisRecord);
                concatenatedStrings.add(concatenatedNamesForThisRecord);
            }
            else {
                concatenatedStrings.add('');
            }
        }

        return concatenatedStrings;
    }
}