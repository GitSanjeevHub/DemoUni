public class ReportMetadataAccess {
    
    @AuraEnabled(cacheable=true)
    public static Report getReportMetadata(String reportAPIName) {

        System.debug('getReportMetadata '+reportAPIName);

        Report report = [select Id from Report where DeveloperName = :reportAPIName];
        System.debug(report);

        return report;

    }


    @AuraEnabled(cacheable=true)
    public static String getReportPortalURL(String reportAPIName){

        Report report = getReportMetadata(reportAPIName);

        URL_Variable__c baseURLsVariable = URL_Variable__c.getOrgDefaults();
        String researcherPortalBaseURL =  baseURLsVariable.I_RS_Researcher_Portal_Base_URL__c;

        String reportURL = researcherPortalBaseURL + '/report/'+report.Id;

        System.debug('reportURL '+reportURL);

        return reportURL;

    }
}