public class AccountContactRelationHelper {
    public static void updateStartAndEndDates(Map<Id, AccountContactRelation> oldACRs, List<AccountContactRelation> newACRs){
        if (oldACRs == null) {
            for (AccountContactRelation acr: newACRs) {
                acr.StartDate = Date.today();
            }
        }  else {
            for (AccountContactRelation acr: newACRs) {
                if ((acr.AccountId != oldACRs.get(acr.Id).AccountId) && (acr.IsDirect)) {
                	acr.StartDate = Date.today();
                }
            }
        }  
        
    }
}