/*
README
PULL RECORDS OF POSSIBLE MECHANICAL THROMBECTOMIES FROM APCE 
TO COMPARE WITH NUMBERS FROM SSNAP AUDIT.
OPCS-4 CODES AVAILABLE THRO LINKS PROVIDED ON THIS PAGE:
https://www.nice.org.uk/guidance/htg403
(CLICK LINK TO CODES AND SEARCH FOR "HTG403")
AND LEGACY CODES RECOMMENDED BY HSCIC CLINICAL CLASSIFICATIONS SERVICE

SSNAP COHORT BASED ON PRIMARY DIAGNOSIS I6[134]
https://www.strokeaudit.org/Audits/Clinical-audit-information/About.aspx

*/

SELECT 
[Der_Episode_Number],
[Der_Provider_Site_Code],
site_name,
trust_name,
[Admission_Method],
[Der_Management_Type],
CASE 
WHEN [Der_Primary_Diagnosis_Code] LIKE 'I63%'
THEN 1
ELSE 0
END AS 'ischaemic_stroke',
CASE 
WHEN [Der_Procedure_All] LIKE '%L354%' 
/*
OR [Der_Procedure_All] LIKE '%L35[89]%' 
-- OR [Der_Procedure_All] LIKE '%L961%'
-- OR [Der_Procedure_All] LIKE '%L67%'
-- OR [Der_Procedure_All] LIKE '%L65%'
*/
OR (
[Der_Procedure_All] LIKE '%L712%'
/*AND [Der_Procedure_All] LIKE '%Y53%'*/
AND 
(
[Der_Procedure_All] LIKE '%Z35%'
OR [Der_Procedure_All] LIKE '%O28[189]%'  
)
)
THEN 1
ELSE 0
END AS 'thrombo_base',
/*
CASE 
WHEN [Der_Procedure_All] LIKE '%Y53%' 
OR [Der_Procedure_All] LIKE '%Y68%'
THEN 1
ELSE 0
END AS 'thrombo_image',
CASE 
WHEN [Der_Procedure_All] LIKE '%Z35%'
OR [Der_Procedure_All] LIKE '%O281%'
THEN 1
ELSE 0
END AS 'thrombo_artery',
CASE 
WHEN [Der_Procedure_All] LIKE '%X833%'
THEN 1
ELSE 0
END AS 'control_thrombolysis',
[Der_Diagnosis_ALL],
[Der_Procedure_All],
*/
COUNT(*) AS 'n'
FROM [Reporting_MESH_APC].[APCE_Core_Monthly_Snapshot] core
LEFT JOIN (
select site_code, site_name, trust_name
from Reporting_UKHD_ODS.Provider_Site
) sites
ON core.der_provider_site_code = sites.site_code
WHERE 1 = 1
AND [Deleted] = 0
AND [Der_Financial_Year] = '2024/25'
/* THIS IS THE COHORT COVERED BY SSNAP  */

AND (
    [Der_Primary_Diagnosis_Code] LIKE 'I63%' OR 
    [Der_Primary_Diagnosis_Code] LIKE 'I61%' OR
    [Der_Primary_Diagnosis_Code] LIKE 'I64%'
  )
GROUP BY 
[Der_Episode_Number],
[Der_Provider_Site_Code],
site_name,
trust_name,
[Admission_Method],
[Der_Management_Type],
CASE 
WHEN [Der_Primary_Diagnosis_Code] LIKE 'I63%'
THEN 1
ELSE 0
END,
CASE 
WHEN [Der_Procedure_All] LIKE '%L354%' 
/*
OR [Der_Procedure_All] LIKE '%L35[89]%' 
OR [Der_Procedure_All] LIKE '%L961%'
OR [Der_Procedure_All] LIKE '%L67%'
OR [Der_Procedure_All] LIKE '%L65%'
*/
OR (
[Der_Procedure_All] LIKE '%L712%'
/*AND [Der_Procedure_All] LIKE '%Y53%'*/
AND 
(
[Der_Procedure_All] LIKE '%Z35%'
OR [Der_Procedure_All] LIKE '%O28[189]%'  
)
)
THEN 1
ELSE 0
END
/*
,
CASE 
WHEN [Der_Procedure_All] LIKE '%Y53%' 
OR [Der_Procedure_All] LIKE '%Y68%'
THEN 1
ELSE 0
END,
CASE 
WHEN [Der_Procedure_All] LIKE '%Z35%'
OR [Der_Procedure_All] LIKE '%O281%'
THEN 1
ELSE 0
END,
CASE 
WHEN [Der_Procedure_All] LIKE '%X833%'
THEN 1
ELSE 0
END,
[Der_Diagnosis_ALL],
[Der_Procedure_All]
*/


