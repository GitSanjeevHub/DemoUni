public class FlowUtility {

    @InvocableMethod(label='Check if record is locked')
    public static List<RecordLockedResult> checkIfRecordIsLocked(List<Id> recordIds){
        
        List<RecordLockedResult> recordLockedResults = new List<RecordLockedResult>();

        for (Id recordId : recordIds){
            
            RecordLockedResult result = new RecordLockedResult();
            result.recordId = recordId;        
            result.isLocked = Approval.isLocked(recordId);
            
            recordLockedResults.add(result);
        }
        
        system.debug('recordLockedResults '+recordLockedResults);
        return recordLockedResults;
    }
    
    public class RecordLockedResult {
      @InvocableVariable(required=true)
	  public Id recordId;
      @InvocableVariable(label='Record Is Locked' required=true)
	  public Boolean isLocked;
    }
	
    
}