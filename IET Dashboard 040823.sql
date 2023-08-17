-----------------
--For clinical time for just IET
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_TypeAndDuration]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_TypeAndDuration]
SELECT  
    i.PathwayID
    ,i.IntEnabledTherProg
	,i.IntegratedSoftwareInd
    ,SUM(DurationIntEnabledTher) AS DurationIntEnabledTher
INTO [MHDInternal].[TEMP_TTAD_IET_TypeAndDuration]
FROM [mesh_IAPT].[IDS205internettherlog] i
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON i.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND i.[AuditId] = l.[AuditId]
WHERE l.IsLatest = 1 
GROUP BY i.PathwayID, i.IntEnabledTherProg, i.IntegratedSoftwareInd


--For clinical time including IET
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_NoIETDuration]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_NoIETDuration]
SELECT  
    ca.PathwayID
    ,SUM(ca.ClinContactDurOfCareAct) AS ClinContactDurOfCareAct
INTO [MHDInternal].[TEMP_TTAD_IET_NoIETDuration]
FROM [mesh_IAPT].[IDS202careactivity] ca
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON ca.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND ca.[AuditId] = l.[AuditId]
WHERE l.IsLatest = 1 
GROUP BY ca.PathwayID


-- IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_ConsMed]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_ConsMed]

-- SELECT
-- 	PathwayID
-- 	,SUM([Face to face communication]) AS [Face to face communication]
-- 	-- ,SUM([Other]) AS [Other]
-- INTO [MHDInternal].[TEMP_TTAD_IET_ConsMed]
-- FROM(
-- 	SELECT DISTINCT 
-- 			c.[PathwayID]
-- 			,c.Unique_CareContactID
-- 			,CASE WHEN (c.ConsMechanism IN ('01', '1', '1 ', ' 1') OR c.ConsMediumUsed IN ('01', '1', '1 ', ' 1'))
-- 					AND c.Unique_CareContactID IS NOT NULL
-- 				THEN 1 
-- 				END AS 'Face to face communication'
-- 			-- ,CASE WHEN c.ConsMechanism IN ('02', '2', '2 ', ' 2','03', '3', '3 ', ' 3','04', '4', '4 '
-- 			-- 		, ' 4','05', '5', '5 ', ' 5','06', '6', '6 ', ' 6','98', '98 ', ' 98','08', '8', '8 '
-- 			-- 		, ' 8','09', '9', '9 ', ' 9','10', '10', '10 ', ' 10','11', '11', '11 ', ' 11','12'
-- 			-- 		, '12', '12 ', ' 12','13', '13', '13 ', ' 13') 
-- 			-- 		OR c.ConsMediumUsed IN ('02', '2', '2 ', ' 2','03', '3', '3 ', ' 3','04', '4', '4 ', ' 4'
-- 			-- 		,'05', '5', '5 ', ' 5','06', '6', '6 ', ' 6','98', '98 ', ' 98','08', '8', '8 ', ' 8','09'
-- 			-- 		, '9', '9 ', ' 9','10', '10', '10 ', ' 10','11', '11', '11 ', ' 11','12', '12', '12 '
-- 			-- 		, ' 12','13', '13', '13 ', ' 13') 
-- 			-- 		AND c.Unique_CareContactID IS NOT NULL
-- 			-- 	THEN 1 
-- 			-- END AS 'Other'
	
-- 	FROM [mesh_IAPT].[IDS201carecontact] c
-- 	INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON c.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND c.AuditId = l.AuditId
-- 	WHERE (c.[AttendOrDNACode] in ('5','6') or c.PlannedCareContIndicator = 'N') AND c.AppType IN ('01','02','03','05') and IsLatest = 1
-- )_
-- GROUP BY PathwayID

------------------------------------------------------------------------------------------------------------------
------------------------------------------Base table 
--This creates a base table with one record per row which is then aggregated to produce [MHDInternal].[DASHBOARD_TTAD_IET_Main]
DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset for getting the period start and end should be -1 to get the latest refreshed month
SET @PeriodStart = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT EOMONTH(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

--The offset needs to be set for September 2020 (e.g. @PeriodStart -30 = -31 which is the offset of September 2020)
DECLARE @Offset int
SET @Offset=-32

SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_Base]
SELECT DISTINCT
	CAST(DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR) AS DATE) AS Month
    ,CASE WHEN DATENAME(q, l.ReportingPeriodStartDate)=1 THEN 'Q4' + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR)
    WHEN DATENAME(q, l.ReportingPeriodStartDate)=2 THEN 'Q1' + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR)
    WHEN DATENAME(q, l.ReportingPeriodStartDate)=3 THEN 'Q2' + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR)
    WHEN DATENAME(q, l.ReportingPeriodStartDate)=4 THEN 'Q3' + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR)
	END AS Quarter	
	,l.ReportingPeriodStartDate
	,l.ReportingPeriodEndDate
	,r.PathwayID
	,r.Unique_MonthID

	,r.ReferralRequestReceivedDate
	,r.Assessment_FirstDate
	,r.TherapySession_FirstDate
	,r.TherapySession_SecondDate
	,r.ServDischDate

	--Wait Times
	,DATEDIFF(DD,r.ReferralRequestReceivedDate,r.Assessment_FirstDate) AS WaitRefToFirstAssess
	,DATEDIFF(DD,r.ReferralRequestReceivedDate,r.TherapySession_FirstDate) AS WaitRefToFirstTherapy
	,DATEDIFF(DD,r.TherapySession_FirstDate,r.TherapySession_SecondDate) AS WaitFirstTherapyToSecondTherapy
		
	--Number of Appointments
    ,r.InternetEnabledTherapy_Count

    --Type of IET
	--,i.IntEnabledTherProg
	,CASE WHEN (i.IntEnabledTherProg LIKE 'SilverCloud%' OR i.IntEnabledTherProg LIKE  'Slvrcld%' ) THEN 'SilverCloud'
		WHEN (i.IntEnabledTherProg LIKE 'Mnddstrct%' OR i.IntEnabledTherProg LIKE 'Minddistrict%') THEN 'Minddistrict'
		WHEN i.IntEnabledTherProg LIKE 'iCT%' THEN 'iCT'
		WHEN i.IntEnabledTherProg LIKE 'OCD%' THEN 'OCD-NET'
		WHEN i.IntEnabledTherProg IS NULL THEN 'No IET'
		ELSE i.IntEnabledTherProg
		END IntEnabledTherProg

	--Therapist Time
	,i.DurationIntEnabledTher
	,ca.ClinContactDurOfCareAct

	--Integration Engine Flag
	,i.IntegratedSoftwareInd

	--Consultation Medium
	-- ,CASE WHEN m.[Face to face communication]>0 THEN 'F2F' ELSE 'No F2F'
	-- 	END AS ConsultationMedium

	--Reasons for Ending Treatment
	,r.EndCode
	,CASE WHEN r.EndCode='' THEN 'Referred but not seen/Seen but not taken on for a course of treatment/Seen and taken on for a course of treatment'
		WHEN r.EndCode='50' THEN 'Not assessed'	
		WHEN r.EndCode='10' THEN 'Not suitable for IAPT service - no action taken or directed back to referrer'
		WHEN r.EndCode='11'	THEN 'Not suitable for IAPT service - signposted elsewhere with mutual agreement of patient'
		WHEN r.EndCode='12' THEN 'Discharged by mutual agreement following advice and support'
		WHEN r.EndCode='13' THEN 'Referred to another therapy service by mutual agreement'
		WHEN r.EndCode='14'	THEN 'Suitable for IAPT service, but patient declined treatment that was offered'
		WHEN r.EndCode='16' THEN 'Incomplete Assessment (Patient dropped out)'
		WHEN r.EndCode='17' THEN 'Deceased (Seen but not taken on for a course of treatment)'
		WHEN r.EndCode='95' THEN 'Not Known (Seen but not taken on for a course of treatment)'
		WHEN r.EndCode='46' THEN 'Mutually agreed completion of treatment'
		WHEN r.EndCode='47' THEN 'Termination of treatment earlier than Care Professional planned'
		WHEN r.EndCode='48' THEN 'Termination of treatment earlier than patient requested'
		WHEN r.EndCode='49' THEN 'Deceased (Seen and taken on for a course of treatment)'
		WHEN r.EndCode='96' THEN 'Not Known (Seen and taken on for a course of treatment)'
		ELSE 'Missing/invalid'
		END AS EndCodeDescription

    --Clinical Outcomes	
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.Recovery_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS CompTreatFlagRecFlag	--Flag for recovery, where the discharge date is within the reporting period, completed treatment flag is true and recovery flag is true
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.NotCaseness_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0 
	END AS CompTreatFlagNotCasenessFlag	--Flag for not caseness, where the discharge date is within the reporting period, completed treatment flag is true and not caseness flag is true
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.ReliableImprovement_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0
	END AS CompTreatFlagRelImpFlag	--Flag for reliable improvement, where the discharge date is within the reporting period, completed treatment flag is true and reliable improvement flag is true
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' AND r.ReliableImprovement_Flag = 'True' 
		AND r.Recovery_Flag = 'True' AND r.PathwayID IS NOT NULL THEN 1 ELSE 0
	END AS CompTreatFlagRelRecFlags	--Flag for reliable improvement and recovery, where the discharge date is within the reporting period, completed treatment flag is true and reliable improvement flag is true
	,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0
	END AS CompTreatFlag --Flag for completed treatment flag, where the discharge date is within the reporting period
    
    --Problem Descriptor
	,CASE WHEN r.PresentingComplaintHigherCategory = 'Depression' OR r.[PrimaryPresentingComplaint] = 'Depression' THEN 'F32 or F33 - Depression'
		WHEN r.PresentingComplaintHigherCategory = 'Unspecified' OR r.[PrimaryPresentingComplaint] = 'Unspecified'  THEN 'Unspecified'
		WHEN r.PresentingComplaintHigherCategory = 'Other recorded problems' OR r.[PrimaryPresentingComplaint] = 'Other recorded problems' THEN 'Other recorded problems'
		WHEN r.PresentingComplaintHigherCategory = 'Other Mental Health problems' OR r.[PrimaryPresentingComplaint] = 'Other Mental Health problems' THEN 'Other Mental Health problems'
		WHEN r.PresentingComplaintHigherCategory = 'Invalid Data supplied' OR r.[PrimaryPresentingComplaint] = 'Invalid Data supplied' THEN 'Invalid Data supplied'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = '83482000 Body Dysmorphic Disorder' OR [SecondaryPresentingComplaint] = '83482000 Body Dysmorphic Disorder') THEN '83482000 Body Dysmorphic Disorder'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F400 - Agoraphobia' OR [SecondaryPresentingComplaint] = 'F400 - Agoraphobia') THEN 'F400 - Agoraphobia'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F401 - Social phobias' OR [SecondaryPresentingComplaint] = 'F401 - Social phobias') THEN 'F401 - Social Phobias'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F402 - Specific (isolated) phobias' OR [SecondaryPresentingComplaint] = 'F402 - Specific (isolated) phobias') THEN 'F402 care- Specific Phobias'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F410 - Panic disorder [episodic paroxysmal anxiety' OR [SecondaryPresentingComplaint] = 'F410 - Panic disorder [episodic paroxysmal anxiety') THEN 'F410 - Panic Disorder'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F411 - Generalised Anxiety Disorder' OR [SecondaryPresentingComplaint] = 'F411 - Generalised Anxiety Disorder') THEN 'F411 - Generalised Anxiety'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F412 - Mixed anxiety and depressive disorder' OR [SecondaryPresentingComplaint] = 'F412 - Mixed anxiety and depressive disorder') THEN 'F412 - Mixed Anxiety'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F42 - Obsessive-compulsive disorder' OR [SecondaryPresentingComplaint] = 'F42 - Obsessive-compulsive disorder') THEN 'F42 - Obsessive Compulsive'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F431 - Post-traumatic stress disorder' OR [SecondaryPresentingComplaint] = 'F431 - Post-traumatic stress disorder') THEN 'F431 - Post-traumatic Stress'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'F452 Hypochondriacal Disorders' OR [SecondaryPresentingComplaint] = 'F452 Hypochondriacal Disorders') THEN 'F452 - Hypochondrial disorder'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory = 'Other F40-F43 code' OR [SecondaryPresentingComplaint] = 'Other F40-F43 code') THEN 'Other F40 to 43 - Other Anxiety'
		WHEN (r.PresentingComplaintHigherCategory = 'Anxiety and stress related disorders (Total)' OR r.[PrimaryPresentingComplaint] = 'Anxiety and stress related disorders (Total)') AND (r.PresentingComplaintLowerCategory IS NULL OR [SecondaryPresentingComplaint] IS NULL) THEN 'No Code' 
		ELSE 'Other'
	END AS 'ProblemDescriptor'
    
    --Geography
    ,ch.Organisation_Code as 'Sub-ICBCode'
	,ch.Organisation_Name as 'Sub-ICBName'
	,ch.STP_Code as 'ICBCode'
	,ch.STP_Name as 'ICBName'
	,ch.Region_Name as 'RegionNameComm'
	,ch.Region_Code as 'RegionCodeComm'
	,ph.Organisation_Code as 'ProviderCode'
	,ph.Organisation_Name as 'ProviderName'
	,ph.Region_Name as 'RegionNameProv'
	--,ph.Region_Code as 'RegionCodeProv'
INTO [MHDInternal].[TEMP_TTAD_IET_Base]
FROM [MESH_IAPT].[IDS101referral] r

INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
--Three tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
LEFT JOIN [MHDInternal].[REFERENCE_CCG_2020_Lookup] c ON r.OrgIDComm = c.IC_CCG					
LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON c.CCG21 = ch.Organisation_Code AND ch.Effective_To IS NULL
LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

LEFT JOIN [MHDInternal].[TEMP_TTAD_IET_TypeAndDuration] i ON i.PathwayID = r.PathwayID
LEFT JOIN [MHDInternal].[TEMP_TTAD_IET_NoIETDuration] ca ON ca.PathwayID=r.PathwayID

WHERE r.UsePathway_Flag = 'True' 
	AND l.IsLatest = 1	--To get the latest data
	AND r.CompletedTreatment_Flag = 'True'	--Data is filtered to only look at those who have completed a course of treatment
	AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate	
	AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, @Offset, @PeriodStart) AND @PeriodStart	--for refresh, the offset should be 0 as only want the data for the latest month

------------------------------------------------------------------------------------	
----------------------------------------Aggregated Main Table------------------------
--This table aggregates [MHDInternal].[TEMP_TTAD_IET_Base] table to get the number of PathwayIDs with the recovery flag,
-- not caseness flag, reliable improvement flag, completed treatment flag, and both the recovery and reliable improvement flag.
--This is calculated at different Geography levels (National, Regional, ICB, Sub-ICB and Provider), by Appointment Types (1+ IET, 2+ IET and No IET),
--by IET Therapy Types, by Integrated Software Indicator, by End Codes, and by Problem Descriptors

IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_IET_Main]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_IET_Main]
--National, IET 1+
SELECT 
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,CAST('1+ IET' AS VARCHAR(50)) AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor
GO
--National, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor

--National, IET 2+
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor

--Region, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm AS OrgName
,RegionCodeComm AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor

--Region, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm  AS OrgName
,RegionCodeComm  AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor

--Region, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm  AS OrgName
,RegionCodeComm  AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor


--ICB, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor

--ICB, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor


--ICB, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor

--Sub-ICB, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor

--Sub-ICB, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor

--Sub-ICB, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor

--Provider, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor


--Provider, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor

--Provider, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_Main]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,IntegratedSoftwareInd
,EndCode
,EndCodeDescription
,ProblemDescriptor
,SUM(CompTreatFlagRecFlag) AS CompTreatFlagRecFlag
,SUM(CompTreatFlagNotCasenessFlag) AS CompTreatFlagNotCasenessFlag
,SUM(CompTreatFlagRelImpFlag) AS CompTreatFlagRelImpFlag
,SUM(CompTreatFlagRelRecFlags) AS CompTreatFlagRelRecFlags
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_Base]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,IntegratedSoftwareInd
	,EndCode
	,EndCodeDescription
	,ProblemDescriptor

-------------------------------------------------------------------------------
--For Patient Experience Questionnaire (PEQ)
DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset for getting the period start and end should be -1 to get the latest refreshed month
SET @PeriodStart = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT EOMONTH(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

--The offset needs to be set for September 2020 (e.g. @PeriodStart -30 = -31 which is the offset of September 2020)
DECLARE @Offset int
SET @Offset=-32

SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd
IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_BasePEQ]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
SELECT DISTINCT 
CAST(DATENAME(m, l.ReportingPeriodStartDate) + ' ' + CAST(DATEPART(yyyy, l.ReportingPeriodStartDate) AS VARCHAR) AS DATE) as Month
,r.PathwayID
,CASE WHEN (i.IntEnabledTherProg LIKE 'SilverCloud%' OR i.IntEnabledTherProg LIKE  'Slvrcld%' ) THEN 'SilverCloud'
		WHEN (i.IntEnabledTherProg LIKE 'Mnddstrct%' OR i.IntEnabledTherProg LIKE 'Minddistrict%') THEN 'Minddistrict'
		WHEN i.IntEnabledTherProg LIKE 'iCT%' THEN 'iCT'
		WHEN i.IntEnabledTherProg LIKE 'OCD%' THEN 'OCD-NET'
		WHEN i.IntEnabledTherProg IS NULL THEN 'No IET'
		ELSE i.IntEnabledTherProg
		END IntEnabledTherProg
,r.InternetEnabledTherapy_Count
,CASE WHEN s2.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire choice question 1 score (observable entity)' THEN 'Assessment Question 1'
	WHEN s2.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire choice question 2 score (observable entity)' THEN 'Assessment Question 2'
	WHEN s2.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire choice question 3 score (observable entity)' THEN 'Assessment Question 3'
	WHEN s2.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire choice question 4 score (observable entity)' THEN 'Assessment Question 4'
	WHEN s2.[Term]='Improving Access to Psychological Therapies assessment Patient Experience Questionnaire satisfaction question 1 score (observable entity)' THEN 'Satisfaction Assessment Question 1'
	WHEN s2.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 1 score (observable entity)' THEN 'Treatment Question 1'
	WHEN s2.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 2 score (observable entity)' THEN 'Treatment Question 2'
	WHEN s2.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 3 score (observable entity)' THEN 'Treatment Question 3'
	WHEN s2.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 4 score (observable entity)' THEN 'Treatment Question 4'
	WHEN s2.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 5 score (observable entity)' THEN 'Treatment Question 5'
	WHEN s2.[Term]='Improving Access to Psychological Therapies treatment Patient Experience Questionnaire question 6 score (observable entity)' THEN 'Treatment Question 6'
	ELSE NULL		
END AS 'Question'
,CASE 
	-- Treatment
	WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('0') THEN 'Never'
	WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('1') THEN 'Rarely'
	WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('2') THEN 'Sometimes'
	WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('3') THEN 'Most of the time'
	WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('4') THEN 'All of the time'
	WHEN [CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108') AND [PersScore] IN ('NA') THEN 'Not applicable'
	--Assessment
	WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('Y') THEN 'Yes'
	WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('N') THEN 'No'
	WHEN [CodedAssToolType] IN('747861000000100','747871000000107','747881000000109','904691000000103') AND [PersScore] IN ('NA') THEN 'Not applicable'
	--Satifaction
	WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('0') THEN 'Not satisfied at all'
	WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('1') THEN 'Not satisfied'
	WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('2') THEN 'Neither satisfied or Dis-satisfied'
	WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('3') THEN 'Mostly satisfied'
	WHEN [CodedAssToolType] IN('747891000000106') AND [PersScore] IN ('4') THEN 'Completely satisfied'
END AS 'Answer'

,CASE WHEN (r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate) AND r.CompletedTreatment_Flag = 'True' 
		AND r.PathwayID IS NOT NULL THEN 1 ELSE 0
	END AS CompTreatFlag --Flag for completed treatment flag, where the discharge date is within the reporting period
    
--Geography
    ,ch.Organisation_Code as 'Sub-ICBCode'
	,ch.Organisation_Name as 'Sub-ICBName'
	,ch.STP_Code as 'ICBCode'
	,ch.STP_Name as 'ICBName'
	,ch.Region_Name as 'RegionNameComm'
	,ch.Region_Code as 'RegionCodeComm'
	,ph.Organisation_Code as 'ProviderCode'
	,ph.Organisation_Name as 'ProviderName'
	,ph.Region_Name as 'RegionNameProv'
INTO [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
FROM [MESH_IAPT].[IDS101referral] r
INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
--Three tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes:
LEFT JOIN [MHDInternal].[REFERENCE_CCG_2020_Lookup] c ON r.OrgIDComm = c.IC_CCG					
LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON c.CCG21 = ch.Organisation_Code AND ch.Effective_To IS NULL
LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL

LEFT JOIN [MHDInternal].[TEMP_TTAD_IET_TypeAndDuration] i ON i.PathwayID = r.PathwayID
LEFT JOIN [mesh_IAPT].[IDS607codedscoreassessmentact] csa ON r.PathwayID=csa.PathwayID AND r.AuditId=csa.AuditId
AND csa.[CodedAssToolType] IN ('747901000000107','747911000000109','747921000000103','747931000000101','747941000000105','747951000000108'
	,'747861000000100','747871000000107','747881000000109','904691000000103','747891000000106')
	
LEFT JOIN [UKHD_SNOMED].[Descriptions_SCD] s2 ON CodedAssToolType = CAST(s2.[Concept_ID] AS VARCHAR) 
	AND s2.Type_ID = 900000000000003001 AND s2.Is_Latest = 1 AND s2.Active = 1
WHERE l.IsLatest = 1	--To get the latest data
	AND UsePathway_Flag='True'
	AND r.CompletedTreatment_Flag = 'True'	--Data is filtered to only look at those who have completed a course of treatment
	AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate	
	AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, @Offset, @PeriodStart) AND @PeriodStart	--for refresh, the offset should be 0 as only want the data for the latest month



IF OBJECT_ID ('[MHDInternal].[DASHBOARD_TTAD_IET_PEQ]') IS NOT NULL DROP TABLE [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
--National, IET 1+
SELECT 
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,CAST('1+ IET' AS VARCHAR(50)) AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,IntEnabledTherProg
	,Question
	,Answer
GO
--National, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,IntEnabledTherProg
	,Question
	,Answer

--National, IET 2+
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,CAST('National' AS VARCHAR(50)) AS OrgType
,CAST('All Regions' AS VARCHAR(255)) AS Region
,CAST('England' AS VARCHAR(255)) AS OrgName
,CAST('ENG' AS VARCHAR(50)) AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,IntEnabledTherProg
	,Question
	,Answer

--Region, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm AS OrgName
,RegionCodeComm AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm
	,IntEnabledTherProg
	,Question
	,Answer

--Region, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm  AS OrgName
,RegionCodeComm  AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg
	,Question
	,Answer

--Region, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Region' AS OrgType
,RegionNameComm AS Region
,RegionNameComm  AS OrgName
,RegionCodeComm  AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameComm
	,RegionCodeComm 
	,IntEnabledTherProg
	,Question
	,Answer


--ICB, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,Question
	,Answer

--ICB, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,Question
	,Answer


--ICB, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'ICB' AS OrgType
,RegionNameComm AS Region
,[ICBName] AS OrgName
,[ICBCode] AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameComm
	,[ICBName]
	,[ICBCode]
	,IntEnabledTherProg
	,Question
	,Answer

--Sub-ICB, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,Question
	,Answer

--Sub-ICB, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,Question
	,Answer

--Sub-ICB, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Sub-ICB' AS OrgType
,RegionNameComm AS Region
,[Sub-ICBName] AS OrgName
,[Sub-ICBCode] AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameComm
	,[Sub-ICBName]
	,[Sub-ICBCode]
	,IntEnabledTherProg
	,Question
	,Answer

--Provider, 1+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,'1+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=1
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,Question
	,Answer


--Provider, No IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,'No IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count=0 OR InternetEnabledTherapy_Count IS NULL
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,Question
	,Answer

--Provider, 2+ IET
INSERT INTO [MHDInternal].[DASHBOARD_TTAD_IET_PEQ]
SELECT 
Month
,'Provider' AS OrgType
,RegionNameProv AS Region
,[ProviderName] AS OrgName
,[ProviderCode] AS OrgCode
,'2+ IET' AS AppointmentType
,SUM(InternetEnabledTherapy_Count) AS InternetEnabledTherapy_Count
,IntEnabledTherProg
,Question
,Answer
,SUM(CompTreatFlag) AS CompTreatFlag
FROM [MHDInternal].[TEMP_TTAD_IET_BasePEQ]
WHERE InternetEnabledTherapy_Count>=2
GROUP BY 
	Month
	,RegionNameProv
	,[ProviderName]
	,[ProviderCode]
	,IntEnabledTherProg
	,Question
	,Answer

	

