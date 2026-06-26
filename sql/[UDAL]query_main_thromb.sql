/*
 README
 THIS IS THE PRINCIPLE THROMBECTOMY QUERY. COVERS 2014/15 ONWARDS.

 TODO: EPISODE- OR SPELL-LEVEL DATA ??? (COUPLE MORE % IN SPELLS)
 
 UNJOINED: 1,854,301 EPISODE RECORDS
 
 FOR PATIENTS WHO HAD A CEREBRAL INFARCTION, FLAG MECHANICAL THROMBECTOMIES.
 THESE ARE DEFINED USING OPCS-4 CODES AVAILABLE THRO LINKS PROVIDED ON THIS PAGE:
 https://www.nice.org.uk/guidance/htg403
 (CLICK LINK TO CODES AND SEARCH FOR "HTG403")
 AND LEGACY CODES RECOMMENDED BY HSCIC CLINICAL CLASSIFICATIONS SERVICE

NOTE: THIS WILL EXCLUDE:
- 8 CASES WITH THROMBO BUT WITH INFARCTION AS SECONDARY DIAG
- 62 CASES WITH THROMBO BUT PRIMARY DIAG AS OTHER TYPE STROKE 
I THINK THIS IS OKAY SINCE WE ARE NOT TRYING TO MATCH THE AUDIT HERE,
WE ARE DEFINING A PATIENT COHORT (THOSE I63 DIAG) AND LOOKING AT TREATMENT.
TODO: SO PERHAPS THE 8 CASES ARE INCLUDED?
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
    [site_code_of_treatment_at_episode_start_date],
    [site_code_of_treatment_at_episode_end_date],  
    [Der_Provider_Site_Code],
    [site_name],
    [trust_name],
    [Admission_Method],
    [Der_Management_Type],
    [Der_Episode_Number],
    /* THROMBECTOMY ACCORDING TO STRICT DEFINITIONS */
    CASE
        /* NEWER CODING */
        WHEN [Der_Procedure_All] LIKE '%L354%'
        /* OLDER CODING */
        OR (
            [Der_Procedure_All] LIKE '%L712%'
            AND [Der_Procedure_All] LIKE '%Y53%'
            AND (
                [Der_Procedure_All] LIKE '%Z35%'
                OR [Der_Procedure_All] LIKE '%O28[189]%'
            )
        ) THEN 1
        ELSE 0
    END AS 'thromb',
    [Der_Diagnosis_ALL]
FROM [Reporting_MESH_APC].[APCE_Core_Monthly_Snapshot] core
    LEFT JOIN (
        select site_code,
            site_name,
            trust_name
        from Reporting_UKHD_ODS.Provider_Site
    ) sites ON core.der_provider_site_code = sites.site_code
WHERE 1 = 1
    /* COHORT BEING: PATIENTS WHO HAD CEREBRAL INFARCTION AS PRIMARY DIAG */
    AND [Der_Primary_Diagnosis_Code] LIKE 'I63%'
    /* AND [Der_Diagnosis_All] LIKE '%I63%'*/
    /* ADMITTED IN AN EMERGENCY (OR TRANSFERRED IN SOME FORM) */
    AND (
      LEFT([Admission_Method], 1) = '2' OR 
      [Admission_Method] = '81'
      )
    /* STUDY PERIOD AND OTHER EXCLUSIONS */  
    AND YEAR(Admission_Date) >= 2014
    AND [Der_Financial_Year] <> '2013/14'
    AND [Der_Financial_Year] <> '2026/27'
    AND [Deleted] = 0
    AND [der_age_at_cds_activity_date] <= 112
    /* NOTE: LSOA-BASED EXCLUSIONS APPLIED IN R WORKFLOW */
    
    