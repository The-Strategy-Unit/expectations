/*
README
THIS IS THE PRINCIPLE TAVI QUERY. ACTIVITY FROM 2010/11 ONWARDS.

PULL ALL PATIENTS WHO HAD AN aortic (valve) stenosis (ICD-10 code I35.0)
AND UNDERWENT SOME FORM OF aortic valve replacement.
LATER IN THE R WORKFLOW WE DIFFERENTIATE BETWEEN
THOSE WHO HAD THE PROCEDURE ELECTIVELY AND THOSE WHO HAD AN EMERGENCY TAVI.


USING OPCS-4 CODES BASED ON STRICT NICE DEFINITION:
https://www.nice.org.uk/guidance/htg446
(CLICK LINK TO CODES AND SEARCH FOR "HTG446" (NOTE: A SEARCH FOR "TAVI" 
 WILL GIVE DIFFERENT (UNDESIRED) RESULTS))

*/

/* SET MONDAY AS WEEKDAY 1 (FOR DATEPART) */
SET DATEFIRST 1 

SELECT   
    [Der_Financial_Year] as 'fyear',
    [Der_Activity_Month] as 'month',
    [der_spell_id],      
    [der_pseudo_nhs_number] as 'nhs_no',
    [Admission_Date],
    [Admission_Time],
    [Discharge_Date],
    [Discharge_Time],
    [episode_start_date],
    [episode_start_time],
    [episode_end_date], 
    [episode_end_time],
     CASE
      WHEN DATEPART(weekday, [Admission_Date]) IN ('6', '7')
      THEN 1
      ELSE 0
    END AS 'is_wkend',
    CASE
      WHEN [sex] IN ('1', '2')
      THEN [sex]
      ELSE 'not specified'
    END AS 'sex',
    [der_age_at_cds_activity_date] as 'age',
    [ethnic_group],
    [der_postcode_lsoa_2011_code] as 'lsoa11code',
    [der_postcode_lsoa_2021_code] as 'lsoa21code',
    [Der_Provider_Site_Code],
    [site_name],
    [trust_name],
    [Admission_Method],
    [Der_Management_Type],
    [Der_Episode_Number],
    CASE 
      WHEN [Der_Procedure_All] LIKE '%Y79%'
        OR [Der_Procedure_All] LIKE '%Y494%' 
    /* NOTE: NOT REQUIRING ADDITIONAL IMAGING PROC CODES: Y53, Y68, U202 */
      THEN 1 
      ELSE 0
    END AS 'tavi',
    [Der_Diagnosis_ALL]
FROM [Reporting_MESH_APC].[APCE_Core_Monthly_Snapshot] core
  LEFT JOIN (
        SELECT [site_code],
               [site_name],
              [trust_name]
        FROM Reporting_UKHD_ODS.Provider_Site
    ) sites 
  ON core.der_provider_site_code = sites.site_code
WHERE 1=1
    /* COHORT BEING: */
    /* 1. WITH AORTIC (VALVE) STENOSIS */
    AND [Der_Diagnosis_ALL] LIKE '%I350%'
    /* 2. UNDERGOING A PLASTIC REPAIR OF AORTIC VALVE */
    AND [Der_Procedure_All] LIKE '%K26%'
    /* 3. ELECTIVE PATIENTS - FILTERED IN R WORKFLOW */
    /*AND [Admission_Method] IN ('11', '12', '13')*/
     /* STUDY PERIOD AND OTHER EXCLUSIONS */  
    AND YEAR(Admission_Date) >= 2010
    AND [Der_Financial_Year] <> '2009/10'
    AND [Der_Financial_Year] <> '2026/27'
    AND [Deleted] = 0
    AND [der_age_at_cds_activity_date] <= 112
    /* NOTE: LSOA-BASED EXCLUSIONS APPLIED IN R WORKFLOW */
  