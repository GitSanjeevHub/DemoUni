/**
 * @author: Sush
 * @date : 21/06/2019
 * @description : Schedulable class that fetches the Opportunity records from  Research Professional system and store under staging object in SFDC.
 */

global class ResearchProfessionalREST implements Schedulable {
    
    public Integer startingPageIndex{get; private set;}
    public Integer pageRetryCount{get; private set;}

    global ResearchProfessionalREST(Integer pageIndex){
        this.startingPageIndex = pageIndex;
        this.pageRetryCount = 0;
    }

    global ResearchProfessionalREST(Integer startingPageIndex, Integer pageRetryCount){
        this.startingPageIndex = startingPageIndex;
        this.pageRetryCount = pageRetryCount;
    }

	global void execute(SchedulableContext SC) {
        // Schedule job to callout REST API serivce to get Opportunity records from Research Professional system.
        system.debug('get into REST class');
        System.enqueueJob(new ResearchProfessionalService(startingPageIndex, pageRetryCount));
    }
}