/*
README
PULL RECORDS OF TAVIs FROM APCS TO COMPARE WITH NUMBERS FROM 2023 AUDIT:

"Geographical Inequality in Access to Aortic Valve Intervention in England:
A Report from the UK Transcatheter Aortic Valve Implantation Registry
and National Adult Cardiac Surgery Audit"

USING OPCS-4 CODES BASED ON STRICT NICE DEFINITION:
https://www.nice.org.uk/guidance/htg446
(CLICK LINK TO CODES AND SEARCH FOR "HTG446" ("TAVI" GIVES DIFFERENT RESULTS))

*/

SELECT 
[Der_Financial_Year],
[Der_Management_Type],
[Admission_Method],
CASE 
  WHEN [Admission_Method] IN ('11', '12', '13')
  THEN 1
  ELSE 0
END AS 'is_elective',
CASE 
  WHEN [Der_Diagnosis_ALL] LIKE '%I350%'
  THEN 1
  ELSE 0
END AS 'diag_stenosis',
/*
CASE 
  WHEN [Der_Diagnosis_ALL] LIKE '%I352%'
  THEN 1
  ELSE 0
END AS 'diag_stenosis_insuff',
CASE 
  WHEN [Der_Diagnosis_ALL] LIKE '%I35[189]%'
  THEN 1
  ELSE 0
END AS 'diag_broader',
CASE 
  WHEN [Der_Diagnosis_ALL] LIKE '%T82[029]%'
  THEN 1
  ELSE 0
END AS 'diag_complctn',
*/
CASE 
  WHEN [Der_Procedure_All] LIKE '%Y79%'
  THEN 1
  ELSE 0
END AS 'proc_app_artery',
CASE 
  WHEN [Der_Procedure_All] LIKE '%Y494%'
  THEN 1
  ELSE 0
END AS 'proc_app_trnsapical',
CASE 
  WHEN [Der_Procedure_All] LIKE '%Y53%' 
    OR [Der_Procedure_All] LIKE '%Y68%' 
  THEN 1
  ELSE 0
END AS 'proc_image_codes',
CASE 
  WHEN [Der_Procedure_All] LIKE '%U202%' 
  THEN 1
  ELSE 0
END AS 'proc_echocardio_codes',
/*
CASE 
  WHEN [Der_Procedure_All] LIKE '%Y78%'
  THEN 1
  ELSE 0
END AS 'proc_app_other',
*/
COUNT(*) AS 'n'
FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot]
WHERE 1 = 1
  AND [Der_Financial_Year] = '2022/23'
  /* PLASTIC REPAIR OF AORTIC VALVE */
  AND [Der_Procedure_All] LIKE '%K26%'
  /*
  [Patient_Classification]
  AND YEAR(Admission_Date) > 2018
  AND [Der_Financial_Year] <> '2018/19'
  */
  /* ELECTIVES ONLY */
  /*AND [Admission_Method] IN ('11', '12', '13')*/
  /*AND [Der_Diagnosis_ALL] LIKE '%I35[02]%'*/
GROUP BY 
[Der_Financial_Year],
[Der_Management_Type],
[Admission_Method],
CASE 
  WHEN [Admission_Method] IN ('11', '12', '13')
  THEN 1
  ELSE 0
END,
CASE 
  WHEN [Der_Diagnosis_ALL] LIKE '%I350%'
  THEN 1
  ELSE 0
END,
CASE 
  WHEN [Der_Procedure_All] LIKE '%Y79%'
  THEN 1
  ELSE 0
END,
CASE 
  WHEN [Der_Procedure_All] LIKE '%Y494%'
  THEN 1
  ELSE 0
END,
CASE 
  WHEN [Der_Procedure_All] LIKE '%Y53%' 
    OR [Der_Procedure_All] LIKE '%Y68%' 
  THEN 1
  ELSE 0
END,
CASE 
  WHEN [Der_Procedure_All] LIKE '%U202%' 
  THEN 1
  ELSE 0
END
