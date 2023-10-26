public without sharing class I_ST_OrgWideEmailAddressUtil {

    @invocableMethod(label='Get OrgWideEmailAddress Id')
    public static List<String> getOrgWideEmailAddressId(List<String> displayNames) {

        List<String> orgWideEmailAddressIds = new List<String>();
        List<OrgWideEmailAddress> orgWideEmailAddresses = [SELECT Id  FROM OrgWideEmailAddress WHERE DisplayName IN: displayNames];

        if (orgWideEmailAddresses.isEmpty()) {
            throw new I_ST_SendEmail.InvocableActionException
                ('There is no org wide email address for ' + displayNames[0]);
        }

        for(OrgWideEmailAddress owea : orgWideEmailAddresses) {
            orgWideEmailAddressIds.add(owea.Id);
        }
        
        return orgWideEmailAddressIds;
    }
}