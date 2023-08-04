DECLARE @PeriodStart DATE
DECLARE @PeriodEnd DATE 
--For refreshing, the offset for getting the period start and end should be -1 to get the latest refreshed month
SET @PeriodStart = (SELECT DATEADD(MONTH,-1,MAX([ReportingPeriodStartDate])) FROM [mesh_IAPT].[IsLatest_SubmissionID])
SET @PeriodEnd = (SELECT eomonth(DATEADD(MONTH,-1,MAX([ReportingPeriodEndDate]))) FROM [mesh_IAPT].[IsLatest_SubmissionID])

--The offset needs to be set for September 2020 (e.g. @PeriodStart -30 = -31 which is the offset of September 2020)
DECLARE @Offset int
SET @Offset=-31

SET DATEFIRST 1

PRINT @PeriodStart
PRINT @PeriodEnd

IF OBJECT_ID ('[MHDInternal].[TEMP_TTAD_IET_Base]') IS NOT NULL DROP TABLE [MHDInternal].[TEMP_TTAD_IET_Base]
SELECT 
    r.PathwayID
    ,r.InternetEnabledTherapy_Count
    
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
	,ch.Organisation_Name as 'Sub-ICB Name'
	,ch.STP_Name as 'ICB Name'
	,ch.Region_Name as 'RegionNameComm'
	,ph.Organisation_Code as 'ProviderCode'
	,ph.Organisation_Name as 'Provider Name'
	,ph.Region_Name as 'RegionNameProv'
INTO [MHDInternal].[TEMP_TTAD_IET_Base]
FROM [MESH_IAPT].[IDS101referral] r
    INNER JOIN [mesh_IAPT].[IsLatest_SubmissionID] l ON r.[UniqueSubmissionID] = l.[UniqueSubmissionID] AND r.[AuditId] = l.[AuditId]
    LEFT JOIN [MHDInternal].[REFERENCE_CCG_2020_Lookup] c ON r.OrgIDComm = c.IC_CCG					
	LEFT JOIN [Reporting].[Ref_ODS_Commissioner_Hierarchies_ICB] ch ON c.CCG21 = ch.Organisation_Code AND ch.Effective_To IS NULL
	LEFT JOIN [Reporting].[Ref_ODS_Provider_Hierarchies_ICB] ph ON r.OrgID_Provider = ph.Organisation_Code AND ph.Effective_To IS NULL
	--Three tables for getting the up-to-date Sub-ICB/ICB/Region/Provider names/codes
    LEFT JOIN [mesh_IAPT].[IDS205internettherlog] i ON i.PathwayID = r.PathwayID and i.Unique_MonthID=r.Unique_MonthID


WHERE r.UsePathway_Flag = 'True' 
		AND l.IsLatest = 1	--To get the latest data
		AND r.CompletedTreatment_Flag = 'True'	--Data is filtered to only look at those who have completed a course of treatment
		AND r.ServDischDate BETWEEN l.ReportingPeriodStartDate AND l.ReportingPeriodEndDate	
		AND l.[ReportingPeriodStartDate] BETWEEN DATEADD(MONTH, @Offset, @PeriodStart) AND @PeriodStart	--for refresh, the offset should be 0 as only want the data for the latest month
		