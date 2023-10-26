@isTest(seeAllData=true)
public class ReportMetadataAccessTest {

    public static testmethod void linkedReportURLAccessTest() {

        if (URL_Variable__c.getOrgDefaults() == null){
            insert new URL_Variable__c(
                I_RS_Researcher_Portal_Base_URL__c = 'https://latrobe.prime.edu.au/s'
            );
        }

        Report anyRandomReport = [select DeveloperName from Report LIMIT 1];

        system.assert(
            ReportMetadataAccess.getReportPortalURL(anyRandomReport.DeveloperName)
            != null
        );

    }
}