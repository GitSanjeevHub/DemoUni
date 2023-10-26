declare module "@salesforce/apex/ResearchOpportunitySearchController2.getSearchResults" {
  export default function getSearchResults(param: {configName: any, keywordsToSearch_String: any, keywordsToExclude_String: any, filters: any, filterLogic: any, orderBy: any, orderDirection: any, rowLimit: any, offset: any}): Promise<any>;
}
declare module "@salesforce/apex/ResearchOpportunitySearchController2.getUserSavedSearch" {
  export default function getUserSavedSearch(): Promise<any>;
}
declare module "@salesforce/apex/ResearchOpportunitySearchController2.saveUserSearch" {
  export default function saveUserSearch(param: {data: any}): Promise<any>;
}
declare module "@salesforce/apex/ResearchOpportunitySearchController2.getColumns_DatatableMetadata" {
  export default function getColumns_DatatableMetadata(param: {configName: any}): Promise<any>;
}
