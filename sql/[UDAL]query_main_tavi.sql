/*
README
THIS IS THE PRINCIPLE TAVI QUERY. COVERS 2010/11 ONWARDS.

PULL ALL PATIENTS WHO HAD AN aortic (valve) stenosis (ICD-10 code I35.0)
AND UNDERWENT aortic valve replacement in an elective setting.


USING OPCS-4 CODES BASED ON STRICT NICE DEFINITION:
https://www.nice.org.uk/guidance/htg446
(CLICK LINK TO CODES AND SEARCH FOR "HTG446" (NOTE: A SEARCH FOR "TAVI" 
 WILL GIVE DIFFERENT (UNDESIRED) RESULTS))

*/

SELECT   
    [Der_Financial_Year] as 'fyear',
    [Der_Activity_Month] as 'month',
    --------- [apce_ident] as 'id',
    [der_age_at_cds_activity_date] as 'age',
    [sex],
    [ethnic_group],
    [der_postcode_lsoa_2011_code] as 'lsoa11code',
    [der_postcode_lsoa_2021_code] as 'lsoa21code',
    [Der_Provider_Site_Code],
    [site_name],
    [trust_name],
    [Admission_Method],
    [Der_Management_Type],
    CASE 
  WHEN [Der_Procedure_All] LIKE '%Y79%'
    OR [Der_Procedure_All] LIKE '%Y494%'  -- PLUS EXTRA CODES FROM NICE?    
  THEN 1 
  ELSE 0
END AS 'tavi',
 # CHECK THAT ADDITIONAL PROCEDURE CODES DO NOT AFFECT AUDIT NOS 
    [Der_Diagnosis_ALL]

WHERE 1=1
  AND [Deleted] = 0
  AND YEAR(Admission_Date) >= 2010
  AND [Der_Financial_Year] <> '2009/10'
  /* COHORT BEING: */
  /* 1. ELECTIVE PATIENTS */
  AND [Admission_Method] IN ('11', '12', '13')
  /* 2. WITH AORTIC (VALVE) STENOSIS */
  [Der_Diagnosis_ALL] LIKE '%I350%'
  /* 3. UNDERGOING A PLASTIC REPAIR OF AORTIC VALVE */
  AND [Der_Procedure_All] LIKE '%K26%'


# TAVI IN EMERGENCY ????
