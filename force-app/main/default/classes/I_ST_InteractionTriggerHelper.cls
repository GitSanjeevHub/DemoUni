/**
─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_InteractionTriggerHelper
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author Teja Yenduri
* @date 2022-02-18
* 
* @group IST(2)
* 
* @description : This class is used For Interaction trigger helper methods
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public class I_ST_InteractionTriggerHelper {
     //IST - This static method is used to calculate the Incremental Score on the Case object
    public static void calculateIncrementalScoreOnInteraction(String sobjectName, String interactionIncrementField, Set<Id> recordTypeIds,List<I_ST_Interaction__c> interactions){
         I_ST_IncrementalScoreContactRelObject.calcIncrementalScoreContactRelObject(sobjectName, interactionIncrementField,recordTypeIds,interactions,null);   
    }
}