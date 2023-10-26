/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* I_ST_CaseTriggerHandler
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Teja Yenduri   <tyenduri@au1.ibm.com>
* @version        1.0
* @created        2021-08-20
* ─────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* v1.0           Teja Yenduri
* 2021-01-19      Created
@changes
*v1.1			Rahul Kumar
* 20222-01-18 	Updated
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/ 
public without sharing class I_ST_CaseTriggerHandler{
    
    private static Boolean hasFired = false;    
    
    public static Boolean hasFired() {
        return hasFired;
    }
    
    public static void setFired() {
        hasFired = true;
    }
    
    public static void setNotFired() {
        hasFired = false;
    }
    
       public static void execute(){
        //Will use I_ST_CaseTriggerHelper Here
        if((Trigger.isBefore && Trigger.isInsert) ||(trigger.isBefore && Trigger.isupdate)){
            	I_ST_CaseTriggerHelper.updateContactOnCase(Trigger.new);
            	I_ST_CaseTriggerHelper.updateAffiliation(Trigger.new); 
        }
        
        
        if((Trigger.isAfter && Trigger.isInsert) ||(trigger.isAfter && Trigger.isupdate)) {          
            if(!hasFired){
            	I_ST_CaseTriggerHelper.calculateCaseScoring();
            }
        } 
        
    } 
}