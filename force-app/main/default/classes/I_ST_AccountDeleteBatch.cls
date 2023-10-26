/* created by : IST Team On 05-11-2020*/

global class I_ST_AccountDeleteBatch implements Database.Batchable<sobject>{
    
    //RecordType objrt = [select id from RecordType where sObjectType='Account' and DeveloperName='I_ST_Lead_Account'];
    
    global Database.Querylocator start (Database.BatchableContext BC) {
        
        String accID='0014Y000006gpP2'; // put test account id
        String rec ='I_ST_Lead_Account';
        //String query = 'Select Id FROM Account WHERE RecordType.DeveloperName=:rec AND ID=:accID'; //remove ID filter when running on actual data
        String query = 'Select Id FROM Account WHERE RecordType.DeveloperName=:rec';
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext BC, List<Account> lstAccountId) {
        
        List<AccountContactRelation> indirectRelationIds = new List<AccountContactRelation>();        
        Set<Id> directRelationIds = new Set<Id>();
        Set<Id> deleteAccountIds = new Set<Id>();
        
        System.debug('****'+lstAccountId);
        
        for(AccountContactRelation a : [Select Id, AccountID, IsDirect FROM AccountContactRelation WHERE AccountID IN:lstAccountId]){    
            if(a.IsDirect == false){
                indirectRelationIds.add(a);
            }else{
                directRelationIds.add(a.AccountID);
            }
        }
        System.debug('****ACR***'+indirectRelationIds);
        //delete indirectRelationIds; // Delete ACR which has indirect Relationship
        
        Database.DeleteResult[] drListACR = Database.delete(indirectRelationIds, false); // failing uncomment for investigation
        
        // Extracted the account id those do not have direct ACR  
        for(Account acc : lstAccountId){
            
            //check all accounts which are not in direct ACR account list 
            if(!directRelationIds.contains(acc.Id)){ 
                deleteAccountIds.add(acc.Id);
            }
        }           
        
        //Removed those accounts which are not related to cases.
        List<Case> caseWithDeleteAccounts = new List<Case>([Select Id, AccountID FROM Case WHERE AccountId IN :deleteAccountIds]);      
        for(Case c : caseWithDeleteAccounts){           
            deleteAccountIds.remove(c.AccountID); 
        }
        
        List<Id> lstDelete = new List<Id>();
        for(Id objId :deleteAccountIds){
            lstDelete.add(objId);
        }
        System.Debug('###'+lstDelete);
        Database.DeleteResult[] drList = Database.delete(lstDelete, false); // delete account if has no case and contact relation
    }
    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    } 
}