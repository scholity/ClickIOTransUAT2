/**
 * Created by scholity on 12/10/19.
 */

public without sharing class PHSS_PublishCertificatesBatch implements Database.Batchable<sObject>, Database.Stateful {
    public Boolean exportAllCertificates = false;
    public DateTime RunTime = DateTime.Now();
    public String exportFileName = 'aws_cert_view_' + RunTime.format('yyyyMMddhhmmss') + '_1.csv';
    public Integer theSequenceNumber = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String csvHeader;
        //List<String> csvRowValues;
        //csvRowValues = new List<String>();

        csvHeader = 'offer_id|'
                +'reg_num|'
                +'first_nm|'
                +'mid_init|'
                +'last_nm|'
                +'email|'
                +'person_num|'
                +'person_typ|'
                +'instruct_flg|'
                +'org_id|'
                +'org_name|'
                +'course_id|'
                +'course_num|'
                +'course_nm|'
                +'course_ver|'
                +'valid_for|'
                +'is_component_flg|'
                +'Instructor_Name|'
                +'offering_stat|'
                +'delivery_typ|'
                +'status|'
                +'mastery_stat|'
                +'completion_dt|'
                +'facility_nm|'
                +'addr1|'
                +'addr2|'
                +'addr3|'
                +'city_nm|'
                +'state|'
                +'zip|'
                +'qr_code';

        DateTime lastRunDate = DateTime.Now();
        String incrementalExport = '';
        if (!exportAllCertificates) {
            // Get last run date/time from integration files object
            /*
            List<Integration_Files__c> integrationFiles = [Select Id, CreatedDate From Integration_Files__c Where File_Name__c Like 'aws_cert_view_%'
            Order By CreatedDate Desc Limit 1];
            if (integrationFiles.size() != null && integrationFiles.size() > 0) {
                lastRunDate = integrationFiles[0].CreatedDate;
                incrementalExport = 'And LastModifiedDate > :lastRunDate ';
            }
            */
            // DE9999 - Use export date as a filter rather than relying on date of last update in integration object
            incrementalExport = 'And Export_Date__c = null ';
        }
        System.debug('lastRunDate='+lastRunDate);
        System.debug('incrementalExport='+incrementalExport);
        System.debug('exportAllCertificates='+exportAllCertificates);

        // DE2591 - Apply list of accounts which are to be blocked from sending acquired certificates to AWS
        //List<PHSS_Custom_Settings__c> allSettings = PHSS_Custom_Settings__c.getAll().values();
        //List<String> blockedAccountList = new List<String>();
        //String blockedAccounts = '';
        //String blockedAccountFormattedList = '';

        // DE2591 - The following custom setting has been superseded by using a custom checkbox at the Account
        // level named Block Certificate Export to AWS
        /*
        if(!allSettings.isEmpty() && allSettings.get(0).AWS_Export_Accounts_Excluded__c != null
                && String.isNotBlank(allSettings.get(0).AWS_Export_Accounts_Excluded__c)) {
            System.debug('allSettings.get(0).AWS_Export_Accounts_Excluded__c'+allSettings.get(0).AWS_Export_Accounts_Excluded__c);
            blockedAccountList = allSettings.get(0).AWS_Export_Accounts_Excluded__c.split(',');
            for (String blockedAccount : blockedAccountList) {
                if (blockedAccountFormattedList.length() > 0) blockedAccountFormattedList += ',';
                blockedAccountFormattedList += '\''+blockedAccount+'\'';
            }
            blockedAccounts = 'AND Account__c NOT IN ('+blockedAccountFormattedList+')';
        }
        System.debug('blockedAccounts'+blockedAccounts);
        */

        String theAssignmentQuery = 'SELECT Id, Name, Firstname__c, Lastname__c, Email__c, Account__c, Online_Class__c, ';
        theAssignmentQuery += 'ILT_Class__c, Evaluation_Result__c,redwing__Acquisition_Date__c,redwing__status__c, redwing__Achievement__c, QR_Code_Identifier__c ';
        theAssignmentQuery += 'FROM redwing__Achievement_Assignment__c WHERE Achievement_Type__c = \'Certifications\' AND redwing__status__c = \'Acquired\' ';
        theAssignmentQuery += 'AND Firstname__c != null AND Lastname__c != null ';
        theAssignmentQuery += 'AND Account__r.Block_Certificate_Export_To_AWS__c = False ';
        theAssignmentQuery += incrementalExport;
        theAssignmentQuery += 'ORDER BY Name ';
		System.debug('theAssignmentQuery='+theAssignmentQuery);
        
        // Write export record header to Integration Files object

        try {
            Integration_Files__c integrationFileHeader = new Integration_Files__c();
            integrationFileHeader.Record_Data__c = csvHeader;
            integrationFileHeader.File_Name__c = exportFileName;
            integrationFileHeader.Sequence_Number__c = ++theSequenceNumber;
            integrationFileHeader.Target_System__c = 'AWS';
            insert(integrationFileHeader);

        } catch (exception e) {

        }

        return Database.getQueryLocator(theAssignmentQuery);
    }

    public void execute(Database.BatchableContext bc, List<redwing__Achievement_Assignment__c> assignmentList) {
        System.debug('# assignmentList='+assignmentList.size());

        Map<Id, Id> accountIdMap = new Map<Id, Id>();
        Map<Id, Id> classIdMap = new Map<Id, Id>();
        Map<Id, Id> achievementIdMap = new Map<Id, Id>();
        Map<Id, Id> learningIdMap = new Map<Id, Id>();
        Map<Id, String> onlineProductMap = new Map<Id, String>();
        Set<Id> onlineLearningPlanIds = new Set<Id>();

        for (redwing__Achievement_Assignment__c theAssignment : assignmentList) {
            if (theAssignment.Account__c != null) accountIdMap.put(theAssignment.Id, theAssignment.Account__c);
            if (theAssignment.ILT_Class__c != null) classIdMap.put(theAssignment.Id, theAssignment.ILT_Class__c);
            if (theAssignment.redwing__Achievement__c != null) achievementIdMap.put(theAssignment.Id, theAssignment.redwing__Achievement__c);
            if (theAssignment.Online_Class__c != null) learningIdMap.put(theAssignment.Id, theAssignment.Online_Class__c);
        }

        Map<Id, Account> accountMap = new Map<Id, Account>();
        Map<Id, redwing__ILT_Class__c> classMap = new Map<Id, redwing__ILT_Class__c>();
        Map<Id, redwing__Achievement__c> achievementMap = new Map<Id, redwing__Achievement__c>();
        Map<Id, redwing__ILT_Instructor__c> instructorMap = new Map<Id, redwing__ILT_Instructor__c>();
        Map<Id, redwing__Training_Plan_Section_Item__c> tpsiMap = new Map<Id, redwing__Training_Plan_Section_Item__c>();

        List<Account> accountList = [SELECT Id, Name from Account Where Id IN :accountIdMap.values()];
        List<redwing__ILT_Class__c> classList = [SELECT Id, Cloud_Craze_Product__c, Cloud_Craze_Product__r.ccrz__SKU__c, Cloud_Craze_Product__r.Name,
                Classroom_Setting__c, Site_Name__c, Site_Address_1__c, Site_Address_2__c, Site_City__c, State__c, Site_Postal_Code__c,
                Learning_Plan__r.Name, redwing__Location__c
                FROM redwing__ILT_Class__c Where Id IN :classIdMap.values()];
        List<redwing__Achievement__c> achievementList = [SELECT Id, Name, redwing__Expiration_Date__c, Description__c,
                redwing__Expiration_Term__c, redwing__Expiration_Term_Basis__c FROM redwing__Achievement__c WHERE Id IN :achievementIdMap.values()];
        List <redwing__ILT_Instructor__c> instructorList = [Select Id, Name, redwing__ILT_Class__c, redwing__Instructor__r.Name
                From redwing__ILT_Instructor__c Where redwing__ILT_Class__c IN :classIdMap.values() /*And redwing__Primary__c = True*/ ];
        List <redwing__Training_Plan_Section_Item__c> tpsiList = [Select Id, redwing__Learning__c, redwing__Training_Plan_Section__r.redwing__Training_Plan__r.Id
                From redwing__Training_Plan_Section_Item__c Where redwing__Learning__c IN :learningIdMap.values()];
        for (redwing__Training_Plan_Section_Item__c theTPSI : tpsiList) {
            onlineLearningPlanIds.add(theTPSI.redwing__Training_Plan_Section__r.redwing__Training_Plan__r.Id);
        }
        List <ccrz__E_Product__c> productList = [Select Id, ccrz__SKU__c, LMS_Learning_Plan__c From ccrz__E_Product__c Where LMS_Learning_Plan__c IN :onlineLearningPlanIds];
        for (ccrz__E_Product__c theProduct : productList) {
            onlineProductMap.put(theProduct.LMS_Learning_Plan__c, theProduct.ccrz__SKU__c);
        }

        for (Account theAccount : accountList){
            accountMap.put(theAccount.Id, theAccount);
        }
        for (redwing__ILT_Class__c theClass : classList) {
            classMap.put(theClass.Id, theClass);
        }
        for (redwing__Achievement__c theAchievement : achievementList) {
            achievementMap.put(theAchievement.Id, theAchievement);
        }
        for (redwing__ILT_Instructor__c theInstructor : instructorList) {
            instructorMap.put(theInstructor.redwing__ILT_Class__c, theInstructor);
        }
        for (redwing__Training_Plan_Section_Item__c theTPSI : tpsiList) {
            tpsiMap.put(theTPSI.redwing__Learning__c, theTPSI);
        }

        List<Integration_Files__c> integFiles = new List<Integration_Files__c>();
        List<redwing__Achievement_Assignment__c> exportedAchievementAssignments = new List<redwing__Achievement_Assignment__c>();


        for(redwing__Achievement_Assignment__c a : assignmentList)
        {
            //System.debug('Next assignment record='+a);

            List<String> dataList = new List<String>();

            // offer_id
            /*
            if(a.ILT_Class__c != null) {
                if(classMap.get(a.ILT_Class__c).Classroom_Setting__c == 'Online') {
                    dataList.add('');
                    // This is *WRONG* - not this leaning object!!  dataList.add('\"'+ a.ILT_Class__r.redwing__Learning__c +'\"');
                }
                else {
                    String productId = a.ILT_Class__c;
                    if (productId.length()>15) productId = productId.substring(0,15);
                    dataList.add('\"'+ productId +'\"');
                }
            }
            else {
                dataList.add('');
            }*/
            if(a.Name != null && a.Name.length()>4) {
                dataList.add('\"'+ a.Name.substring(4) +'\"');
            } else dataList.add('');

            // reg_num
            dataList.add('');

            // first_nm
            if(a.Firstname__c != null) {
                String firstName = a.Firstname__c;
                if(firstName.length()<2) {
                    firstName = 'XX';
                }
                dataList.add('\"'+ firstName +'\"');
            }
            else {
                dataList.add('');
            }

            // mid_init
            dataList.add('');

            // last_nm
            if(a.Lastname__c != null) {
                String lastName = a.Lastname__c;
                if(lastName.length()<2) {
                    lastName = 'XX';
                }
                dataList.add('\"'+ lastName +'\"');
            }
            else {
                dataList.add('');
            }

            // email
            if(a.Email__c != null) {
                dataList.add('\"'+ a.Email__c + '\"');
            }
            else {
                dataList.add('');
            }

            // person_num
            dataList.add('');

            // person_typ
            dataList.add('');

            // instruct_flg
            if(a.redwing__Achievement__c != null && achievementMap.get(a.redwing__Achievement__c).Name.containsIgnoreCase('instructor')) {
                dataList.add('\"Y\"');
            } else dataList.add('\"N\"');

            // org_id
            /*if(a.Account__c != null && accountMap.get(a.Account__c).Id != null) {
                dataList.add('\"'+ accountMap.get(a.Account__c).Id +'\"');
            }
            else {
                dataList.add('');
            }
            */
            dataList.add('');

            // org_name
            /*if(a.Account__c != null && accountMap.get(a.Account__c).Name != null) {
                dataList.add('\"'+ accountMap.get(a.Account__c).Name +'\"');
            }
            else {
                dataList.add('');
            }
            */
            dataList.add('');

            // course_id
            if(a.ILT_Class__c != null || a.Online_Class__c != null) {
                if(a.Online_Class__c != null) {
                    if(tpsiMap.get(a.Online_Class__c) != null) {
                        String courseId = tpsiMap.get(a.Online_Class__c).redwing__Training_Plan_Section__r.redwing__Training_Plan__r.Id;
                        if (courseId.length()>15) courseId = courseId.substring(0,15);
                        dataList.add('\"'+ courseId +'\"');
                    } else dataList.add('');
                }
                else {
                    if(classMap.get(a.ILT_Class__c).Learning_Plan__c != null) {
                        String courseId = classMap.get(a.ILT_Class__c).Learning_Plan__c;
                        if (courseId.length()>15) courseId = courseId.substring(0,15);
                        dataList.add('\"'+ courseId +'\"');
                    } else dataList.add('');
                }
            }
            else {
                dataList.add('');
            }

            // course_num
            if(a.ILT_Class__c != null || a.Online_Class__c != null) {
                if (a.Online_Class__c != null) {
                    if (tpsiMap.get(a.Online_Class__c) != null) {
                        String courseId = tpsiMap.get(a.Online_Class__c).redwing__Training_Plan_Section__r.redwing__Training_Plan__r.Id;
                        if (onlineProductMap.get(courseId) != null) {
                            dataList.add('\"' + onlineProductMap.get(courseId) + '\"');
                        } else dataList.add('');
                    } else dataList.add('');
                } else {
                    if (classMap.get(a.ILT_Class__c).Cloud_Craze_Product__r.ccrz__SKU__c != null) {
                        dataList.add('\"' + classmap.get(a.ILT_Class__c).Cloud_Craze_Product__r.ccrz__SKU__c + '\"');
                    } else dataList.add('');
                }
            } else {
                dataList.add('');
            }

            // course_nm (learning plan name)
            // US1499 - change to Achievement Assignment description field (or name if blank)
            /*
            if(a.ILT_Class__c != null && classMap.get(a.ILT_Class__c).Learning_Plan__r.Name != null) {
                dataList.add('\"'+ classMap.get(a.ILT_Class__c).Learning_Plan__r.Name +'\"');
            }
            */
            if (a.redwing__Achievement__c != null) {
                if (achievementMap.get(a.redwing__Achievement__c).Description__c != null) {
                    dataList.add('\"'+achievementMap.get(a.redwing__Achievement__c).Description__c+'\"');
                } else dataList.add('\"'+achievementMap.get(a.redwing__Achievement__c).Name+'\"');
            }
            else dataList.add('');

            // course_ver
            if (a.redwing__Achievement__c != null && achievementMap.get(a.redwing__Achievement__c).redwing__Expiration_Date__c != null) {
                Integer theYear = achievementMap.get(a.redwing__Achievement__c).redwing__Expiration_Date__c.year();
                dataList.add('\"'+'r.'+String.valueOf(theYear)+'\"');
            } else dataList.add('');

            // valid_for
            if (a.redwing__Achievement__c != null && achievementMap.get(a.redwing__Achievement__c).redwing__Expiration_Term__c != null) {
                if (achievementMap.get(a.redwing__Achievement__c).redwing__Expiration_Term_Basis__c != null) {
                    Integer theTerm = Integer.valueOf(achievementMap.get(a.redwing__Achievement__c).redwing__Expiration_Term__c);
                    String theBasis = achievementMap.get(a.redwing__Achievement__c).redwing__Expiration_Term_Basis__c;
                    if (theBasis.trim().equals('Years')) {
                        if (theTerm == 1) theBasis = 'Year';
                        dataList.add('\"'+String.valueOf(theTerm)+' '+theBasis+'\"');
                    }
                    else dataList.add('');
                }
                else dataList.add('');
            } else {
                dataList.add('');
            }

            // is_component_flg
            // Force to a Y value to insure validation period displays on a certificate generated in RCO via AWS
            /*
            if(a.ILT_Class__c != null && classMap.get(a.ILT_Class__c).Learning_Plan__r.Name != null) {
                if(classMap.get(a.ILT_Class__c).Learning_Plan__r.Name == 'Lifeguarding') {
                    dataList.add('\"N\"');
                } else dataList.add('\"Y\"');
            }
            else {
                dataList.add('\"Y\"');
            }
            */
            dataList.add('\"Y\"');

            // Instructor_Name
            if(a.ILT_Class__c != null && instructorMap.get(a.ILT_Class__c) != null &&  instructorMap.get(a.ILT_Class__c).redwing__Instructor__r.Name != null) {
                dataList.add('\"'+ instructorMap.get(a.ILT_Class__c).redwing__Instructor__r.Name +'\"');
            } else dataList.add('');

            // offering_stat
            dataList.add('\"Delivered - Normal\"');

            // delivery_typ
            if(a.ILT_Class__c != null || a.Online_Class__c != null) {
                if(a.Online_Class__c != null) {
                    dataList.add('\"Web Based\"');
                } else {
                    if (classMap.get(a.ILT_Class__c).Classroom_Setting__c != null) {
                        if (classMap.get(a.ILT_Class__c).Classroom_Setting__c == 'Online') {
                            dataList.add('\"Web Based\"');
                        } else if (classMap.get(a.ILT_Class__c).Classroom_Setting__c == 'Online + Classroom') {
                            dataList.add('\"Web Based / Classroom\"');
                        } else {
                            dataList.add('\"' + classMap.get(a.ILT_Class__c).Classroom_Setting__c + '\"');
                        }
                    } else dataList.add('');
                }
            } else {
                dataList.add('');
            }

            // status
            if(a.redwing__Status__c != null) {
                if(a.redwing__Status__c == 'Acquired') {
                    dataList.add('\"Completed\"');
                }
                else continue;
            }
            else {
                dataList.add('');
            }

            // mastery_stat
            if(a.redwing__Status__c != null) {
                if (a.redwing__Status__c == 'Acquired') {
                    dataList.add('\"Successful\"');
                }
                else continue;
            }
            else {
                dataList.add('');
            }

            // completion_dt (format MM/DD/YYYY 00:00:00)
            if(a.redwing__Acquisition_Date__c != null) {
                String dtMonth = String.valueOf(a.redwing__Acquisition_Date__c.month());
                String dtDay = String.valueOf(a.redwing__Acquisition_Date__c.day());
                String dtYear = String.valueOf(a.redwing__Acquisition_Date__c.year());
                if (dtMonth.length()<2) dtMonth = '0'+dtMonth;
                if (dtDay.length()<2) dtDay = '0'+dtDay;
                String formattedAcqDate = dtMonth+'/'+dtDay+'/'+dtYear+' 00:00:00';
                //DateTime dtAcqDate = a.redwing__Acquisition_Date__c;
                //String formattedAcqDate = dtAcqDate.format('MM/dd/yyyy')+' 00:00:00';

                dataList.add('\"'+ formattedAcqDate +'\"');
            }
            else {
                dataList.add('');
            }

            // facility_nm (and all related facility address fields) - Removed per John Cordero
            /*
            if(a.ILT_Class__c != null) {
                if(classMap.get(a.ILT_Class__c).redwing__Location__c != null) {
                    dataList.add('\"'+classmap.get(a.ILT_Class__c).redwing__Location__r.Name+'\"');
                } else if (classMap.get(a.ILT_Class__c).Site_Name__c != null) {
                    dataList.add('\"'+classMap.get(a.ILT_Class__c).Site_Name__c+'\"');
                } else dataList.add('');
            } else dataList.add('');
            */
            dataList.add('');

            // addr1 Site_Address_1__c
            /*
            if(a.ILT_Class__c != null) {
                if(classMap.get(a.ILT_Class__c).redwing__Location__c != null) {
                    dataList.add('\"'+classMap.get(a.ILT_Class__c).redwing__Location__r.redwing__Address_1__c+'\"');
                } else if (classMap.get(a.ILT_Class__c).Site_Address_1__c != null) dataList.add('\"'+classMap.get(a.ILT_Class__c).Site_Address_1__c+'\"');
                    else dataList.add('');
            } else dataList.add('');
            */
            dataList.add('');

            // addr2
            /*
            if(a.ILT_Class__c != null) {
                if(classMap.get(a.ILT_Class__c).redwing__Location__c != null) {
                    dataList.add('\"'+classMap.get(a.ILT_Class__c).redwing__Location__r.redwing__Address_2__c+'\"');
                } else if (classMap.get(a.ILT_Class__c).Site_Address_2__c != null) dataList.add('\"'+classMap.get(a.ILT_Class__c).Site_Address_2__c+'\"');
                    else dataList.add('');
            } else dataList.add('');
            */
            dataList.add('');

            // addr3
            dataList.add('');

            // city_nm
            /*
            if(a.ILT_Class__c != null) {
                if(classMap.get(a.ILT_Class__c).redwing__Location__c != null) {
                    dataList.add('\"'+classMap.get(a.ILT_Class__c).redwing__Location__r.redwing__City__c+'\"');
                } else if (classMap.get(a.ILT_Class__c).Site_City__c != null) dataList.add('\"'+classMap.get(a.ILT_Class__c).Site_City__c+'\"');
                    else dataList.add('');
            } else dataList.add('');  */
            dataList.add('');


            // state
            /*
            if(a.ILT_Class__c != null) {
                if(classMap.get(a.ILT_Class__c).redwing__Location__c != null) {
                    dataList.add('\"'+classMap.get(a.ILT_Class__c).redwing__Location__r.redwing__State__c+'\"');
                } else if (classMap.get(a.ILT_Class__c).State__c != null) dataList.add('\"'+classMap.get(a.ILT_Class__c).State__c+'\"');
                    else dataList.add('');
            } else dataList.add('');
            */
            dataList.add('');

            // zip
            /*
            if(a.ILT_Class__c != null) {
                if(classMap.get(a.ILT_Class__c).redwing__Location__c != null) {
                    dataList.add('\"'+classMap.get(a.ILT_Class__c).redwing__Location__r.redwing__Postal_Code__c+'\"');
                } else if (classMap.get(a.ILT_Class__c).Site_Postal_Code__c != null) dataList.add('\"'+classMap.get(a.ILT_Class__c).Site_Postal_Code__c+'\"');
                    else dataList.add('');
            } else dataList.add('');
            */
            dataList.add('');

            // qr_code
            if(a.QR_Code_Identifier__c != null) {
                dataList.add('\"'+a.QR_Code_Identifier__c+'\"');
            } else dataList.add('');

            /* This is now calculated in after insert / before update trigger for AchievementAssignment
            String QRCodeBase32 = base10To32(Decimal.valueOf(a.Name.substring(4)));
            dataList.add(QRCodeBase32);
            */

            Integration_Files__c integrationFileRecord = new Integration_Files__c();
            integrationFileRecord.Record_Data__c = String.join(dataList,'|');
            integrationFileRecord.File_Name__c = exportFileName;
            integrationFileRecord.Sequence_Number__c = ++theSequenceNumber;
            integrationFileRecord.Target_System__c = 'AWS';
            integFiles.add(integrationFileRecord);

            // DE2051 - Update Export Date field in Achievement Assignment record for all records written
            // to Integration Files object
            redwing__Achievement_Assignment__c exportedAssignment = new redwing__Achievement_Assignment__c();
            exportedAssignment.Id = a.Id;
            exportedAssignment.Export_Date__c = RunTime;
            exportedAchievementAssignments.add(exportedAssignment);

            // DE2051 - Disable the creation of a local copy of integration file (primarily used for testing)
            //String concatenatedValues = String.join(dataList,'|');
            //if (concatenatedValues != null) csvRowValues.add(concatenatedValues);
        }

        // Write export records to Integration Files object
        // DE2051 - Upodate achievement assignment records with date exported to integration files object

        try {
            Database.insert(integFiles);
            Database.update(exportedAchievementAssignments);

        } catch (exception e) {

        }

        return;
    }

    public void finish(Database.BatchableContext bc){
        // No end of job processing required - no trailer record(s) required in integration file
    }
}