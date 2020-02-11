/*************************************************************************************

Class      :  AccountContactRelationTriggerHandler.cls
Developer  :  cvaughan@salesforce.com
Created    :  02/01/2020
Objective  :  Trigger handler class for the AccountContactRelation object
Test Class :  AccountContactRelationTriggerHandlerTest.cls
Notes      :  Instantiated from AccountContactRelationTrigger.trigger

*************************************************************************************/

public without sharing class AccountContactRelationTriggerHandler {

    @testVisible
    private static final String ACR_ROLE_INSTRUCTOR = 'Instructor';

    @testVisible
    private static final String ACR_ROLE_ADMINISTRATOR = 'Administrator';

    @testVisible
    private static Profile instructorProfile{
        get{
            if(instructorProfile == null){
                instructorProfile = [SELECT Id, UserLicenseId, UserType FROM Profile WHERE Name = 'SB PHSS-IC-Community Plus Login' LIMIT 1];
            }
            return instructorProfile;
        }
        private set;
    }

    @testVisible
    private static Profile adminProfile{
        get{
            if(adminProfile == null){
                adminProfile = [SELECT Id, UserLicenseId, UserType FROM Profile WHERE Name = 'SB PHSS-Partner-Community Plus Login' LIMIT 1];
            }
            return adminProfile;
        }
        private set;
    }

    /**
    * Method Name: onAfterInsert
    * Method Description: handle all After Insert tigger operations
    */ 
    public void onAfterInsert(List<AccountContactRelation> newAccountContactRelations){
        updateInstructorAndAdminProfiles(newAccountContactRelations, null);
    }

    /**
    * Method Name: onAfterUpdate
    * Method Description: handle all After Update tigger operations
    */ 
    public void onAfterUpdate(List<AccountContactRelation> newAccountContactRelations, List<AccountContactRelation> oldAccountContactRelations, Map<ID, AccountContactRelation> newAccountContactRelationMap , Map<ID, AccountContactRelation> oldAccountContactRelationMap){
        updateInstructorAndAdminProfiles(newAccountContactRelations, oldAccountContactRelations);
    }

    /**
    * Method Name: updateInstructorAndAdminProfiles
    * Method Description: update the User profile related to the Contact when a AccountContactRelation record is created with a role of 'Instructor' or 'Administrator'
    * @param newAccountContactRelations: List of inserted or updated AccountContactRelation records
    * @param oldAccountContactRelations: List of AccountContactRelation records in state prior to update 
    */ 
    private void updateInstructorAndAdminProfiles(List<AccountContactRelation> newAccountContactRelations, List<AccountContactRelation> oldAccountContactRelations){

        Map<Id, AccountContactRelation> newAccountContactRelationMap = new Map<Id, AccountContactRelation>(newAccountContactRelations);

        Map<Id, AccountContactRelation> oldAccountContactRelationMap = ( oldAccountContactRelations == null ? null : new Map<Id, AccountContactRelation>(oldAccountContactRelations) );

        List<AccountContactRelation> accountContactRelationsToProcess = new List<AccountContactRelation>();

        for(Id acrId : newAccountContactRelationMap.keySet()){  
            AccountContactRelation newACR = newAccountContactRelationMap.get(acrId);
            if(String.isNotBlank(newACR.Roles)
                && (newACR.Roles.contains(ACR_ROLE_INSTRUCTOR) 
                    || newACR.Roles.contains(ACR_ROLE_ADMINISTRATOR)) ){

                AccountContactRelation oldACR = ( oldAccountContactRelationMap != null ? oldAccountContactRelationMap.get(acrId) : null );
                if(oldACR == null){ 
                    accountContactRelationsToProcess.add(newACR);
                }
                else if(newACR.Roles.contains(ACR_ROLE_ADMINISTRATOR) 
                    && (String.isBlank(oldACR.Roles) 
                        || !oldACR.Roles.contains(ACR_ROLE_ADMINISTRATOR))){

                    accountContactRelationsToProcess.add(newACR);
                }
                else if(newACR.Roles.contains(ACR_ROLE_INSTRUCTOR) 
                    && !newACR.Roles.contains(ACR_ROLE_ADMINISTRATOR) 
                    && (String.isBlank(oldACR.Roles) 
                        || !oldACR.Roles.contains(ACR_ROLE_INSTRUCTOR))){

                    accountContactRelationsToProcess.add(newACR);
                }
            }
        }

        if(!accountContactRelationsToProcess.isEmpty()){

            List<Id> contactIds = new List<Id>();

            for(AccountContactRelation acr : accountContactRelationsToProcess){
                contactIds.add(acr.ContactId);
            }

            List<User> usersToUpdate = new List<User>([
                SELECT Id, UserRoleId, ContactId, Contact.AccountId, Contact.Account.Id, Contact.Account.Owner.Alias
                FROM User
                WHERE ContactId IN :contactIds
            ]);

            Map<Id, User> contactToUserMap = new Map<Id, User>();

            List<String> userRolesNames = new List<String>();

            for(User u : usersToUpdate){
                contactToUserMap.put(u.ContactId, u);
                // attempting to match a user to the system-created UserRole record generated as part of "Account role optimization" settings. These roles follow
                // a similar naming convention of User.Alias+"  Customer Person Account" (e.g. tuser Customer Person Account)
                userRolesNames.add(u.Contact.Account.Owner.Alias+' Customer Person Account');
            }
            
            Map<String, Id> userRoleNameMap = new Map<String, Id>();

            for(UserRole ur : [SELECT Id, Name FROM UserRole WHERE Name IN :userRolesNames]){
                userRoleNameMap.put(ur.Name, ur.Id);
            }

            Map<Id, Id> userToProfileMap = new Map<Id, Id>();

            Map<Id, Id> userToRoleMap = new Map<Id, Id>();

            for(AccountContactRelation acr : accountContactRelationsToProcess){
                User thisUser = contactToUserMap.get(acr.ContactId);
                Id newProfileId;
                if(thisUser.UserRoleId == null){
                    String newRoleName = thisUser.Contact.Account.Owner.Alias+' Customer Person Account';
                    Id newUserRoleId = userRoleNameMap.get(newRoleName);
                    userToRoleMap.put(thisUser.Id, newUserRoleId);
                }
                if(acr.Roles.contains(ACR_ROLE_ADMINISTRATOR)){
                    newProfileId = adminProfile.Id;
                }
                else if(acr.Roles.contains(ACR_ROLE_INSTRUCTOR)){
                    newProfileId = instructorProfile.Id;
                }
                userToProfileMap.put(thisUser.Id, newProfileId);
            }

            updateUserRecordsAsync(userToProfileMap, userToRoleMap);
        }
    }

    /**
    * Method Name: updateUserRecordsAsync
    * Method Description: perform DML operation on user records async to avoid MIXED_DML error
    * @param userToProfileMap: Map of User.Id to the new ProfileId
    * @param userToRoleMap: Map of User.Id to the new UserRoleId
    */ 
    @future
    private static void updateUserRecordsAsync(Map<Id, Id> userToProfileMap, Map<Id, Id> userToRoleMap){
        List<User> usersToUpdate = new List<User>();
        for(Id userId : userToProfileMap.keySet()){
            User newUser = new User(
                Id = userId,
                ProfileId = userToProfileMap.get(userId)
            );
            if(userToRoleMap.containsKey(userId)){
                newUser.UserRoleId = userToRoleMap.get(userId);
            }
            usersToUpdate.add(newUser);
        }
        update usersToUpdate;
    }

}