/*
 README
 THIS IS THE PRINCIPLE THROMBECTOMY QUERY. COVERS 2014/15 ONWARDS.
 SPELL-LEVEL DATA 
 
 FOR PATIENTS WHO HAD A CEREBRAL INFARCTION, FLAG MECHANICAL THROMBECTOMIES.
 THESE ARE DEFINED USING OPCS-4 CODES AVAILABLE THRO LINKS PROVIDED ON THIS PAGE:
 https://www.nice.org.uk/guidance/htg403
 (CLICK LINK TO CODES AND SEARCH FOR "HTG403")
 AND LEGACY CODES RECOMMENDED BY HSCIC CLINICAL CLASSIFICATIONS SERVICE

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
FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot] core
    LEFT JOIN (
        select site_code,
            site_name,
            trust_name
        from Reporting_UKHD_ODS.Provider_Site
    ) sites ON core.der_provider_site_code = sites.site_code
WHERE 1 = 1
    /* COHORT BEING: PATIENTS WHO HAD CEREBRAL INFARCTION CODED IN SPELL */
    AND [Der_Diagnosis_All] LIKE '%I63%'
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
    
    