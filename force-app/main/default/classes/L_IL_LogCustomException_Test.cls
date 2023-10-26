@isTest
public class L_IL_LogCustomException_Test {

    @isTest
    public static void LogException_Test() {
        try {
            Account acc = new Account();
            insert acc;
        } catch (Exception ex) {
            L_IL_LogCustomException.LogException(ex, 'None', 'Error');
        }    
    } 
}