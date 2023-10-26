//Assumption : Researcher/team Member will be associated to only one organisation.
public without sharing class ProjectTeamMemberHierarchyAccess {
	public static final String SHARE_PROJECT_HIERARCHY_MAP = 'shareProjectHierarchyMap';
	public static final String DELETE_USER_ID_LIST = 'deleteUserIdList';

    //Assumption is that Only Latrobe orgs will have external users
    private static Map<Id, Account> latrobeOrgs;
    // Get only Head of the Orgs (HoS/HoC/HoD) "Account ID" and "Contact IDs" hwo have "Grant access to Project proposal"  in ACR
    private static Map<Id, Set<Id>> latrobeOrgHeads;
    // Get User ID of Head of the Orgs (HoS/HoC/HoD) ContactID & UserID
    private static Map<Id, Id> latrobeOrgHeadsUser;
    // Account Hierarchy Map
    private static Map< Id, set<Id>> latrobeOrgHierarchy;
    // Child Account Map
    private static Map< Id, set<Id>> latrobeOrgChildAccountMap;

    public static void initialiseStaticMapsVariables() {

        Id laTrobeRecordTypeId = 
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('I_RS_La_Trobe_Organisation_Unit').getRecordTypeId();

        //Get me those La Trobe orgs
        latrobeOrgs = new Map<Id, Account>(
            [SELECT Id, ParentId FROM Account 
            WHERE RecordTypeId = :laTrobeRecordTypeId]);
        latrobeOrgHeads = new Map<Id,Set<Id>>();

        //Fo the ACRS under these LTU orgs and where grant acess is true...
        for (AccountContactRelation acr: [SELECT Id, ContactId, AccountId FROM AccountContactRelation WHERE
                                          (AccountId in :latrobeOrgs.keySet())
                                          AND Account.RecordTypeId =: laTrobeRecordTypeId
                                          AND (I_RS_Grant_Project_Proposal_Access__c = TRUE) 
                                          AND (IsActive = True)]) {
            //if (!latrobeOrgHeads.containsKey(acr.AccountId)) {
                //Add all ACR contacts (that are valid) to map (org => contact id set)
                Set<Id> ctIds = latrobeOrgHeads.get(acr.AccountId);
                if (ctIds == null) {
                    ctIds = new Set<Id>();
                }
                ctIds.add(acr.ContactId);
                latrobeOrgHeads.put(acr.AccountId, ctIds);
            //}
        }

        //Copy all contact ids from above nested strucutre into flat set
        set<Id> allctIds = new set<Id>();
        for (set<Id> ctIds: latrobeOrgHeads.values()){
        	allctIds.addAll(ctIds);
        }

        //Create map of contact to user for the contacts above (in the La Trobe org ACRs)
        latrobeOrgHeadsUser = new Map<Id, Id>();
        for (Contact ct: [SELECT Id, I_RS_Related_User__c FROM Contact WHERE Id in :allctIds AND I_RS_Related_User__c != '']) {
            if (!latrobeOrgHeadsUser.containsKey(ct.Id)) {
                System.debug('CTCTID: USRID: ' + ct.Id + ' : ' + ct.I_RS_Related_User__c);
                latrobeOrgHeadsUser.put(ct.Id, ct.I_RS_Related_User__c);
            }
        }

        //For each La Trobe org, get all parents in a map of current org => set of all parent ids
        latrobeOrgHierarchy = new Map< Id, set<Id>>();
        Set<id> accountSet;
        Account loopAccount;
        for (Account a: latrobeOrgs.values()) {
            accountSet = latrobeOrgHierarchy.get(a.Id);
            if (accountSet == null) {
                accountSet = new set<Id>();
                latrobeOrgHierarchy.put(a.Id, accountSet);
            }
            Id pId = a.ParentId;
             while (pId != null) {
                 accountSet.add(pId);
                 loopAccount = latrobeOrgs.get(pId);
                 if (loopAccount != null) {
                    pId = loopAccount.ParentId;
                 } else {
                    pId = null;
                 }
            }
        }

        //
        latrobeOrgChildAccountMap = new Map< Id, set<Id>>();
        Set<id> childAccountSet;
        Set<id> parentAccountSet;
        //For all the keys in the hierarchy (basically all the La Trobe orgs)...
        for (Id i: latrobeOrgs.keySet()) {
            //Get the parent ids for the given org
            parentAccountSet = latrobeOrgHierarchy.get(i);
            if (parentAccountSet != null) {
                for (Id j: parentAccountSet) {

                    childAccountSet = latrobeOrgChildAccountMap.get(j);
                    if (childAccountSet == null) {
                        childAccountSet = new set<Id>();
                    }
                    childAccountSet.add(i);
                    latrobeOrgChildAccountMap.put(j, childAccountSet);
                }
            }
        }
    }

    public static Boolean isAfterUpdateFirstRun = true;

    //This method is used to avoid recursion for after update scenario
    public static Boolean isFirstRunAfter(){
        Boolean retAfterUpdateVal;
        if(isAfterUpdateFirstRun){
            retAfterUpdateVal = true;
            isAfterUpdateFirstRun = false;
        }
        else{
            retAfterUpdateVal = isAfterUpdateFirstRun;
        }
        return retAfterUpdateVal;
    }
    //Returns set of Hierarchy userID for given set of contacts
    public static set<Id> getHierarchyUsers(set<Id> contacts, Map<Id, set<Id>> contactAccountMap) {
    	set<Id> hierarchyUserIds = new set<Id>();
        set<Id> accounts = new set<Id>();
        set<Id> accountsWithHierarchy = new set<Id>();

            system.debug('Contacts 103: ' + contacts);
            system.debug('contactAccountMap 104: ' + contactAccountMap);
        for (Id ct: contacts) {
            if (contactAccountMap.get(ct) != null) {
            system.debug('getHierarchyUsers ct: ' + ct);
            system.debug('getHierarchyUsers contactAccountMap.get(ct): ' + contactAccountMap.get(ct));
        	accounts.addAll(contactAccountMap.get(ct));
            }
        }

        id actId;
        for (Id ac: accounts) {
            actId = ac;
            do {
            	Account act = latrobeOrgs.get(actId);
                if (act != null){
                    accountsWithHierarchy.add(act.Id);
                    actId = act.ParentId;
                } else { actID = null;}
            } while (actID != null);
            //} while ((actID != null) && (actID != ''));
        }

        Set<Id> ctIds;
        Id usr;
        for (Id ac: accountsWithHierarchy) {
            ctIds = latrobeOrgHeads.get(ac);
            if (ctIds != null) {
                for (Id ct: ctIds){
                    usr = latrobeOrgHeadsUser.get(ct);
                    //if ((usr != null) && (usr != '')) {
                    if (usr != null) {
                    	system.debug('ContactID: UserID: ' + ct + ' : ' + usr);
                        hierarchyUserIds.add(usr);
                    }
                }
            }
        }

        return hierarchyUserIds;
    }

    public static void refreshTeamMemberHierarchyShare(){
        initialiseStaticMapsVariables();

        List<Project_Team_Member__c> triggerOld = (List<Project_Team_Member__c>) Trigger.old;
        List<Project_Team_Member__c> triggerNew = (List<Project_Team_Member__c>) Trigger.new;
        Map<Id, Project_Team_Member__c> triggerOldMap = (Map<Id, Project_Team_Member__c>) Trigger.oldMap;

        Set<Id> ppNewModifiedIds = new Set<Id>();
        Set<Id> ppDeleteIds = new Set<Id>();

        //First get list of affected Project_Proposal__c reords(thier teams)
        if (Trigger.isDelete) {
            for (Project_Team_Member__c ppTM: triggerOld) {
            	ppDeleteIds.add(ppTM.I_RS_Project_Proposal__c);
            }
        } else if (Trigger.isInsert) {
            for (Project_Team_Member__c ppTM: triggerNew) {
            	ppDeleteIds.add(ppTM.I_RS_Project_Proposal__c);
            	ppNewModifiedIds.add(ppTM.I_RS_Project_Proposal__c);
            }
        } else if (Trigger.isUpdate) {
            for (Project_Team_Member__c ppTM: triggerNew) {
                if (ppTM.I_RS_Active__c != triggerOldMap.get(ppTM.Id).I_RS_Active__c) {
            		ppDeleteIds.add(ppTM.I_RS_Project_Proposal__c);
                	ppNewModifiedIds.add(ppTM.I_RS_Project_Proposal__c);
                }
            }
        }

        //now get all the user ID active team members of the project proposal
        Map<Id, set<Id>> proposalTMContactsMap = new Map<Id, set<Id>>();
        set<Id> contactIds;
        for (Project_Team_Member__c ppTM: [SELECT ID, I_RS_Project_Proposal__c, I_RS_Project_Team_Member__c, I_RS_Team_Member_User__c FROM Project_Team_Member__c WHERE (I_RS_Project_Proposal__c in :ppDeleteIds) AND (I_RS_Team_Member_User__c != '') AND (I_RS_Active__c = True) AND (IsDeleted = False)]) {
            System.debug('Project_Team_Member__c ppTM: ' + ppTM);
            System.debug('ppTM.I_RS_Project_Team_Member__c: ' + ppTM.I_RS_Project_Team_Member__c);

            //for some strange reason in "after delete" the above SOQL fetches the deleted team member, so do not include the deleted team member
            if ((!Trigger.isDelete) || (triggerOldMap.get(ppTM.Id)) == null) {
                if (ppTM.I_RS_Project_Team_Member__c != null) {
                    if (proposalTMContactsMap.containsKey(ppTM.I_RS_Project_Proposal__c)) {
                        contactIds = proposalTMContactsMap.get(ppTM.I_RS_Project_Proposal__c);
                        contactIds.add( ppTM.I_RS_Project_Team_Member__c);
                    } else {
                        contactIds = new Set<Id>();
                        contactIds.add(ppTM.I_RS_Project_Team_Member__c);
                        proposalTMContactsMap.put(ppTM.I_RS_Project_Proposal__c, contactIds);
                    }
                }
            }
        }

        recalculateAllRelatedObjectHierarchyShares(ppDeleteIds, getProposalHierarchyUserMap(proposalTMContactsMap));
    }

    public static Map<Id, set<Id>> getProposalHierarchyUserMap(Map<Id, set<Id>> proposalTMContactsMap) {
        //now get the associated account of all the contacts
        set<Id> allContacts = new set<Id>();
        for (set<Id> ids: proposalTMContactsMap.values()) {
            allContacts.addAll(ids);
        }
		System.debug('allContacts 238: ' + allContacts);
        Map<Id,Set<Id>> contactAccountMap = new Map<Id,set<Id>>();
        for (AccountContactRelation acr : [SELECT ContactId, AccountId FROM AccountContactRelation WHERE ContactId in :allContacts AND IsActive = True]){
            set<Id> accts = contactAccountMap.get(acr.ContactId);
            if (accts == null) {
                accts = new set<Id>();
            }
            accts.add(acr.AccountId);
            contactAccountMap.put(acr.ContactId, accts);
        }
        System.debug('contactAccountMap 248: ' + contactAccountMap);
        //Get the hierarchy user for each proposal for whom the record access should open up
        Map<Id, set<Id>> proposalHierarchyUsersMap = new Map<Id, set<Id>>();
        for (Id ppId: proposalTMContactsMap.keyset()) {
            Set<Id> hierarchyUsers = getHierarchyUsers(proposalTMContactsMap.get(ppId), contactAccountMap);
            proposalHierarchyUsersMap.put(ppId, hierarchyUsers);
        }
        System.debug('proposalHierarchyUsersMap 255:'+proposalHierarchyUsersMap);
        return proposalHierarchyUsersMap;
    }

    public static void calculateHierarchySharesForACR(List<AccountContactRelation> acrs, Map<Id, AccountContactRelation> OldACRMap){
        set<Id> allContacts = new set<Id>();
        for (AccountContactRelation acr: acrs) {
            if ((oldACRMap == null) ||
               ((acr.I_RS_Grant_Project_Proposal_Access__c == oldACRMap.get(acr.Id).I_RS_Grant_Project_Proposal_Access__c) &&
                (acr.IsActive != oldACRMap.get(acr.Id).IsActive))){
            	allContacts.add(acr.ContactId);
            }
        }
        System.debug('calculateHierarchySharesForACR 267: ' + allContacts);
        if (allContacts.size() > 0){
        	System.enqueueJob(new HierarchySharesForContactsQueueable(allContacts, null, false, false));
        }
    }

    //public static void calculateHierarchySharesForContacts(set<Id> contactIds){
    public static Map<Id,set<Id>> calculateHierarchySharesForContacts(set<Id> contactIds){
        System.debug('272: contactIds: ' + contactIds);
        //initialiseStaticMapsVariables();

        set<Id> ppDeleteList = new set<Id>();
        Map<Id,set<Id>> proposalTMContactsMap = new Map<Id,set<Id>>();
        Set<Id> projectProposalIds;

        for (Project_Team_Member__c ptm: [SELECT Id, I_RS_Project_Proposal__c
                                          FROM Project_Team_Member__c
                                          WHERE I_RS_Project_Team_Member__c in :contactIds
                                          AND I_RS_Team_Member_User__c != ''
                                          AND (I_RS_Active__c = True) AND (IsDeleted = False)]) {
                                              ppDeleteList.add(ptm.I_RS_Project_Proposal__c);
                                          }
            projectProposalIds = ppDeleteList;

        //now get contacts of every project proposals
        for (Project_Team_Member__c ptm: [SELECT Id, I_RS_Project_Proposal__c, I_RS_Project_Team_Member__c FROM Project_Team_Member__c WHERE I_RS_Project_Proposal__c in :projectProposalIds AND I_RS_Team_Member_User__c != ''  AND (I_RS_Active__c = True) AND (IsDeleted = False)]) {
            if(!proposalTMContactsMap.containsKey(ptm.I_RS_Project_Proposal__c)) {
                Set<Id> tempContactSet = new Set<Id>();
                tempContactSet.add(ptm.I_RS_Project_Team_Member__c);
                proposalTMContactsMap.put(ptm.I_RS_Project_Proposal__c,tempContactSet);
            }
            else{
                proposalTMContactsMap.get(ptm.I_RS_Project_Proposal__c).add(ptm.I_RS_Project_Team_Member__c);
            }
        }
        System.debug('proposalTMContactsMap 312: ' + proposalTMContactsMap);
        return proposalTMContactsMap;
        //System.enqueueJob(new HierarchySharesForContactsQueueable(proposalTMContactsMap, false, false, false));
    }

    public static void recalculateAllRelatedObjectHierarchyShares(set<Id> ppDelete, Map<Id, set<Id>> proposalHierarchyUsersMap){
        recalculateProjectProposalHierarchyShares(ppDelete, proposalHierarchyUsersMap);
        recalculateContractsHierarchyShares(ppDelete, proposalHierarchyUsersMap);
    }

    public static void recalculateProjectProposalHierarchyShares(set<Id> ppDelete, Map<Id, set<Id>> proposalHierarchyUsersMap){
        System.debug('ppDelete:' + ppDelete);
        System.debug('proposalHierarchyUsersMap:' + proposalHierarchyUsersMap);
        String rowCause = Schema.Project_Proposal__Share.rowCause.Project_Proposal_Hierarchy_User__c;
        List<Project_Proposal__Share> PPShareList;
        if (ppDelete != null) {
            PPShareList = [SELECT Id, ParentId, UserOrGroupId FROM Project_Proposal__Share WHERE (ParentId in :ppDelete) AND (RowCause = :rowCause) ];
        	System.debug('PPShareList:' + PPShareList);
            Database.DeleteResult[] deleRes = Database.delete(PPShareList, false);
            for (Database.DeleteResult dr: deleRes) {
            	System.debug('database.delete result 389: ' + dr);
            }
            System.debug('after share table delete 391: ' + [SELECT Id, ParentId, UserOrGroupId FROM Project_Proposal__Share WHERE (ParentId in :ppDelete) AND (RowCause = :rowCause) ]);
        }

        PPShareList = new List<Project_Proposal__Share>();
        Project_Proposal__Share PPShareRec;
        set<Id> hierarchyUsers;
        for (Id ProjPropId: proposalHierarchyUsersMap.keyset()) {
        	hierarchyUsers = proposalHierarchyUsersMap.get(ProjPropId);
        	System.debug('hierarchyUsers 396:' + hierarchyUsers);
            if (hierarchyUsers != null) {
                for (Id usr: hierarchyUsers) {
                    PPShareRec = new Project_Proposal__Share();
                    PPShareRec.ParentId = ProjPropId;
                    PPShareRec.UserOrGroupId = usr;
                    PPShareRec.RowCause = rowCause;
                    PPShareRec.AccessLevel = GlobalConstants.PROJECT_HIERARCHY_SHARING_PROJ_PROP_ACCESS;
                    PPShareList.add(PPShareRec);
                }
            }
        }

        Database.insert(PPShareList, false);
        System.debug('PPShareList:' + PPShareList);
    }

    public static void recalculateContractsHierarchyShares(set<Id> ppDelete, Map<Id, set<Id>> proposalHierarchyUsersMap){
        String rowCause = Schema.Contract__Share.rowCause.Project_Proposal_Hierarchy_User__c;
    	List<Contract__Share> crtShareList;

        set<Id> allPPIdList= new set<Id>();
        allPPIdList.addAll(ppDelete);
        allPPIdList.addAll(proposalHierarchyUsersMap.keySet());

        Map<Id, Contract__c> crtList = new Map<Id, Contract__c>([SELECT Id, I_RS_Project_Proposal__c  FROM Contract__c WHERE I_RS_Project_Proposal__c in :allPPIdList]);

        set<Id> crtDelete = new Set<Id>();
        for (Contract__c crt: crtList.Values()) {
            if (ppDelete.contains(crt.I_RS_Project_Proposal__c)) {
            	crtDelete.add(crt.Id);
            }
        }
        if (crtDelete.size() > 0) {
            crtShareList = [SELECT Id FROM Contract__Share WHERE (ParentId in :crtDelete) AND (RowCause = :rowCause) ];
            Database.delete(crtShareList, false);
        }

        set<Id> crtIds;
        Map<Id, set<Id>> projectproposalCRTMap = new  Map<Id, set<Id>>();
        for (Contract__c crt: crtList.values()){
            if (proposalHierarchyUsersMap.containsKey(crt.I_RS_Project_Proposal__c)) {
                crtIds = projectproposalCRTMap.get(crt.I_RS_Project_Proposal__c);
                if (crtIds == null) {
                    crtIds = new set<Id>();
                }
                crtIds.add(crt.Id);
                projectproposalCRTMap.put(crt.I_RS_Project_Proposal__c, crtIds);
            }
        }

        crtShareList = new List<Contract__Share>();
        Contract__Share crtShareRec;
        set<Id> hierarchyUsers;
        for (Id ProjPropId: proposalHierarchyUsersMap.keyset()) {
        	hierarchyUsers = proposalHierarchyUsersMap.get(ProjPropId);
            crtIds = projectproposalCRTMap.get(ProjPropId);
            if ((crtIds != null) && (hierarchyUsers != null)) {
                for(Id crtId: crtIds) {
                    for (Id usr: hierarchyUsers) {
                        crtShareRec = new Contract__Share();
                        crtShareRec.ParentId = crtId;
                        crtShareRec.UserOrGroupId = usr;
                        crtShareRec.RowCause = rowCause;
                        crtShareRec.AccessLevel = GlobalConstants.PROJECT_HIERARCHY_SHARING_CONTRACT_ACCESS;
                        crtShareList.add(crtShareRec);
                    }
                }
            }
        }
        System.debug('crtShareList: ' + crtShareList);
        Database.insert(crtShareList, false);
    }


    public static void handleContractRecordVisibility(Map<Id, Contract__c> oldCs, Map<Id, Contract__c> newCs){
        String rowCause = Schema.Contract__Share.rowCause.Project_Proposal_Hierarchy_User__c;
        Map<Id, set<Id>> ppCIdMap = new Map<Id, set<Id>>();

        List<Contract__share> cShares;
        set<Id> deleteCShareIds = new set<Id>();

        set<Id> cIds;
        for (Contract__c c: newCs.values()) {
            if (((oldCs != null) &&(c.I_RS_Project_Proposal__c != oldCs.get(c.Id).I_RS_Project_Proposal__c))) {
            	deleteCShareIds.add(c.Id);
            }
            if ((oldCs == null) ||(c.I_RS_Project_Proposal__c != oldCs.get(c.Id).I_RS_Project_Proposal__c)) {
                if (c.I_RS_Project_Proposal__c != null) {
                    if (!ppCIdMap.containsKey(c.I_RS_Project_Proposal__c)) {
                		ppCIdMap.put(c.I_RS_Project_Proposal__c, new set<Id>());
                    }
                    cIds = ppCIdMap.get(c.I_RS_Project_Proposal__c);
                    cIds.add(c.Id);
                }
            }
        }

        cShares = [SELECT Id FROM Contract__share WHERE (ParentId IN :deleteCShareIds) AND (RowCause = :rowCause)];
        Database.delete(cShares, false);

        cShares = new List<Contract__share>();
        List<Project_Proposal__share> ppShares = [SELECT ParentId, UserOrGroupId FROM Project_Proposal__share WHERE (ParentId IN :ppCIdMap.keySet()) AND (RowCause = :rowCause)];
        for (Project_Proposal__share pps: ppShares){
            cIds = ppCIdMap.get(pps.ParentId);
            for (Id cId: cIds) {
            	Contract__share cShareRec = new Contract__share();
                cShareRec.ParentId = cId;
                cShareRec.UserOrGroupId = pps.UserOrGroupId;
                cShareRec.RowCause = rowCause;
                cShareRec.AccessLevel = GlobalConstants.PROJECT_HIERARCHY_SHARING_CONTRACT_ACCESS;
                cShares.add(cShareRec);
            }
        }
        System.debug('cShares: ' + cShares);
        Database.insert(cShares, false);
    }

    public static Map<string, Map<Id, set<Id>>> recalculateGrantHierarchyshares(Map<Id, AccountContactRelation> oldACRs, Map<Id, AccountContactRelation> newACRs) {
        initialiseStaticMapsVariables();
         Map<string, Map<Id, set<Id>>> returnMap = new  Map<string, Map<Id, set<Id>>>();

    	set<Id> allContactIds = new set<Id>();
    	set<Id> deleteContactIds = new set<Id>();
    	set<Id> deleteUserIds = new set<Id>();
    	set<Id> grantContactIds = new set<Id>();
    	map<Id, Id> addUserContactMap = new map<Id, Id>();
    	map<Id, Id> addContactUserMap = new map<Id, Id>();

        set<Id> tempAccIds;
        if (newACRs == null) {
            for (AccountContactRelation acr: oldACRs.values()) {
                deleteContactIds.add(acr.ContactId);
			}
        } else if (oldACRs == null) {
            for (AccountContactRelation acr: newACRs.Values()) {
                if ((acr.I_RS_Grant_Project_Proposal_Access__c) && (acr.IsActive)){
                    grantContactIds.add(acr.ContactId);
                }
			}
        } else {
            for (AccountContactRelation acr: newACRs.values()) {
                system.debug('AccountContactRelation newACR: ' + acr);
                if (acr.AccountId != oldACRs.get(acr.Id).AccountId) {
                system.debug('AccountContactRelation AccountID oldACR: ' + oldACRs.get(acr.Id));
                	deleteContactIds.add(acr.ContactId);
                    if ((acr.I_RS_Grant_Project_Proposal_Access__c) &&(acr.IsActive)) {
                        grantContactIds.add(acr.ContactId);
                    }
                } else if ((acr.I_RS_Grant_Project_Proposal_Access__c != oldACRs.get(acr.Id).I_RS_Grant_Project_Proposal_Access__c) ||
                           (acr.IsActive != oldACRs.get(acr.Id).IsActive)) {
                	system.debug('AccountContactRelation Grant Access oldACR: ' + acr.ContactId+ ' : ' + acr.I_RS_Grant_Project_Proposal_Access__c);
                               if (acr.IsActive) {
                                    if (acr.I_RS_Grant_Project_Proposal_Access__c) {
                                        system.debug('AccountContactRelation Grant1 Access oldACR: ' + acr.ContactId);
                                        grantContactIds.add(acr.ContactId);
                                    }  else {
                                        system.debug('AccountContactRelation Grant3 delete Access oldACR: ' + acr.ContactId);
                                        deleteContactIds.add(acr.ContactId);
                                    }
                               }else {
                        deleteContactIds.add(acr.ContactId);
                }
                }

            }
        }

        System.debug('deleteContactIds 597: ' + deleteContactIds);
        for (User usr:[SELECT Id, ContactId FROM User WHERE IsActive = True AND IsPortalEnabled = True]) {
            if (deleteContactIds.contains(usr.ContactId)) {
                deleteUserIds.add(usr.Id);
            }
            addUserContactMap.put(usr.Id, usr.ContactId);
            addContactUserMap.put(usr.ContactId, usr.Id);
        }
        System.debug('deleteUserIds 603: ' + deleteUserIds);
        system.debug('addUserContactMap: ' +addUserContactMap);
        system.debug('addContactUserMap: ' +addContactUserMap);
        System.debug('latrobeOrgHierarchy.size(): ' + latrobeOrgHierarchy	.size());
        System.debug('latrobeOrgChildAccountMap.size(): ' + latrobeOrgChildAccountMap.size());
        System.debug('latrobeOrgChildAccountMap: ' + latrobeOrgChildAccountMap);

        Map<Id, set<Id>> AUMap = new Map<Id, set<Id>>();
        set<Id> userSet;
        set<Id> childAccIdSet;
        for (AccountContactRelation acr: [SELECT AccountId, ContactId FROM AccountContactRelation WHERE IsActive = True
            and ContactId IN :grantContactIds
            and Contact.I_RS_Related_User__c != null
            and Contact.I_RS_Related_User__r.IsActive = TRUE]) {
              Id userId = addContactUserMap.get(acr.ContactId);
              userSet = AUMap.get(acr.AccountId);
              if (userSet == null) {
                userset = new set<Id>();
              }
              userSet.add(userId);
              AUMap.put(acr.AccountId, userSet);
              System.debug('acr.AccountId: ' + acr.AccountId);
              System.debug('latrobeOrgChildAccountMap.get(acr.AccountId): ' + latrobeOrgChildAccountMap.get(acr.AccountId));
              childAccIdSet = latrobeOrgChildAccountMap.get(acr.AccountId);
                if (childAccIdSet != null) {
                  for (Id ca: childAccIdSet) {
                    userSet = AUMap.get(ca);
                    if (userSet == null) {
                      userset = new set<Id>();
                    }
                    userSet.add(userId);
                    AUMap.put(ca, userSet);
                  }
                }
        }

        set<Id> hUsers;
        Map<Id, set<Id>> userHierarchyUserMap = new Map<Id, set<Id>>();
        for (AccountContactRelation acr: [SELECT AccountID, ContactId FROM AccountContactRelation WHERE IsActive = True
            and AccountId IN :AUMap.keyset()
            and Contact.I_RS_Related_User__c != null
            and Contact.I_RS_Related_User__r.IsActive = TRUE]) {
            Id userId = addContactUserMap.get(acr.ContactId);
            if (userHierarchyUserMap.containsKey(userId)) {
              userSet = userHierarchyUserMap.get(userId);
            } else {
                userSet = null;
            }
            if (userSet == null) {
              userSet = new Set<Id>();
            }
            hUsers = AUMap.get(acr.accountId);
            if (hUsers != null) {
              userSet.addAll(hUsers);
            }
            userHierarchyUserMap.put(userId, userSet);
        }
        
        Map<Id, set<Id>> projectHierarchyMap = new Map<Id, set<Id>>();
        for (Project_Team_Member__c ptm: 
             [SELECT I_RS_Project_Proposal__c, I_RS_Team_Member_User__c FROM Project_Team_Member__c 
              WHERE (I_RS_Active__c = TRUE) AND (IsDeleted = False) AND (I_RS_Team_Member_User__c IN :userHierarchyUserMap.keySet()) ]) {
				hUsers = projectHierarchyMap.get(ptm.I_RS_Project_Proposal__c);   
                  if (hUsers == null) {
                      hUsers = new set<Id>();
                  }
                  hUsers.addAll(userHierarchyUserMap.get(ptm.I_RS_Team_Member_User__c));
                  projectHierarchyMap.put(ptm.I_RS_Project_Proposal__c, hUsers);
              }

        Map<Id, set<Id>> deleteUsersMap = new Map<Id, set<Id>>(); 
        deleteUsersMap.put(UserInfo.getUserId(), deleteUserIds);
        
        returnMap.put(SHARE_PROJECT_HIERARCHY_MAP, projectHierarchyMap);
        returnMap.put(DELETE_USER_ID_LIST, deleteUsersMap);
        return returnMap;

    }

    public static List<SObject> queueableCalculatePPShare(Map<Id, set<Id>> projectHierarchyMap){
        Id ctId;
        set<Id> hUserIds;
        String keyString;
        set<String> keySet = new set<String>();
        List<Project_Proposal__Share> ppShareList = new List<Project_Proposal__Share>();
        
        for (Id ppId: projectHierarchyMap.keySet()){
        	hUserIds = projectHierarchyMap.get(ppId); 
            for (Id uId: hUserIds) {
                keyString = ppId;
                keyString = keyString + uId;
                if (!keySet.contains(keystring)) {
                    Project_Proposal__Share newShare = new Project_Proposal__Share();
                    newShare.ParentId = ppId;
                    newShare.UserOrGroupId = uId;
                    newShare.RowCause = Schema.Project_Proposal__Share.rowCause.Project_Proposal_Hierarchy_User__c;
                    newShare.AccessLevel = GlobalConstants.PROJECT_HIERARCHY_SHARING_PROJ_PROP_ACCESS;
                    ppShareList.add(newShare);
                    keySet.add(keyString);
                }
            }
        }
        return ppShareList;
    }
    public static List<SObject> queueableCalculateCShare(Map<Id, set<Id>> projectHierarchyMap){
        Id cId;
        set<Id> hUserIds;
        String keyString;
        set<String> keySet = new set<String>();
        List<Contract__Share> cShareList = new List<Contract__Share>();

        for (Contract__c cRec: [SELECT Id, I_RS_Project_Proposal__c FROM Contract__c WHERE (I_RS_Project_Proposal__c IN :projectHierarchyMap.keySet())]) {
            cId =  cRec.Id;
            hUserIds = projectHierarchyMap.get(cRec.I_RS_Project_Proposal__c);
            if (hUserIds != null) {
                for (Id uId: hUserIds) {
                    keyString = cId;
                    keyString = keyString + uId;
                    if (!keySet.contains(keystring)) {
                        Contract__Share newShare = new Contract__Share();
                        newShare.ParentId = cId;
                        newShare.UserOrGroupId = uId;
                        newShare.RowCause = Schema.Project_Proposal__Share.rowCause.Project_Proposal_Hierarchy_User__c;
                        newShare.AccessLevel = GlobalConstants.PROJECT_HIERARCHY_SHARING_CONTRACT_ACCESS;
                        cShareList.add(newShare);
                        keySet.add(keyString);
                    }
                }
            }
        }
        return cShareList;
    }
    public static List<SObject> queueableCalculateCDelete(set<Id> deleteUserIds){
        List<SObject> cDeleteList = [SELECT ID FROM Contract__Share WHERE (UserOrGroupId IN :deleteUserIds) AND
                                   (RowCause = :Schema.Contract__Share.rowCause.Project_Proposal_Hierarchy_User__c)];
        System.debug('cDeleteList.size() : ' + cDeleteList.size());
        System.debug('cDeleteList : ' + cDeleteList);
        return cDeleteList;
    }

    public static List<SObject> queueableCalculatePPDelete(set<Id> deleteUserIds){
    	List<SObject> ppDeleteList = [SELECT ID FROM Project_Proposal__Share WHERE (UserOrGroupId IN :deleteUserIds) AND
                                   (RowCause = :Schema.Project_Proposal__Share.rowCause.Project_Proposal_Hierarchy_User__c)];
        System.debug('ppDeleteList.size() : ' + ppDeleteList.size());
        System.debug('ppDeleteList : ' + ppDeleteList);
        return ppDeleteList;
    }
}