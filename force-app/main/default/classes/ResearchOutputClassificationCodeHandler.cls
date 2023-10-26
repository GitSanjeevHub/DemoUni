public class ResearchOutputClassificationCodeHandler {
    private static ResearchOutputClassificationCodeHelper ResearchOutputClassificationCodeUtil;

    public static void execute() {
        ResearchOutputClassificationCodeUtil = new ResearchOutputClassificationCodeHelper();
        
        // Check for event type of trigger
        if(Trigger.isBefore ){
            beforeHandler();
        }
    }

    private static void beforeHandler(){
        if((Trigger.isInsert) || (Trigger.isUpdate)){ 
            ResearchOutputClassificationCodeUtil.validateUserIsPartOfAuthorship((List<Research_Output_Classification_Code__c>)Trigger.New);
        }
    }
    
}